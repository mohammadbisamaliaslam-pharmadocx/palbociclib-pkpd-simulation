# ==========================================
# MASTER EXECUTION SCRIPT
# ==========================================

# 1. Set Working Directory (Safety Check)
# setwd("/Users/mohammadbisam/Documents/GitHub/palbociclib-pkpd-simulation")

# 2. Load Parameters & Setup
if(file.exists("src/01_model_setup.R")) {
  message("STEP 1: Loading Parameters...")
  source("src/01_model_setup.R")
} else {
  stop("CRITICAL ERROR: src/01_model_setup.R not found!")
}

# 3. Run Simulation Engine
if(file.exists("src/02_simulation_engine.R")) {
  message("STEP 2: Running Simulation...")
  source("src/02_simulation_engine.R")
}

# 4. Run Sensitivity Analysis
if(file.exists("src/03_sensitivity_analysis.R")) {
  message("STEP 3: Running Sensitivity Analysis...")
  source("src/03_sensitivity_analysis.R")
}

# 5. Generate Final Report
if(file.exists("src/04_main_report.R")) {
  message("STEP 4: Generating Report...")
  source("src/04_main_report.R")
}

message("✅ DONE! All scripts executed.")
