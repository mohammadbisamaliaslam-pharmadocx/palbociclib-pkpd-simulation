# ==============================================================================
# MASTER EXECUTION SCRIPT
# ==============================================================================

# 1. Run Simulation (Generates the data)
message("\nSTEP 1: Running Simulation...")
source("src/02_simulation_engine.R")

# 2. Run Sensitivity (Optional/Stubbed)
if(file.exists("src/03_sensitivity_analysis.R")) {
  message("\nSTEP 2: Running Sensitivity Analysis...")
  source("src/03_sensitivity_analysis.R")
}

# 3. Generate Report (Reads the data)
message("\nSTEP 3: Generating Final Report...")
source("src/04_main_report.R")

message("\n✅ ALL SYSTEMS GO! Simulation complete.")
