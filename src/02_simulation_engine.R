# ==============================================================================
# PALBOCICLIB POPULATION PK/PD SIMULATION ENGINE
# Script 02: Monte Carlo Simulation & Analysis
# ==============================================================================
# Based on literature-verified parameters from 01_model_setup.R
# Sources: Royer et al. (2021), Courlet et al. (2022), Le Marouille et al. (2021)
# ==============================================================================

library(tidyverse)
library(data.table)

# Load parameters from 01_model_setup.R
if (!exists("all_params")) {
  all_params <- readRDS("data/parameters.rds")
}

cat("\n")
cat("================================================================================\n")
cat("PALBOCICLIB POPULATION SIMULATION ENGINE\n")
cat("================================================================================\n\n")

# Extract parameters
pk <- all_params$pk
dose <- all_params$dose
tdm <- all_params$tdm
pd <- all_params$pd
pop <- all_params$population
sim <- all_params$simulation
cost <- all_params$cost
expected <- all_params$expected

set.seed(sim$set_seed)

# ==============================================================================
# FUNCTION 1: GENERATE INDIVIDUAL CLEARANCE (LOGNORMAL IIV)
# ==============================================================================
# Source: Royer et al. 2021 - 31.3% CV for CL/F
generate_individual_cl <- function(n, pop_mean, cv_cl) {
  mu <- log(pop_mean) - 0.5 * log(1 + cv_cl^2)
  sigma <- sqrt(log(1 + cv_cl^2))
  rlnorm(n, meanlog = mu, sdlog = sigma)
}

# ==============================================================================
# FUNCTION 2: CALCULATE STEADY-STATE CMIN (1-COMPARTMENT MODEL)
# ==============================================================================
# Royer et al. 2021 used 1-compartment model
# Cmin ≈ Dose / (CL × tau) in steady state
calculate_cmin <- function(dose_mg, cl_l_per_h, v_l, tau_h = 24) {
  # Calculate Cmin using simplified steady-state equation
  cmin_ug_l <- dose_mg / (cl_l_per_h * tau_h)
  cmin_ng_ml <- cmin_ug_l * 1000
  
  return(cmin_ng_ml)
}

# ==============================================================================
# FUNCTION 3: CALCULATE NEUTROPENIA RISK (E_max MODEL)
# ==============================================================================
# Source: Courlet et al. 2022 (PMC9322950, Table 2)
# E_max model superior to linear (AIC = -76)
calculate_neutropenia_risk_emax <- function(cmin, e0, emax, ec50, gamma) {
  # E_max logistic model
  cmin_term <- cmin^gamma
  ec50_term <- ec50^gamma
  
  risk <- e0 + emax * (cmin_term / (ec50_term + cmin_term))
  risk <- pmax(0, pmin(1, risk))  # Bound between 0 and 1
  
  return(risk)
}

# ==============================================================================
# FUNCTION 4: SIMULATE INDIVIDUAL PATIENT TRAJECTORY
# ==============================================================================
simulate_patient <- function(patient_id, age, weight, cl_individual, params) {
  
  # Apply allometric scaling
  weight_scalar <- (weight / params$pk$weight_reference)^params$pk$CL_weight_exponent
  cl_adjusted <- cl_individual * weight_scalar
  
  # =========================================================================
  # BASELINE DOSING (125 mg fixed)
  # =========================================================================
  dose_baseline <- params$dose$dose_standard
  cmin_baseline <- calculate_cmin(
    dose_baseline,
    cl_adjusted,
    params$pk$V,
    tau_h = 24
  )
  
  risk_baseline <- calculate_neutropenia_risk_emax(
    cmin_baseline,
    params$pd$E0,
    params$pd$Emax,
    params$pd$EC50,
    params$pd$gamma
  )
  
  # Categorize baseline exposure
  category_baseline <- cut(
    cmin_baseline,
    breaks = c(0, 40, 70, 100, Inf),
    labels = c("Low (<40)", "Target (40-70)", "Caution (70-100)", "High (>100)"),
    right = FALSE
  )
  
  # =========================================================================
  # TDM-GUIDED DOSING (Adaptive)
  # =========================================================================
  # Decision rule: If Cmin > 70, reduce from 125 to 100 mg
  dose_tdm <- ifelse(
    cmin_baseline > params$tdm$tdm_threshold_target,
    params$dose$dose_reduced,      # 100 mg
    params$dose$dose_standard      # 125 mg
  )
  
  cmin_tdm <- calculate_cmin(
    dose_tdm,
    cl_adjusted,
    params$pk$V,
    tau_h = 24
  )
  
  risk_tdm <- calculate_neutropenia_risk_emax(
    cmin_tdm,
    params$pd$E0,
    params$pd$Emax,
    params$pd$EC50,
    params$pd$gamma
  )
  
  category_tdm <- cut(
    cmin_tdm,
    breaks = c(0, 40, 70, 100, Inf),
    labels = c("Low (<40)", "Target (40-70)", "Caution (70-100)", "High (>100)"),
    right = FALSE
  )
  
  dose_reduced_flag <- ifelse(dose_tdm < dose_baseline, 1, 0)
  
  # =========================================================================
  # ECONOMIC CALCULATION
  # =========================================================================
  # Baseline costs
  event_cost_baseline <- risk_baseline * params$cost$hospitalization_cost
  
  # TDM costs (includes assay cost)
  event_cost_tdm <- risk_tdm * params$cost$hospitalization_cost
  tdm_program_cost <- params$cost$tdm_assay_cost * params$cost$tdm_frequency_per_patient
  
  # Return patient result
  return(data.frame(
    patient_id = patient_id,
    age = age,
    weight = weight,
    cl_individual = cl_individual,
    cl_adjusted = cl_adjusted,
    
    # Baseline
    dose_baseline = dose_baseline,
    cmin_baseline = cmin_baseline,
    risk_baseline = risk_baseline,
    category_baseline = category_baseline,
    event_cost_baseline = event_cost_baseline,
    
    # TDM
    dose_tdm = dose_tdm,
    cmin_tdm = cmin_tdm,
    risk_tdm = risk_tdm,
    category_tdm = category_tdm,
    dose_reduced_flag = dose_reduced_flag,
    event_cost_tdm = event_cost_tdm,
    tdm_program_cost = tdm_program_cost,
    total_cost_tdm = event_cost_tdm + tdm_program_cost,
    
    stringsAsFactors = FALSE
  ))
}

# ==============================================================================
# FUNCTION 5: RUN MONTE CARLO SIMULATION (n=1,000)
# ==============================================================================
run_monte_carlo <- function(n_patients, params) {
  
  cat(sprintf("Running Monte Carlo simulation (n=%d patients)...\n", n_patients))
  cat("Generating demographics and PK parameters...\n")
  
  # Generate population
  set.seed(params$simulation$set_seed)
  
  ages <- rnorm(n_patients, params$population$age_mean, params$population$age_sd)
  ages <- pmax(params$population$age_min, pmin(params$population$age_max, ages))
  
  weights <- rnorm(n_patients, params$population$weight_mean, params$population$weight_sd)
  weights <- pmax(params$population$weight_min, pmin(params$population$weight_max, weights))
  
  cls <- generate_individual_cl(n_patients, params$pk$CL, params$pk$CL_iiv)
  
  # Simulate each patient
  cat("Simulating exposure and risk for each patient...\n")
  
  results <- map_df(
    1:n_patients,
    function(i) {
      simulate_patient(i, ages[i], weights[i], cls[i], params)
    }
  )
  
  return(results)
}

# ==============================================================================
# RUN SIMULATION
# ==============================================================================

start_time <- Sys.time()

sim_results <- run_monte_carlo(pop$n_patients, all_params)

end_time <- Sys.time()
elapsed <- as.numeric(end_time - start_time, units = "secs")

cat(sprintf("\n✓ Simulation completed in %.2f seconds\n\n", elapsed))

# ==============================================================================
# CALCULATE SUMMARY STATISTICS
# ==============================================================================

cat("================================================================================\n")
cat("SIMULATION RESULTS SUMMARY\n")
cat("================================================================================\n\n")

# Pharmacokinetic summary
mean_cmin_baseline <- mean(sim_results$cmin_baseline)
sd_cmin_baseline <- sd(sim_results$cmin_baseline)
mean_cmin_tdm <- mean(sim_results$cmin_tdm)
sd_cmin_tdm <- sd(sim_results$cmin_tdm)

# Pharmacodynamic summary
mean_risk_baseline <- mean(sim_results$risk_baseline)
mean_risk_tdm <- mean(sim_results$risk_tdm)
absolute_risk_reduction <- mean_risk_baseline - mean_risk_tdm
relative_risk_reduction <- (mean_risk_baseline - mean_risk_tdm) / mean_risk_baseline

# NNT calculation
if (absolute_risk_reduction > 0) {
  nnt <- 1 / absolute_risk_reduction
} else {
  nnt <- Inf
}

# Cases prevented
cases_baseline <- mean_risk_baseline * pop$n_patients
cases_tdm <- mean_risk_tdm * pop$n_patients
cases_prevented <- cases_baseline - cases_tdm

# Dose reduction rate
n_dose_reduced <- sum(sim_results$dose_reduced_flag)
dose_reduction_rate <- n_dose_reduced / nrow(sim_results)

# Economic analysis
total_cost_baseline <- sum(sim_results$event_cost_baseline)
total_cost_tdm <- sum(sim_results$total_cost_tdm)
net_savings <- total_cost_baseline - total_cost_tdm

cat("PHARMACOKINETICS:\n")
cat(sprintf("Baseline (125 mg):\n"))
cat(sprintf("   • Mean Cmin:     %.1f ng/mL (SD: %.1f)\n", mean_cmin_baseline, sd_cmin_baseline))
cat(sprintf("   • Median Cmin:   %.1f ng/mL\n", median(sim_results$cmin_baseline)))
cat(sprintf("   • Range:         %.1f–%.1f ng/mL\n\n", 
            min(sim_results$cmin_baseline), max(sim_results$cmin_baseline)))

cat(sprintf("TDM-Guided (Adaptive):\n"))
cat(sprintf("   • Mean Cmin:     %.1f ng/mL (SD: %.1f)\n", mean_cmin_tdm, sd_cmin_tdm))
cat(sprintf("   • Median Cmin:   %.1f ng/mL\n", median(sim_results$cmin_tdm)))
cat(sprintf("   • Range:         %.1f–%.1f ng/mL\n\n", 
            min(sim_results$cmin_tdm), max(sim_results$cmin_tdm)))

cat("PHARMACODYNAMICS (Grade 3/4 Neutropenia Risk):\n")
cat(sprintf("   • Baseline Risk:            %.1f%%\n", mean_risk_baseline * 100))
cat(sprintf("   • TDM Risk:                 %.1f%%\n", mean_risk_tdm * 100))
cat(sprintf("   • Absolute Risk Reduction:  %.1f%% ★\n", absolute_risk_reduction * 100))
cat(sprintf("   • Relative Risk Reduction:  %.1f%%\n", relative_risk_reduction * 100))
cat(sprintf("   • Number Needed to Treat:   %.1f ★★★\n\n", nnt))

cat("DOSE ADJUSTMENTS:\n")
cat(sprintf("   • Patients Requiring Reduction: %d (%.1f%%)\n", n_dose_reduced, dose_reduction_rate * 100))
cat(sprintf("   • Dose Reduction (125→100 mg):  %.1f%%\n\n", dose_reduction_rate * 100))

cat("CLINICAL SIGNIFICANCE (per 1,000 patients):\n")
cat(sprintf("   • Cases of G3/4 Neutropenia (Baseline): %.0f\n", cases_baseline))
cat(sprintf("   • Cases of G3/4 Neutropenia (TDM):     %.0f\n", cases_tdm))
cat(sprintf("   • Cases Prevented:                       %.0f ★\n\n", cases_prevented))

cat("ECONOMIC IMPACT (per 1,000 patients):\n")
cat(sprintf("   • Baseline Cost:     $%s\n", format(round(total_cost_baseline), big.mark=",")))
cat(sprintf("   • TDM Cost:          $%s\n", format(round(total_cost_tdm), big.mark=",")))
cat(sprintf("   • Net Savings:       $%s\n", format(round(net_savings), big.mark=",")))
cat(sprintf("   • Cost per case prevented: $%s\n\n", 
            format(round(net_savings / cases_prevented), big.mark=",")))

cat("VALIDATION (PALOMA Trial Calibration):\n")
cat(sprintf("   • Model Baseline (%%):  %.1f%% vs PALOMA 66%%\n", mean_risk_baseline * 100))
cat(sprintf("   • Match Quality:        %s\n\n",
            if (abs(mean_risk_baseline - 0.66) <= 0.02) "✓ EXCELLENT" else "⚠ Review"))

cat("================================================================================\n")
cat("✅ SIMULATION COMPLETE\n")
cat("================================================================================\n\n")

# ==============================================================================
# SAVE RESULTS
# ==============================================================================

if (!dir.exists("outputs")) {
  dir.create("outputs")
}

write.csv(sim_results, "outputs/02_Simulation_Results_Full.csv", row.names = FALSE)

# Summary statistics
summary_stats <- data.frame(
  Metric = c("Mean Cmin (ng/mL)", "SD Cmin (ng/mL)", "Mean Risk (%)", 
             "Baseline Risk (%)", "TDM Risk (%)", "ARR (%)", "NNT",
             "Dose Reduction Rate (%)", "Cases Prevented (per 1,000)",
             "Baseline Cost ($)", "TDM Cost ($)", "Net Savings ($)"),
  Baseline = c(round(mean_cmin_baseline, 1), round(sd_cmin_baseline, 1), 
               round(mean_risk_baseline*100, 1), round(mean_risk_baseline*100, 1),
               NA, NA, NA, NA, NA, round(total_cost_baseline), NA, NA),
  TDM = c(round(mean_cmin_tdm, 1), round(sd_cmin_tdm, 1),
          round(mean_risk_tdm*100, 1), NA, round(mean_risk_tdm*100, 1),
          round(absolute_risk_reduction*100, 1), round(nnt, 1),
          round(dose_reduction_rate*100, 1), round(cases_prevented, 0),
          NA, round(total_cost_tdm), round(net_savings))
)

write.csv(summary_stats, "outputs/02_Summary_Statistics.csv", row.names = FALSE)

cat("Output files saved:\n")
cat("   • outputs/02_Simulation_Results_Full.csv\n")
cat("   • outputs/02_Summary_Statistics.csv\n\n")

# Export for visualization
assign("sim_results", sim_results, envir = .GlobalEnv)
assign("summary_stats", summary_stats, envir = .GlobalEnv)

cat("Ready for visualization (03_visualization.R)\n\n")
