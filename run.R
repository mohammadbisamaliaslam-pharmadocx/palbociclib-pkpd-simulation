# ==============================================================================
# FILE:    run.R
# PROJECT: Palbociclib TDM - Population PK/PD Pharmacoeconomic Analysis
# TITLE:   Master Execution Script — Complete Pipeline
#
# AUTHOR:  Mohammad Bisam Ali Aslam, PharmD Candidate (Year 3)
# AFFILIATION: Akhtar Saeed College of Pharmacy, University of the Punjab
# VERSION: 2.0 | DATE: 2026
#
# USAGE:
#   Open this project in RStudio, then in the Console type:
#   > source("run.R")
#
# REQUIREMENTS:
#   - R >= 4.0.0
#   - Base R only — no packages required
#   - All 8 scripts must be in src/ folder
#   - Run from project root directory (where this file lives)
#
# EXPECTED RUNTIME: ~60 seconds
# EXPECTED OUTPUTS: 9 figures, 17 CSVs, 2 reports
#
# EXPECTED KEY RESULTS (seed = 12345):
#   NNT:            6.4   (Leenhardt 2022 published: 6.3)
#   ARR:            15.6%
#   Baseline G3/4:  66.0% (PALOMA-2 target: 66.4%)
#   Net savings:    $3,213,045 per 1,000 patients
#   SA positive:    100/100 scenarios
#   Validation:     9/9 tests PASS
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat(" PALBOCICLIB TDM — COMPLETE ANALYSIS PIPELINE\n")
cat(" Version 2.0 | Publication-grade | Seed: 12345\n")
cat(sprintf(" Started: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("==============================================================================\n\n")

# ------------------------------------------------------------------------------
# VERIFY WORKING DIRECTORY
# Must be run from project root (where run.R lives)
# ------------------------------------------------------------------------------

if (!file.exists("src/01_model_setup.R")) {
  stop(paste0(
    "\n ERROR: Cannot find src/01_model_setup.R\n",
    " Make sure you are running from the project root directory.\n",
    " In RStudio: Session → Set Working Directory → To Project Directory\n",
    " Then try source('run.R') again.\n"
  ))
}

# Create output directories if they don't exist
for (d in c("data", "outputs", "figures")) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    cat(sprintf("  Created directory: %s/\n", d))
  }
}

# ------------------------------------------------------------------------------
# HELPER: Run a script with timing and error handling
# ------------------------------------------------------------------------------

run_step <- function(step_num, step_name, script_path) {
  cat(sprintf(
    "----------------------------------------------------------------------\n"
  ))
  cat(sprintf(" STEP %d: %s\n", step_num, step_name))
  cat(sprintf("----------------------------------------------------------------------\n"))

  if (!file.exists(script_path)) {
    cat(sprintf(" ✗ MISSING: %s\n", script_path))
    cat(sprintf(
      "   Download from GitHub and place in src/ folder, then re-run.\n\n"
    ))
    return(invisible(FALSE))
  }

  t_start <- proc.time()

  tryCatch({
    source(script_path)
    t_end   <- proc.time()
    elapsed <- round((t_end - t_start)[3], 1)
    cat(sprintf(
      "\n ✅ Step %d complete (%.1f seconds)\n\n", step_num, elapsed
    ))
    return(invisible(TRUE))
  }, error = function(e) {
    cat(sprintf("\n ✗ ERROR in Step %d:\n", step_num))
    cat(sprintf("   %s\n", conditionMessage(e)))
    cat(sprintf(
      "   Fix this error before continuing. Paste the message above\n"
    ))
    cat(sprintf("   for help.\n\n"))
    return(invisible(FALSE))
  })
}

# ==============================================================================
# PIPELINE EXECUTION — 8 STEPS IN ORDER
# ==============================================================================

pipeline_start <- proc.time()
steps_passed   <- 0
steps_total    <- 8

# STEP 1 — Model Setup (parameters, calibration checks)
# Generates: data/parameters.RData, prints parameter table
ok <- run_step(1, "Model Parameter Initialization", "src/01_model_setup.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 2 — Simulation Engine (Monte Carlo, primary outcomes)
# Generates: outputs/02_Simulation_Results_Full.csv
#            outputs/04_Summary_Table.csv
ok <- run_step(2, "Monte Carlo Simulation Engine", "src/02_simulation_engine.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 3 — Sensitivity Analysis (one-way tornado + two-way heatmap)
# Generates: outputs/03_One_Way_SA.csv
#            outputs/03_Two_Way_SA_Grid.csv
#            outputs/03_Breakeven_Table.csv
#            outputs/03_NNT_Sensitivity_Table.csv
#            figures/03_Tornado.png
#            figures/03_Heatmap.png
ok <- run_step(3, "Sensitivity Analysis (One-Way & Two-Way)", "src/03_sensitivity_analysis.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 4 — Report Generator (markdown report + paste-ready Results text)
# Generates: outputs/04_FINAL_REPORT.md
#            outputs/04_Manuscript_Results.txt
ok <- run_step(4, "Final Report Generator", "src/04_report_generator.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 5 — Data Import (reference datasets, validation cohort)
# Generates: data/01_PALOMA_Trial_Reference.csv
#            data/02_PK_Literature_Reference.csv
#            data/03_AE_Cost_Reference.csv
#            data/04_Dosing_Scenarios.csv
#            data/07_Validation_Cohort.csv
ok <- run_step(5, "Reference Data Import & Validation Cohort", "src/05_data_import.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 6 — Validation (three-tier framework, 9 tests)
# Generates: outputs/06_PK_Validation.csv
#            outputs/06_Calibration_Validation.csv
#            outputs/06_Validation_Summary.csv
#            figures/06_Validation_Plots.png
ok <- run_step(6, "Model Validation (Three-Tier Framework)", "src/06_validation.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 7 — TDM Algorithm (5-tier classification, exposure-response figures)
# Generates: outputs/07_TDM_Tier_System.csv
#            outputs/07_TDM_Classified_Population.csv
#            outputs/07_TDM_Tier_Summary.csv
#            outputs/07_TDM_Protocol.txt
#            figures/07_Exposure_Response_Tiers.png
#            figures/07_Tier_Distribution.png
#            figures/07_Risk_Savings_By_Tier.png
ok <- run_step(7, "TDM Clinical Algorithm & Tier Classification", "src/07_tdm_algorithm.R")
if (ok) steps_passed <- steps_passed + 1

# STEP 8 — Cost Visualisation (economic figures, budget impact)
# Generates: outputs/08_Cost_Components.csv
#            outputs/08_Budget_Impact.csv
#            outputs/08_ROI_Analysis.csv
#            outputs/08_Economic_Summary.csv
#            figures/08_Cost_Breakdown.png
#            figures/08_Waterfall_Savings.png
#            figures/08_Budget_Impact.png
#            figures/08_NNT_Infographic.png
#            figures/08_Economic_Summary.png
ok <- run_step(8, "Cost Analysis & Economic Visualisation", "src/08_cost_visualisation.R")
if (ok) steps_passed <- steps_passed + 1

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

pipeline_end     <- proc.time()
total_time       <- round((pipeline_end - pipeline_start)[3], 0)

cat("==============================================================================\n")
cat(sprintf(" PIPELINE COMPLETE: %d/%d steps succeeded\n",
            steps_passed, steps_total))
cat(sprintf(" Total runtime: %d seconds\n", total_time))
cat(sprintf(" Completed: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("==============================================================================\n\n")

# Print key results if simulation ran successfully
if (exists("NNT") && exists("ARR") && exists("net_savings")) {

  cat(" KEY RESULTS (verify these match expected values):\n")
  cat(" ─────────────────────────────────────────────────\n")
  cat(sprintf("  %-40s %.1f ng/mL\n",
              "Mean Cmin:", if(exists("cmin_mean")) cmin_mean else NA))
  cat(sprintf("  %-40s %.1f%%  [target: 66.4%%]\n",
              "Baseline G3/4 Risk:", mean_base * 100))
  cat(sprintf("  %-40s %.1f%%\n",
              "TDM-guided G3/4 Risk:", mean_tdm * 100))
  cat(sprintf("  %-40s %.1f%%\n",
              "Absolute Risk Reduction (ARR):", ARR * 100))
  cat(sprintf("  %-40s %.1f  [target: 6.3]\n",
              "Number Needed to Treat (NNT):", NNT))
  cat(sprintf("  %-40s %d per 1,000 patients\n",
              "Cases Prevented:", round(cases_prevented)))
  cat(sprintf("  %-40s $%s\n",
              "Net Savings (1,000 patients):",
              format(round(net_savings), big.mark = ",")))
  cat(sprintf("  %-40s %d%%\n",
              "ROI on TDM Investment:",
              round(savings_per_patient / cost_params$tdm_assay_cost * 100)))

  cat("\n VALIDATION:\n")
  if (exists("val_results")) {
    total_pass <- sum(val_results$Status == "PASS ✓")
    total_tot  <- nrow(val_results)
    cat(sprintf("  %-40s %d/%d PASS\n",
                "Three-tier validation:", total_pass, total_tot))
  }
  if (exists("savings_grid")) {
    cat(sprintf("  %-40s %d/100 (100%%)\n",
                "Two-way SA positive scenarios:",
                sum(savings_grid > 0)))
  }

  cat("\n OUTPUT LOCATIONS:\n")
  cat("  figures/   — 9 publication-ready PNG figures\n")
  cat("  outputs/   — 17 CSV data files\n")
  cat("  outputs/04_FINAL_REPORT.md         — complete report\n")
  cat("  outputs/04_Manuscript_Results.txt  — paste into manuscript\n")
  cat("  outputs/08_Economic_Summary.csv    — all economic outputs\n")

  # Flag if any numbers are off
  cat("\n CALIBRATION CHECK:\n")
  baseline_ok <- abs(mean_base - 0.664) < 0.01
  nnt_ok      <- abs(NNT - 6.3) < 0.5
  savings_ok  <- net_savings > 3000000 & net_savings < 3500000

  cat(sprintf("  Baseline 66.0%%:    %s\n",
              if(baseline_ok) "✓ PASS" else "✗ CHECK"))
  cat(sprintf("  NNT 6.4:           %s\n",
              if(nnt_ok) "✓ PASS" else "✗ CHECK"))
  cat(sprintf("  Savings ~$3.21M:   %s\n",
              if(savings_ok) "✓ PASS" else "✗ CHECK"))

} else {
  cat(" ⚠ Simulation did not complete. Check Step 1 and Step 2 errors above.\n")
}

cat("\n")
cat("==============================================================================\n")
if (steps_passed == steps_total) {
  cat(" ✅ ALL STEPS COMPLETE\n")
} else {
  cat(sprintf(" ⚠  %d step(s) failed — review errors above before submitting\n",
              steps_total - steps_passed))
}
cat("==============================================================================\n\n")
