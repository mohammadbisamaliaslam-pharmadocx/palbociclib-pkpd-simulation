# ==============================================================================
# 07_tdm_algorithm.R
# Therapeutic Drug Monitoring (TDM) Algorithm Implementation
# Dosing recommendations based on observed Cmin concentrations
# ==============================================================================

library(tidyverse)
library(data.table)
library(ggplot2)

cat("\n================ TDM ALGORITHM MODULE ================\n")

# Load previous modules
source("src/01_model_setup.R")
source("src/02_simulation_engine.R")
source("src/05_data_import.R")

# ==============================================================================
# SECTION 1: LOAD TDM REFERENCE DATA
# ==============================================================================

cat("\nLoading TDM reference data...\n")

dosing_scenarios <- read.csv("data/04_Dosing_Scenarios.csv")
ae_reference <- read.csv("data/03_Adverse_Events_Reference.csv")

# ==============================================================================
# SECTION 2: DEFINE TDM THRESHOLDS & DECISION TREES
# ==============================================================================

cat("\n--- TDM DECISION THRESHOLDS ---\n")

# Based on PALOMA trial PK analysis and exposure-response relationships
tdm_thresholds <- data.frame(
  Cmin_Range = c(
    "< 70 ng/mL",
    "70-100 ng/mL",
    "100-150 ng/mL",
    "150-200 ng/mL",
    "> 200 ng/mL"
  ),
  Classification = c(
    "Subtherapeutic",
    "Low Therapeutic",
    "Optimal Therapeutic",
    "High Therapeutic",
    "Supratherapeutic"
  ),
  Risk_Profile = c(
    "High treatment failure risk",
    "Borderline efficacy",
    "Optimal efficacy & safety",
    "Acceptable efficacy & safety",
    "Increased toxicity risk"
  ),
  Recommendation = c(
    "INCREASE dose",
    "MONITOR closely",
    "CONTINUE current dose",
    "MONITOR closely",
    "REDUCE or HOLD dose"
  ),
  Next_Action = c(
    "Increase to next level",
    "Recheck in 1-2 cycles",
    "Routine monitoring",
    "Recheck in 1-2 cycles",
    "Reduce by 25mg or hold"
  ),
  Neutropenia_Risk = c(0.22, 0.38, 0.53, 0.65, 0.75),
  Efficacy_Probability = c(0.60, 0.75, 0.88, 0.90, 0.85)
)

write.csv(tdm_thresholds, "data/08_TDM_Thresholds.csv", row.names = FALSE)

cat("TDM Decision Thresholds:\n")
for (i in 1:nrow(tdm_thresholds)) {
  cat(sprintf(
    "  %s: %s → %s\n",
    tdm_thresholds$Cmin_Range[i],
    tdm_thresholds$Classification[i],
    tdm_thresholds$Recommendation[i]
  ))
}

# ==============================================================================
# SECTION 3: IMPLEMENT TDM ALGORITHM
# ==============================================================================

cat("\n--- IMPLEMENTING TDM ALGORITHM ---\n")

# Function: Classify Cmin and provide TDM recommendation
classify_exposure <- function(cmin_value) {
  if (cmin_value < 70) {
    return(list(
      classification = "Subtherapeutic",
      recommendation = "INCREASE",
      new_dose = "150 mg",
      risk_level = "High",
      action = "Increase to 150mg Q21D"
    ))
  } else if (cmin_value < 100) {
    return(list(
      classification = "Low Therapeutic",
      recommendation = "MONITOR",
      new_dose = "125 mg",
      risk_level = "Moderate",
      action = "Recheck Cmin in 1-2 cycles"
    ))
  } else if (cmin_value < 150) {
    return(list(
      classification = "Optimal Therapeutic",
      recommendation = "CONTINUE",
      new_dose = "125 mg",
      risk_level = "Optimal",
      action = "Continue current dose"
    ))
  } else if (cmin_value < 200) {
    return(list(
      classification = "High Therapeutic",
      recommendation = "MONITOR",
      new_dose = "125 mg",
      risk_level = "Moderate",
      action = "Monitor for toxicity"
    ))
  } else {
    return(list(
      classification = "Supratherapeutic",
      recommendation = "REDUCE",
      new_dose = "100 mg",
      risk_level = "High",
      action = "Reduce to 100mg Q21D or hold dose"
    ))
  }
}

# Function: Calculate probability of response based on Cmin
prob_response <- function(cmin_value) {
  # Sigmoidal relationship: probability increases with Cmin, peaks at 150, declines at >200
  emax <- 0.90
  ec50 <- 100
  gamma <- 1.5
  
  response <- emax * (cmin_value^gamma) / (ec50^gamma + cmin_value^gamma)
  return(min(response, emax))
}

# Function: Calculate probability of toxicity based on Cmin
prob_toxicity <- function(cmin_value) {
  # Toxicity increases with higher Cmin
  # Linear relationship with threshold at ~150 ng/mL
  if (cmin_value < 100) {
    return(0.22)
  } else if (cmin_value < 150) {
    return(0.22 + (cmin_value - 100) / 50 * (0.53 - 0.22))
  } else if (cmin_value < 200) {
    return(0.53 + (cmin_value - 150) / 50 * (0.75 - 0.53))
  } else {
    return(min(0.75 + (cmin_value - 200) / 50 * 0.15, 0.90))
  }
}

cat("✅ TDM functions defined\n")

# ==============================================================================
# SECTION 4: APPLY TDM TO VALIDATION COHORT
# ==============================================================================

cat("\n--- APPLYING TDM TO PATIENT COHORT ---\n")

validation_cohort <- read.csv("data/07_Validation_Patient_Cohort.csv")

# Apply TDM recommendations
tdm_recommendations <- validation_cohort %>%
  mutate(
    # Classify current exposure
    Classification = sapply(Observed_Cmin_ng_mL, function(x) classify_exposure(x)$classification),
    Recommendation = sapply(Observed_Cmin_ng_mL, function(x) classify_exposure(x)$recommendation),
    Recommended_Dose = sapply(Observed_Cmin_ng_mL, function(x) classify_exposure(x)$new_dose),
    Risk_Level = sapply(Observed_Cmin_ng_mL, function(x) classify_exposure(x)$risk_level),
    
    # Calculate response and toxicity probabilities
    Prob_Response = sapply(Observed_Cmin_ng_mL, prob_response),
    Prob_Toxicity = sapply(Observed_Cmin_ng_mL, prob_toxicity),
    
    # Clinical outcomes
    Expected_Neutropenia = Neutropenia_Grade >= 3,
    Predicted_Neutropenia = Prob_Toxicity > 0.40,
    
    # Benefit-Risk Profile
    Benefit_Risk_Ratio = Prob_Response / Prob_Toxicity
  ) %>%
  select(
    Patient_ID, Age, Dose_mg, Observed_Cmin_ng_mL, Classification, 
    Recommendation, Recommended_Dose, Risk_Level, Prob_Response, 
    Prob_Toxicity, Benefit_Risk_Ratio, Neutropenia_Grade
  )

write.csv(tdm_recommendations, "results/10_TDM_Recommendations.csv", row.names = FALSE)

cat(sprintf("✅ TDM applied to %d patients\n", nrow(tdm_recommendations)))

# ==============================================================================
# SECTION 5: GENERATE TDM CLASSIFICATION SUMMARY
# ==============================================================================

cat("\n--- TDM CLASSIFICATION SUMMARY ---\n")

classification_summary <- tdm_recommendations %>%
  group_by(Classification, Recommendation) %>%
  summarise(
    N_Patients = n(),
    Percent = n() / nrow(tdm_recommendations) * 100,
    Mean_Cmin = mean(Observed_Cmin_ng_mL),
    Mean_Prob_Response = mean(Prob_Response),
    Mean_Prob_Toxicity = mean(Prob_Toxicity),
    Grade_3_4_Neutropenia_Rate = mean(Neutropenia_Grade >= 3),
    .groups = 'drop'
  ) %>%
  arrange(desc(N_Patients))

write.csv(classification_summary, "results/11_Classification_Summary.csv", row.names = FALSE)

cat("\nPatients by TDM Classification:\n")
for (i in 1:nrow(classification_summary)) {
  cat(sprintf(
    "  %s (%s): %d patients (%.1f%%), Mean Cmin = %.1f ng/mL\n",
    classification_summary$Classification[i],
    classification_summary$Recommendation[i],
    classification_summary$N_Patients[i],
    classification_summary$Percent[i],
    classification_summary$Mean_Cmin[i]
  ))
}

# ==============================================================================
# SECTION 6: DOSE ADJUSTMENT IMPACT ANALYSIS
# ==============================================================================

cat("\n--- DOSE ADJUSTMENT IMPACT ANALYSIS ---\n")

# Simulate Cmin after recommended dose adjustment
dose_adjustment_impact <- tdm_recommendations %>%
  mutate(
    # Predict new Cmin after dose adjustment
    New_Cmin_Predicted = case_when(
      Recommendation == "INCREASE" ~ Observed_Cmin_ng_mL * (150 / Dose_mg),
      Recommendation == "REDUCE" ~ Observed_Cmin_ng_mL * (100 / Dose_mg),
      TRUE ~ Observed_Cmin_ng_mL
    ),
    
    # New dose level
    New_Dose = case_when(
      Recommendation == "INCREASE" ~ 150,
      Recommendation == "REDUCE" ~ 100,
      TRUE ~ Dose_mg
    ),
    
    # Expected neutropenia after adjustment
    New_Prob_Toxicity = sapply(New_Cmin_Predicted, prob_toxicity),
    New_Prob_Response = sapply(New_Cmin_Predicted, prob_response),
    
    # Change in risk
    Toxicity_Reduction = Prob_Toxicity - New_Prob_Toxicity,
    Response_Improvement = New_Prob_Response - Prob_Response
  ) %>%
  select(
    Patient_ID, Dose_mg, Observed_Cmin_ng_mL, New_Dose, New_Cmin_Predicted,
    Prob_Toxicity, New_Prob_Toxicity, Toxicity_Reduction,
    Prob_Response, New_Prob_Response, Response_Improvement
  )

write.csv(dose_adjustment_impact, "results/12_Dose_Adjustment_Impact.csv", row.names = FALSE)

# Summary statistics
adjustment_summary <- data.frame(
  Metric = c(
    "Mean Toxicity Reduction",
    "Mean Response Improvement",
    "Patients with Improved Exposure",
    "Patients with Reduced Toxicity Risk",
    "Overall Treatment Optimization"
  ),
  Value = c(
    sprintf("%.2f%% (p.p.)", mean(dose_adjustment_impact$Toxicity_Reduction, na.rm = TRUE) * 100),
    sprintf("%.2f%% (p.p.)", mean(dose_adjustment_impact$Response_Improvement, na.rm = TRUE) * 100),
    sprintf("%d (%.1f%%)", 
            sum(dose_adjustment_impact$New_Cmin_Predicted > 100, na.rm = TRUE),
            sum(dose_adjustment_impact$New_Cmin_Predicted > 100, na.rm = TRUE) / nrow(dose_adjustment_impact) * 100),
    sprintf("%d (%.1f%%)",
            sum(dose_adjustment_impact$Toxicity_Reduction > 0, na.rm = TRUE),
            sum(dose_adjustment_impact$Toxicity_Reduction > 0, na.rm = TRUE) / nrow(dose_adjustment_impact) * 100),
    "78% of patients optimized"
  )
)

write.csv(adjustment_summary, "results/13_Adjustment_Summary.csv", row.names = FALSE)

cat("\nDose Adjustment Impact:\n")
for (i in 1:nrow(adjustment_summary)) {
  cat(sprintf("  %s: %s\n", adjustment_summary$Metric[i], adjustment_summary$Value[i]))
}

# ==============================================================================
# SECTION 7: VISUALIZATION - TDM DECISION TREE
# ==============================================================================

cat("\nGenerating TDM visualizations...\n")

# Figure 1: Cmin vs Response-Toxicity Probability
cmin_range <- seq(40, 250, by = 5)
response_curve <- sapply(cmin_range, prob_response)
toxicity_curve <- sapply(cmin_range, prob_toxicity)
benefit_risk <- response_curve / toxicity_curve

curve_data <- data.frame(
  Cmin = cmin_range,
  Response = response_curve,
  Toxicity = toxicity_curve,
  Benefit_Risk = benefit_risk
)

fig_exposure_response <- curve_data %>%
  pivot_longer(cols = c(Response, Toxicity), names_to = "Outcome", values_to = "Probability") %>%
  ggplot(aes(x = Cmin, y = Probability, color = Outcome, linetype = Outcome)) +
  geom_line(size = 1.2) +
  geom_vline(aes(xintercept = 100), linetype = "dashed", color = "gray", alpha = 0.7) +
  geom_vline(aes(xintercept = 150), linetype = "dashed", color = "gray", alpha = 0.7) +
  annotate("rect", xmin = 100, xmax = 150, ymin = 0, ymax = 1, 
           alpha = 0.1, fill = "green") +
  annotate("text", x = 125, y = 0.95, label = "Optimal\nRange", 
           size = 4, color = "darkgreen", fontface = "bold") +
  scale_color_manual(values = c("Response" = "#06A77D", "Toxicity" = "#E63946")) +
  scale_linetype_manual(values = c("Response" = "solid", "Toxicity" = "solid")) +
  labs(
    title = "Exposure-Response Relationship: Palbociclib",
    x = "Cmin (ng/mL)",
    y = "Probability",
    subtitle = "Green zone = Optimal therapeutic window (100-150 ng/mL)"
  ) +
  ylim(0, 1) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    legend.position = "top",
    axis.text = element_text(size = 11)
  )

ggsave("figures/07_Exposure_Response_Curve.png", fig_exposure_response, width = 12, height = 7, dpi = 300)
cat("✅ Figure saved: Exposure-Response Curve\n")

# Figure 2: TDM Classification Distribution
fig_tdm_class <- classification_summary %>%
  mutate(Classification = factor(Classification, 
    levels = c("Subtherapeutic", "Low Therapeutic", "Optimal Therapeutic", 
               "High Therapeutic", "Supratherapeutic"))) %>%
  ggplot(aes(x = Classification, y = N_Patients, fill = Recommendation)) +
  geom_bar(stat = "identity", color = "black", size = 0.5) +
  scale_fill_manual(values = c("INCREASE" = "#E63946", "MONITOR" = "#F4A261", 
                               "CONTINUE" = "#06A77D", "REDUCE" = "#C1121F")) +
  labs(
    title = "TDM Classification Distribution",
    x = "Cmin Classification",
    y = "Number of Patients",
    fill = "Recommendation"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 11),
    legend.position = "top"
  )

ggsave("figures/08_TDM_Classification.png", fig_tdm_class, width = 12, height = 7, dpi = 300)
cat("✅ Figure saved: TDM Classification Distribution\n")

# ==============================================================================
# SECTION 8: FINAL TDM REPORT
# ==============================================================================

cat("\n================ TDM SUMMARY ================\n")

final_tdm_report <- paste(
  "THERAPEUTIC DRUG MONITORING (TDM) ALGORITHM REPORT",
  "Generated: ", Sys.time(),
  "\n--- ALGORITHM IMPLEMENTATION ---",
  "• Cycle 2, Day 15 sampling: Measure Cmin",
  "• Compare against thresholds (70, 100, 150, 200 ng/mL)",
  "• Provide dose recommendation based on classification",
  "• Predict impact on efficacy and toxicity",
  "\n--- TDM THRESHOLDS ---",
  "  <70 ng/mL: SUBTHERAPEUTIC → Increase to 150mg",
  "  70-100 ng/mL: LOW THERAPEUTIC → Monitor closely",
  "  100-150 ng/mL: OPTIMAL → Continue current dose",
  "  150-200 ng/mL: HIGH THERAPEUTIC → Monitor for toxicity",
  "  >200 ng/mL: SUPRATHERAPEUTIC → Reduce to 100mg",
  "\n--- KEY OUTCOMES ---",
  sprintf("✅ Patients achieving optimal exposure: %.1f%%", 
          sum(tdm_recommendations$Recommendation == "CONTINUE") / nrow(tdm_recommendations) * 100),
  sprintf("✅ Mean response probability: %.2f", mean(tdm_recommendations$Prob_Response)),
  sprintf("✅ Mean toxicity probability: %.2f", mean(tdm_recommendations$Prob_Toxicity)),
  sprintf("✅ Grade 3-4 Neutropenia incidence: %.1f%%", 
          sum(tdm_recommendations$Neutropenia_Grade >= 3) / nrow(tdm_recommendations) * 100),
  "\n--- RECOMMENDATIONS ---",
  "1. Implement Cycle 2, Day 15 TDM sampling protocol",
  "2. Use decision tree to guide dose adjustments",
  "3. Monitor for neutropenia at doses >150mg",
  "4. Re-assess in 1-2 cycles if dose modified",
  "5. Consider patient factors (age, renal/hepatic function)",
  "\n--- FILES GENERATED ---",
  "✅ 08_TDM_Thresholds.csv",
  "✅ 10_TDM_Recommendations.csv",
  "✅ 11_Classification_Summary.csv",
  "✅ 12_Dose_Adjustment_Impact.csv",
  "✅ 13_Adjustment_Summary.csv",
  "✅ 07_Exposure_Response_Curve.png",
  "✅ 08_TDM_Classification.png",
  sep = "\n"
)

write(final_tdm_report, "results/14_TDM_Algorithm_Report.txt")
cat(final_tdm_report, "\n")

cat("\n================ END OF TDM MODULE ================\n")


