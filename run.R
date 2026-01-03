# ==============================================================================
# MASTER EXECUTION SCRIPT
# ==============================================================================

# 1. Run Simulation (Generates the data)
message("\nSTEP 1: Running Simulation...")
source("src/02_simulation_engine.R")

# 2. Run Sensitivity (Optional)
if(file.exists("src/03_sensitivity_analysis.R")) {
  message("\nSTEP 2: Running Sensitivity Analysis...")
  source("src/03_sensitivity_analysis.R")
}

# 3. Generate ASHP Visualizations (The 6 Graphs)
message("\nSTEP 3: Generating ASHP Visualizations...")
if(file.exists("src/05_visualization_ashp.R")) {
  source("src/05_visualization_ashp.R")
} else {
  message("⚠️ Visualization script not found.")
}

# 4. Generate Report (Reads the data)
message("\nSTEP 4: Generating Final Report...")
source("src/04_main_report.R")

message("\n✅ ALL SYSTEMS GO! Simulation complete.")

# 5. Generate PDF Poster
message("\nSTEP 5: Generating PDF Poster...")
if(file.exists("src/06_generate_poster.R")) {
  source("src/06_generate_poster.R")
}
