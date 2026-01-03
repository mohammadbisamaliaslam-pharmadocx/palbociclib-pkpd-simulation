getwd()
source("run.R")
#!/usr/bin/env Rscript

# Set working directory explicitly
setwd("/Users/mohammadbisam/Documents/GitHub/palbociclib-pkpd-simulation")

# Run all scripts in order
source("src/01_model_setup.R")
source("src/02_simulation_engine.R")
source("src/03_sensitivity_analysis.R")
source("src/04_main_report.R")

cat("\n✅ SIMULATION COMPLETE!\n")
