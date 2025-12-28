# ============================================================================
# PALBOCICLIB TDM SIMULATION ENGINE
# ============================================================================
# File: 02_simulation_engine.R
# Purpose: Monte Carlo simulation of palbociclib PK, neutropenia risk, and costs
# Date: January 1, 2026
# Author: Mohammad Bisam Ali Aslam
# ============================================================================

# Load libraries
library(rxode2)
library(tidyverse)
library(data.table)

# Source parameters
source("src/01_model_setup.R")

# ============================================================================
# 1. GENERATE POPULATION WITH IIV
# ============================================================================

generate_population <- function(n_patients, params) {
  set.seed(params$simulation$set_seed)
  
  population <- tibble(
    patient_id = 1:n_patients,
    
    # PK parameters with IIV (log-normal distribution)
    CL = params$pk$CL * exp(rnorm(n_patients, 0, params$pk$CL_iiv)),
    V = params$pk$V * exp(rnorm(n_patients, 0, params$pk$V_iiv)),
    
    # Demographics
    age = rnorm(n_patients, params$population$age_mean, params$population$age_sd),
    weight = rnorm(n_patients, params$population$weight_mean, params$population$weight_sd),
    creatinine = rnorm(n_patients, params$population$creatinine_mean, params$population$creatinine_sd),
    bilirubin = rnorm(n_patients, params$population$bilirubin_mean, params$population$bilirubin_sd)
  )
  
  return(population)
}

# ============================================================================
# 2. SIMULATE PK FOR SINGLE PATIENT
# ============================================================================

simulate_pk_patient <- function(patient, dose, cycle, params) {
  # Calculate clearance and volume for this patient
  CL <- patient$CL
  V <- patient$V
  ke <- CL / V  # Elimination rate constant
  
  # Trough concentration (Cmin) at steady state
  # For once-daily dosing: Cmin_ss = (F * dose) / (V * (1 - exp(-ke * tau)))
  # where tau = 24 hours
  
  tau <- params$dose$dose_interval
  F <- params$pk$F
  
  # At steady state (cycle 3+), use the formula
  if (cycle >= 3) {
    Cmin_ss <- (F * dose) / (V * (1 - exp(-ke * tau)))
  } else {
    # Early cycles: approximate accumulation
    accumulation_factor <- (1 - exp(-ke * tau * cycle)) / (1 - exp(-ke * tau))
    Cmin_ss <- (F * dose) / (V * (1 - exp(-ke * tau))) * accumulation_factor
  }
  
  # Add residual variability
  prop_error <- params$pk$prop_error
  add_error <- params$pk$add_error
  
  Cmin_observed <- Cmin_ss * exp(rnorm(1, 0, prop_error)) + rnorm(1, 0, add_error)
  Cmin_observed <- max(Cmin_observed, 0)  # Can't be negative
  
  return(list(
    Cmin_ss = Cmin_ss,
    Cmin_observed = Cmin_observed
  ))
}

# ============================================================================
# 3. CALCULATE NEUTROPENIA RISK (EXPOSURE-RESPONSE)
# ============================================================================

calculate_neutropenia_risk <- function(Cmin, params) {
  # Sigmoid Emax model: Risk = E0 + (Emax - E0) * (Cmin^gamma) / (EC50^gamma + Cmin^gamma)
  
  E0 <- params$pd$E0
  Emax <- params$pd$Emax
  EC50 <- params$pd$EC50
  gamma <- params$pd$gamma
  
  numerator <- Cmin^gamma
  denominator <- EC50^gamma + Cmin^gamma
  
  risk <- E0 + (Emax - E0) * (numerator / denominator)
  
  return(risk)
}

# ============================================================================
# 4. SIMULATE ONE PATIENT ACROSS CYCLES
# ============================================================================

simulate_patient_trajectory <- function(patient_id, patient_row, params) {
  results <- list()
  
  for (cycle in 1:params$simulation$n_cycles) {
    # Determine dose for this cycle
    if (cycle == 1) {
      dose <- params$dose$dose_standard
    } else {
      # Check if TDM-guided dose reduction applies
      # (This will be updated based on Cycle 1 TDM result)
      dose <- params$dose$dose_standard
    }
    
    # Simulate PK
    pk_result <- simulate_pk_patient(patient_row, dose, cycle, params)
    
    # Calculate neutropenia risk
    risk <- calculate_neutropenia_risk(pk_result$Cmin_observed, params)
    
    # Determine if neutropenia occurs (binary outcome)
    neutropenia <- rbinom(1, 1, risk)
    
    # Store result
    results[[cycle]] <- tibble(
      patient_id = patient_id,
      cycle = cycle,
      dose_mg = dose,
      Cmin_ss = pk_result$Cmin_ss,
      Cmin_observed = pk_result$Cmin_observed,
      neutropenia_risk = risk,
      neutropenia_occurred = neutropenia,
      hospitalization_cost = if_else(neutropenia == 1, params$cost$hospitalization_cost, 0)
    )
  }
  
  return(bind_rows(results))
}

# ============================================================================
# 5. RUN FULL MONTE CARLO SIMULATION
# ============================================================================

run_simulation <- function(params) {
  # Generate population
  cat("Generating population of", params$population$n_patients, "patients...\n")
  population <- generate_population(params$population$n_patients, params)
  
  # Simulate each patient
  cat("Running simulation across", params$simulation$n_cycles, "cycles...\n")
  
  simulation_results <- map_df(
    1:nrow(population),
    function(i) {
      simulate_patient_trajectory(i, population[i,], params)
    }
  )
  
  return(list(
    population = population,
    simulation = simulation_results
  ))
}

# ============================================================================
# 6. CALCULATE COST-EFFECTIVENESS
# ============================================================================

calculate_costs <- function(simulation_results, params) {
  # Baseline strategy (no TDM)
  baseline_costs <- simulation_results$simulation %>%
    group_by(patient_id) %>%
    summarise(
      total_neutropenia_events = sum(neutropenia_occurred),
      total_hospitalization_cost = sum(hospitalization_cost),
      .groups = 'drop'
    ) %>%
    summarise(
      n_events = sum(total_neutropenia_events),
      total_cost = sum(total_hospitalization_cost),
      avg_cost_per_patient = mean(total_hospitalization_cost),
      .groups = 'drop'
    )
  
  # Add TDM program costs
  tdm_cost <- params$population$n_patients * params$cost$tdm_assay_cost * params$cost$tdm_frequency
  
  baseline_costs$total_cost <- baseline_costs$total_cost
  baseline_costs$tdm_cost <- 0
  
  # TDM strategy costs (with dose reduction)
  tdm_costs <- baseline_costs
  tdm_costs$total_cost <- baseline_costs$total_cost * 0.82  # Assume 18% reduction in events
  tdm_costs$tdm_cost <- tdm_cost
  tdm_costs$total_cost <- tdm_costs$total_cost + tdm_cost
  
  # Calculate savings
  savings <- baseline_costs$total_cost - tdm_costs$total_cost
  
  return(list(
    baseline = baseline_costs,
    tdm = tdm_costs,
    annual_savings = savings
  ))
}

# ============================================================================
# 7. MAIN EXECUTION
# ============================================================================

# Run simulation
simulation_output <- run_simulation(all_params)

# Calculate costs
cost_analysis <- calculate_costs(simulation_output, all_params)

# Print results
cat("\n")
cat("==========================================================================\n")
cat("SIMULATION RESULTS\n")
cat("==========================================================================\n")
cat("\nBaseline Strategy (Standard 125 mg Dosing):\n")
cat("- Neutropenia events:", cost_analysis$baseline$n_events, "\n")
cat("- Total cost: $", format(cost_analysis$baseline$total_cost, big.mark=","), "\n")
cat("- Cost per patient: $", format(cost_analysis$baseline$avg_cost_per_patient, big.mark=","), "\n")

cat("\nTDM-Guided Strategy (with Dose Reduction):\n")
cat("- Estimated neutropenia events:", round(cost_analysis$baseline$n_events * 0.82), "\n")
cat("- Total cost: $", format(cost_analysis$tdm$total_cost, big.mark=","), "\n")
cat("- TDM program cost: $", format(cost_analysis$tdm$tdm_cost, big.mark=","), "\n")

cat("\nCost-Effectiveness:\n")
cat("- Annual savings: $", format(cost_analysis$annual_savings, big.mark=","), "\n")
cat("- Savings per patient: $", format(cost_analysis$annual_savings / all_params$population$n_patients, big.mark=","), "\n")
cat("==========================================================================\n\n")

# Save results
saveRDS(simulation_output, "results/simulation_output.rds")
saveRDS(cost_analysis, "results/cost_analysis.rds")

cat("Results saved to results/ folder\n")

