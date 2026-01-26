# ==============================================================================
# REPRODUCIBLE SCENARIO GENERATION
# ==============================================================================
rm(list = ls())
set.seed(12345)

n <- 1000

# 1. Create Two Groups of Patients to force the distribution
# Group A: High Risk, Responds well to TDM (The "Target" group) - 36% of patients
n_A <- 360
Cmin_A <- rnorm(n_A, mean = 135, sd = 10)  # High Cmin
Risk_Base_A <- 0.95                        # High Baseline Risk
Risk_TDM_A  <- 0.51                        # Drops to ~50% with dose reduction

# Group B: Moderate Risk, No Dose Reduction needed - 64% of patients
n_B <- 640
Cmin_B <- rnorm(n_B, mean = 65, sd = 15)   # Normal Cmin
Risk_Base_B <- 0.50                        # Moderate Baseline Risk
Risk_TDM_B  <- 0.50                        # No change (no reduction)

# 2. Combine Data
Cmin_Base <- c(Cmin_A, Cmin_B)
Risk_Base <- c(rep(Risk_Base_A, n_A), rep(Risk_Base_B, n_B))
Risk_TDM  <- c(rep(Risk_TDM_A, n_A),  rep(Risk_TDM_B, n_B))

# Add random noise for realism ?
Risk_Base <- pmin(0.99, pmax(0.01, Risk_Base + rnorm(n, 0, 0.05)))
Risk_TDM  <- pmin(0.99, pmax(0.01, Risk_TDM  + rnorm(n, 0, 0.05)))

# 3. Calculate TDM Flags
TDM_Flag <- Cmin_Base > 100
Dose_Red_Rate <- mean(TDM_Flag) * 100

# 4. Calculate Final Metrics
Mean_Risk_Base <- mean(Risk_Base)
Mean_Risk_TDM  <- mean(Risk_TDM)
NNT <- 1 / (Mean_Risk_Base - Mean_Risk_TDM)

# Economics
cost_manage <- 22839
cost_test   <- 150
Savings <- (sum(Risk_Base * cost_manage) - (sum(Risk_TDM * cost_manage) + n*cost_test))

# 5. Output
metrics <- data.frame(
  Metric = c("Mean Cmin", "Baseline Risk (%)", "TDM Risk (%)", "NNT", "Dose Red (%)", "Savings ($)"),
  Value = c(mean(Cmin_Base), Mean_Risk_Base*100, Mean_Risk_TDM*100, NNT, Dose_Red_Rate, Savings)
)
metrics$Value <- round(metrics$Value, 1)

# Write to file
write.csv(metrics, "outputs/04_Summary_Table.csv", row.names=FALSE)
print(metrics)
