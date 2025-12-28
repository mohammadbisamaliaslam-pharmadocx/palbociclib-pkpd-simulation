# ============================================================================
# PALBOCICLIB TDM - SENSITIVITY ANALYSIS & VISUALIZATION
# ============================================================================
# File: 03_sensitivity_analysis.R
# Purpose: Sensitivity analysis and generate publication-ready figures
# Date: January 1, 2026
# Author: Mohammad Bisam Ali Aslam
# ============================================================================

library(rxode2)
library(tidyverse)
library(data.table)
library(ggplot2)

# Load parameters
source("src/01_model_setup.R")
source("src/02_simulation_engine.R")

# ============================================================================
# 1. SENSITIVITY ANALYSIS - VARY KEY PARAMETERS
# ============================================================================

run_sensitivity_analysis <- function(base_params, param_ranges) {
  sensitivity_results <- list()
  
  # Sensitivity on baseline neutropenia risk
  cat("Running sensitivity on baseline neutropenia risk...\n")
  
  risk_variations <- seq(param_ranges$risk_range[1], param_ranges$risk_range[2], by = 0.05)
  
  for (risk in risk_variations) {
    # Adjust baseline risk
    params_temp <- base_params
    params_temp$pd$baseline_neutropenia_risk <- risk
    
    # Calculate expected outcomes
    baseline_events <- params_temp$population$n_patients * risk
    tdm_events <- baseline_events * 0.82  # 18% reduction
    
    baseline_cost <- baseline_events * params_temp$cost$hospitalization_cost
    tdm_cost <- tdm_events * params_temp$cost$hospitalization_cost + 
                params_temp$population$n_patients * params_temp$cost$tdm_assay_cost
    
    savings <- baseline_cost - tdm_cost
    
    sensitivity_results[[paste0("risk_", risk)]] <- tibble(
      parameter = "baseline_risk",
      value = risk,
      baseline_events = baseline_events,
      tdm_events = tdm_events,
      baseline_cost = baseline_cost,
      tdm_cost = tdm_cost,
      annual_savings = savings
    )
  }
  
  # Sensitivity on hospitalization cost
  cat("Running sensitivity on hospitalization cost...\n")
  
  cost_variations <- seq(15000, 35000, by = 2500)
  
  for (hosp_cost in cost_variations) {
    baseline_events <- all_params$population$n_patients * 0.224
    tdm_events <- baseline_events * 0.82
    
    baseline_cost <- baseline_events * hosp_cost
    tdm_cost <- tdm_events * hosp_cost + 
                all_params$population$n_patients * all_params$cost$tdm_assay_cost
    
    savings <- baseline_cost - tdm_cost
    
    sensitivity_results[[paste0("cost_", hosp_cost)]] <- tibble(
      parameter = "hospitalization_cost",
      value = hosp_cost,
      baseline_events = baseline_events,
      tdm_events = tdm_events,
      baseline_cost = baseline_cost,
      tdm_cost = tdm_cost,
      annual_savings = savings
    )
  }
  
  # Sensitivity on TDM effectiveness (risk reduction)
  cat("Running sensitivity on TDM effectiveness...\n")
  
  effectiveness_variations <- seq(0.10, 0.30, by = 0.02)  # 10-30% reduction
  
  for (effectiveness in effectiveness_variations) {
    baseline_events <- all_params$population$n_patients * 0.224
    tdm_events <- baseline_events * (1 - effectiveness)
    
    baseline_cost <- baseline_events * all_params$cost$hospitalization_cost
    tdm_cost <- tdm_events * all_params$cost$hospitalization_cost + 
                all_params$population$n_patients * all_params$cost$tdm_assay_cost
    
    savings <- baseline_cost - tdm_cost
    
    sensitivity_results[[paste0("effectiveness_", effectiveness)]] <- tibble(
      parameter = "tdm_effectiveness",
      value = effectiveness * 100,  # Convert to percentage
      baseline_events = baseline_events,
      tdm_events = tdm_events,
      baseline_cost = baseline_cost,
      tdm_cost = tdm_cost,
      annual_savings = savings
    )
  }
  
  return(bind_rows(sensitivity_results))
}

# ============================================================================
# 2. TORNADO PLOT - PARAMETER IMPORTANCE
# ============================================================================

create_tornado_plot <- function(sensitivity_data) {
  # Calculate range of savings for each parameter
  tornado_data <- sensitivity_data %>%
    group_by(parameter) %>%
    summarise(
      min_savings = min(annual_savings),
      max_savings = max(annual_savings),
      range = max_savings - min_savings,
      midpoint = (min_savings + max_savings) / 2,
      .groups = 'drop'
    ) %>%
    arrange(desc(range))
  
  # Create tornado plot
  p <- ggplot(tornado_data, aes(x = reorder(parameter, range), y = range)) +
    geom_col(fill = "#2E86AB", alpha = 0.8) +
    coord_flip() +
    labs(
      title = "Sensitivity Analysis: Parameter Impact on Annual Savings",
      subtitle = "Tornado diagram showing range of cost savings (1,000 patients)",
      x = "Parameter",
      y = "Range of Annual Savings ($)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      axis.text.x = element_text(size = 10),
      axis.text.y = element_text(size = 10)
    ) +
    scale_y_continuous(labels = scales::dollar)
  
  return(p)
}

# ============================================================================
# 3. COST-EFFECTIVENESS ACCEPTABILITY CURVE
# ============================================================================

create_ceac <- function(sensitivity_data) {
  # Extract TDM effectiveness sensitivity
  effectiveness_data <- sensitivity_data %>%
    filter(parameter == "tdm_effectiveness") %>%
    mutate(
      cost_per_event_avoided = (baseline_cost - tdm_cost) / (baseline_events - tdm_events),
      positive_benefit = annual_savings > 0
    ) %>%
    arrange(value)
  
  p <- ggplot(effectiveness_data, aes(x = value, y = annual_savings, color = positive_benefit)) +
    geom_line(size = 1, color = "#2E86AB") +
    geom_point(size = 3, color = "#2E86AB") +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.5) +
    labs(
      title = "Cost-Effectiveness: TDM Effectiveness Sensitivity",
      subtitle = "Annual savings per 1,000 patients across TDM effectiveness scenarios",
      x = "TDM Risk Reduction (%)",
      y = "Annual Savings ($)",
      color = "Cost-Effective"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      axis.text = element_text(size = 10),
      legend.position = "bottom"
    ) +
    scale_y_continuous(labels = scales::dollar)
  
  return(p)
}

# ============================================================================
# 4. EXPOSURE-RESPONSE CURVE
# ============================================================================

create_exposure_response_plot <- function(params) {
  # Generate Cmin range
  Cmin_range <- seq(0, 250, by = 5)
  
  # Calculate risk for each Cmin
  risk_data <- tibble(
    Cmin = Cmin_range,
    risk = sapply(Cmin_range, function(c) calculate_neutropenia_risk(c, params))
  )
  
  p <- ggplot(risk_data, aes(x = Cmin, y = risk * 100)) +
    geom_line(size = 1.2, color = "#A23B72") +
    geom_vline(xintercept = params$tdm$tdm_threshold, linetype = "dashed", 
               color = "red", alpha = 0.7, size = 1) +
    annotate("text", x = params$tdm$tdm_threshold + 10, y = 80, 
             label = paste0("TDM Threshold\n", params$tdm$tdm_threshold, " ng/mL"),
             size = 3.5, color = "red") +
    labs(
      title = "Palbociclib Exposure-Response Relationship",
      subtitle = "Grade 3/4 Neutropenia Risk vs Trough Concentration (Cmin)",
      x = "Trough Concentration (ng/mL)",
      y = "Grade 3/4 Neutropenia Risk (%)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      axis.text = element_text(size = 10)
    ) +
    ylim(0, 100)
  
  return(p)
}

# ============================================================================
# 5. MAIN EXECUTION
# ============================================================================

cat("\n")
cat("==========================================================================\n")
cat("RUNNING SENSITIVITY ANALYSIS\n")
cat("==========================================================================\n\n")

# Run sensitivity analysis
sensitivity_results <- run_sensitivity_analysis(
  all_params, 
  all_params$analysis$sensitivity_ranges
)

# Create visualizations
cat("Creating visualizations...\n\n")

tornado_plot <- create_tornado_plot(sensitivity_results)
ceac_plot <- create_ceac(sensitivity_results)
exposure_response_plot <- create_exposure_response_plot(all_params)

# Save plots
ggsave("results/tornado_plot.png", tornado_plot, width = 10, height = 6, dpi = 300)
ggsave("results/ceac_plot.png", ceac_plot, width = 10, height = 6, dpi = 300)
ggsave("results/exposure_response_plot.png", exposure_response_plot, width = 10, height = 6, dpi = 300)

# Print summary
cat("==========================================================================\n")
cat("SENSITIVITY ANALYSIS SUMMARY\n")
cat("==========================================================================\n\n")

# Group by parameter and show range
summary_by_param <- sensitivity_results %>%
  group_by(parameter) %>%
  summarise(
    min_savings = min(annual_savings),
    max_savings = max(annual_savings),
    range = max_savings - min_savings,
    .groups = 'drop'
  ) %>%
  arrange(desc(range))

cat("Parameter Sensitivity (Annual Savings Range per 1,000 Patients):\n\n")
for (i in 1:nrow(summary_by_param)) {
  row <- summary_by_param[i,]
  cat(sprintf("  %s:\n", row$parameter))
  cat(sprintf("    Min: $%s\n", format(round(row$min_savings), big.mark=",")))
  cat(sprintf("    Max: $%s\n", format(round(row$max_savings), big.mark=",")))
  cat(sprintf("    Range: $%s\n\n", format(round(row$range), big.mark=",")))
}

cat("==========================================================================\n")
cat("Plots saved to results/ folder:\n")
cat("  - tornado_plot.png\n")
cat("  - ceac_plot.png\n")
cat("  - exposure_response_plot.png\n")
cat("==========================================================================\n\n")

# Save sensitivity results
saveRDS(sensitivity_results, "results/sensitivity_analysis.rds")
write_csv(sensitivity_results, "results/sensitivity_analysis.csv")

cat("Sensitivity data saved as CSV and RDS\n")

