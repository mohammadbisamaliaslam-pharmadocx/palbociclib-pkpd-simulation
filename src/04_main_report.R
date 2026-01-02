# ============================================================================
# PALBOCICLIB TDM - MAIN EXECUTION & REPORT GENERATION
# ============================================================================
# File: 04_main_report.R
# Purpose: Execute full analysis pipeline 
# Date: January 2, 2026
# Author: Mohammad Bisam Ali Aslam
# ============================================================================

library(rxode2)
library(tidyverse)
library(data.table)
library(ggplot2)
library(knitr)
library(rmarkdown)

# ============================================================================
# 1. CREATE RESULTS DIRECTORY
# ============================================================================

if (!dir.exists("results")) {
  dir.create("results", showWarnings = FALSE)
  cat("Created results/ directory\n")
}

# ============================================================================
# 2. LOAD AND EXECUTE ANALYSIS PIPELINE
# ============================================================================

cat("\n")
cat("==========================================================================\n")
cat("PALBOCICLIB TDM COST-EFFECTIVENESS ANALYSIS\n")
cat("==========================================================================\n\n")

cat("Step 1: Loading parameters...\n")
source("src/01_model_setup.R")

cat("Step 2: Running simulation engine...\n")
source("src/02_simulation_engine.R")

cat("Step 3: Running sensitivity analysis...\n")
source("src/03_sensitivity_analysis.R")

# ============================================================================
# 3. GENERATE SUMMARY STATISTICS
# ============================================================================

cat("\nStep 4: Generating summary statistics...\n\n")

# Extract key results
baseline_risk <- all_params$expected$baseline_neutropenia_risk * 100
tdm_risk <- all_params$expected$tdm_neutropenia_risk * 100
risk_reduction <- ((all_params$expected$baseline_neutropenia_risk - 
                    all_params$expected$tdm_neutropenia_risk) / 
                   all_params$expected$baseline_neutropenia_risk) * 100

baseline_cost <- all_params$expected$baseline_total_cost
tdm_cost <- all_params$expected$tdm_total_cost
annual_savings <- all_params$expected$annual_savings
savings_per_patient <- annual_savings / all_params$population$n_patients

# Create summary table
summary_table <- tibble(
  Metric = c(
    "Baseline Neutropenia Risk",
    "TDM-Guided Neutropenia Risk",
    "Risk Reduction",
    "Baseline Total Cost",
    "TDM Total Cost",
    "Annual Savings",
    "Savings per Patient",
    "Cost per Risk Reduction",
    "Population Size",
    "Treatment Cycles"
  ),
  Value = c(
    paste0(round(baseline_risk, 1), "%"),
    paste0(round(tdm_risk, 1), "%"),
    paste0(round(risk_reduction, 1), "%"),
    paste0("$", format(round(baseline_cost), big.mark = ",")),
    paste0("$", format(round(tdm_cost), big.mark = ",")),
    paste0("$", format(round(annual_savings), big.mark = ",")),
    paste0("$", format(round(savings_per_patient), big.mark = ",")),
    paste0("$", format(round(baseline_cost / (baseline_risk/100)), big.mark = ",")),
    all_params$population$n_patients,
    all_params$simulation$n_cycles
  )
)

# ============================================================================
# 4. CREATE COMPREHENSIVE FIGURES
# ============================================================================

cat("Creating comprehensive figures...\n\n")

# Figure 1: Cost Comparison
cost_comparison <- tibble(
  Strategy = c("Baseline\n(Standard Dosing)", "TDM-Guided\n(Dose Reduction)"),
  `Total Cost ($)` = c(baseline_cost, tdm_cost),
  Color = c("#E63946", "#06D6A0")
)

fig1 <- ggplot(cost_comparison, aes(x = Strategy, y = `Total Cost ($)`, fill = Color)) +
  geom_col(alpha = 0.85) +
  geom_text(aes(label = paste0("$", format(round(`Total Cost ($)`/1e6, 2), trim = TRUE), "M")),
            vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_identity() +
  labs(
    title = "Annual Healthcare Cost Comparison",
    subtitle = "1,000 patients over 4 treatment cycles",
    x = "",
    y = "Total Cost ($)",
    caption = "Includes hospitalization and TDM program costs"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 11),
    legend.position = "none"
  ) +
  ylim(0, max(baseline_cost, tdm_cost) * 1.15)

ggsave("results/fig1_cost_comparison.png", fig1, width = 8, height = 6, dpi = 300)

# Figure 2: Risk Reduction
risk_data <- tibble(
  Strategy = c("Baseline", "TDM-Guided"),
  `Grade 3/4 Neutropenia Risk` = c(baseline_risk, tdm_risk),
  Color = c("#E63946", "#06D6A0")
)

fig2 <- ggplot(risk_data, aes(x = Strategy, y = `Grade 3/4 Neutropenia Risk`, fill = Color)) +
  geom_col(alpha = 0.85) +
  geom_text(aes(label = paste0(round(`Grade 3/4 Neutropenia Risk`, 1), "%")),
            vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_identity() +
  labs(
    title = "Grade 3/4 Neutropenia Incidence",
    subtitle = paste0("Risk reduction: ", round(risk_reduction, 1), "%"),
    x = "",
    y = "Incidence (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 11),
    legend.position = "none"
  ) +
  ylim(0, 30)

ggsave("results/fig2_risk_reduction.png", fig2, width = 8, height = 6, dpi = 300)

# Figure 3: Cost-Benefit Analysis
cost_benefit <- tibble(
  Component = c("Baseline\nHospitalization", "TDM Program\nCost", "Avoided\nHospitalization"),
  `Cost ($)` = c(
    baseline_cost,
    all_params$population$n_patients * all_params$cost$tdm_assay_cost,
    -(baseline_cost - tdm_cost + all_params$population$n_patients * all_params$cost$tdm_assay_cost)
  ),
  Type = c("Cost", "Cost", "Benefit")
)

fig3 <- ggplot(cost_benefit, aes(x = Component, y = `Cost ($)`, fill = Type)) +
  geom_col(alpha = 0.85) +
  scale_fill_manual(values = c("Cost" = "#E63946", "Benefit" = "#06D6A0")) +
  geom_text(aes(label = paste0("$", format(round(abs(`Cost ($)`)/1e6, 2), trim = TRUE), "M")),
            vjust = ifelse(cost_benefit$Type == "Benefit", 1.5, -0.5),
            size = 3.5, fontface = "bold") +
  labs(
    title = "Cost-Benefit Breakdown",
    subtitle = paste0("Net Annual Savings: $", format(round(annual_savings), big.mark = ",")),
    x = "",
    y = "Cost Impact ($)",
    fill = ""
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "green", face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "bottom"
  )

ggsave("results/fig3_cost_benefit.png", fig3, width = 9, height = 6, dpi = 300)

# ============================================================================
# 5. GENERATE MARKDOWN REPORT
# ============================================================================

cat("Generating markdown report...\n\n")

report_content <- paste0("
# Palbociclib TDM Cost-Effectiveness Analysis Report

**Date:** ", format(Sys.Date(), "%B %d, %Y"), "
**Author:** Mohammad Bisam Ali Aslam
**Institution:** Faculty of Pharmacy, Aga Khan University

---

## Executive Summary

This analysis evaluates the cost-effectiveness of therapeutic drug monitoring (TDM)-guided palbociclib dosing compared to standard fixed-dose therapy for breast cancer patients.

### Key Findings

- **Baseline Neutropenia Risk:** ", round(baseline_risk, 1), "%
- **TDM-Guided Neutropenia Risk:** ", round(tdm_risk, 1), "%
- **Risk Reduction:** ", round(risk_reduction, 1), "%
- **Annual Savings (1,000 patients):** $", format(round(annual_savings), big.mark = ","), "
- **Savings per Patient:** $", format(round(savings_per_patient), big.mark = ","), "

---

## Background

Palbociclib is a cyclin-dependent kinase 4/6 (CDK4/6) inhibitor approved for breast cancer treatment. However, it causes severe neutropenia in 66% of patients at standard 125 mg daily dosing, requiring costly hospitalizations (average cost: $22,839 per event).

Therapeutic drug monitoring (TDM) is standard practice for many oncology drugs but remains unexplored for palbociclib. This analysis investigates whether TDM-guided dose reduction can mitigate neutropenia while maintaining efficacy.

---

## Methods

### Study Design
Monte Carlo simulation of 1,000 patients receiving palbociclib 125 mg daily for 4 treatment cycles (21 days on, 7 days off).

### Pharmacokinetic Model
- **Clearance (CL):** ", all_params$pk$CL, " L/h (with ", all_params$pk$CL_iiv * 100, "% IIV)
- **Volume of Distribution (V):** ", all_params$pk$V, " L (with ", all_params$pk$V_iiv * 100, "% IIV)

### TDM Decision Rule
- **Sampling:** Day 15 of first cycle
- **Threshold:** If Cmin > ", all_params$tdm$tdm_threshold, " ng/mL, reduce to 100 mg starting Cycle 2
- **Expected Risk Reduction:** ~18%

### Cost Analysis
- **Hospitalization Cost:** $", format(all_params$cost$hospitalization_cost, big.mark = ","), " per event
- **TDM Assay Cost:** $", all_params$cost$tdm_assay_cost, " per patient per cycle
- **Population:** ", all_params$population$n_patients, " patients

---

## Results

### Primary Outcomes

| Metric | Baseline | TDM-Guided | Difference |
|--------|----------|-----------|-----------|
| Neutropenia Risk | ", round(baseline_risk, 1), "% | ", round(tdm_risk, 1), "% | -", round(risk_reduction, 1), "% |
| Total Cost | $", format(round(baseline_cost), big.mark = ","), " | $", format(round(tdm_cost), big.mark = ","), " | -$", format(round(annual_savings), big.mark = ","), " |
| Cost per Patient | $", format(round(baseline_cost/all_params$population$n_patients), big.mark = ","), " | $", format(round(tdm_cost/all_params$population$n_patients), big.mark = ","), " | -$", format(round(savings_per_patient), big.mark = ","), " |

### Sensitivity Analysis Range

Annual savings across parameter variations:
- **Minimum:** $", format(all_params$expected$savings_min, big.mark = ","), "
- **Maximum:** $", format(all_params$expected$savings_max, big.mark = ","), "

---

## Figures

### Figure 1: Annual Healthcare Cost Comparison
![Cost Comparison](fig1_cost_comparison.png)

### Figure 2: Grade 3/4 Neutropenia Incidence
![Risk Reduction](fig2_risk_reduction.png)

### Figure 3: Cost-Benefit Analysis
![Cost-Benefit](fig3_cost_benefit.png)

### Figure 4: Tornado Sensitivity Plot
![Tornado Plot](tornado_plot.png)

### Figure 5: Cost-Effectiveness Acceptability Curve
![CEAC](ceac_plot.png)

### Figure 6: Exposure-Response Relationship
![Exposure-Response](exposure_response_plot.png)

---

## Conclusions

TDM-guided palbociclib dosing reduces Grade 3/4 neutropenia incidence by ", round(risk_reduction, 1), "% while generating $", format(round(annual_savings), big.mark = ","), " in annual savings per 1,000 patients. This cost-effectiveness supports hospital implementation of TDM programs for palbociclib patients.

### Recommendations

1. **Implement TDM Program:** Hospitals should consider adopting Day 15 TDM assessments for palbociclib patients
2. **Patient Selection:** Prioritize high-risk patients (elderly, renal impairment, concomitant medications)
3. **Prospective Validation:** Conduct clinical trial to confirm simulation findings
4. **Cost Optimization:** Negotiate TDM assay costs to maximize economic benefit

---

## Reproducibility

All code and analysis scripts are available at:
[GitHub Repository](https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation)

---

*Analysis completed: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*
")

writeLines(report_content, "results/ANALYSIS_REPORT.md")

# ============================================================================
# 6. SAVE SUMMARY TABLE
# ============================================================================

write_csv(summary_table, "results/summary_table.csv")

cat("\n")
cat("==========================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("==========================================================================\n\n")

cat("Results Summary:\n")
print(summary_table, n = Inf)

cat("\n")
cat("Output Files Generated:\n")
cat("  ✓ results/ANALYSIS_REPORT.md\n")
cat("  ✓ results/summary_table.csv\n")
cat("  ✓ results/simulation_output.rds\n")
cat("  ✓ results/cost_analysis.rds\n")
cat("  ✓ results/sensitivity_analysis.rds\n")
cat("  ✓ results/sensitivity_analysis.csv\n")
cat("  ✓ results/fig1_cost_comparison.png\n")
cat("  ✓ results/fig2_risk_reduction.png\n")
cat("  ✓ results/fig3_cost_benefit.png\n")
cat("  ✓ results/tornado_plot.png\n")
cat("  ✓ results/ceac_plot.png\n")
cat("  ✓ results/exposure_response_plot.png\n")
cat("\n")
cat("==========================================================================\n")
cat("Report generated successfully!\n")
cat("==========================================================================\n\n")

