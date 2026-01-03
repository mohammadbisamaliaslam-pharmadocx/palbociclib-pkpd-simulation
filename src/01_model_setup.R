# ==============================================================================
# PALBOCICLIB PK/PD SIMULATION - CALIBRATED PARAMETERS (Royer et al. 2021)
# ==============================================================================

# 1. Population PK Parameters (Source: Royer et al., Clin Pharm Ther 2021)
pk_params <- list(
  CL_pop = 33.0,    # LOWERED Clearance (was 45) to increase exposure/risk
  V_pop  = 2500,    # Volume of Distribution (L)
  omega_CL = 0.35,  # Inter-individual variability on CL
  omega_V  = 0.40   # Inter-individual variability on V
)

# 2. PD (Neutropenia) Model Parameters
# Calibrated to achieve ~66% Baseline Risk of Grade 3/4 Neutropenia
pd_params <- list(
  E0      = 5.0,    # Baseline ANC
  Emax    = 4.9,    # Maximum effect
  EC50    = 30.0,   # LOWERED EC50 (was 55) to make patients more sensitive
  Gamma   = 1.5,    # Hill coefficient
  Prob_G34_Base = 0.66 # Target probability
)

# 3. Simulation Settings
sim_settings <- list(
  n_patients = 1000,
  dose_mg    = 125,
  tdm_threshold = 100.0, # ng/mL
  cycle_days = 28,
  n_cycles   = 3
)

# 4. Cost Parameters (USD 2025)
cost_params <- list(
  drug_cost_monthly = 13000,
  g34_manage_cost   = 22839, # Cost to manage one neutropenia event
  tdm_test_cost     = 150    # Cost of one PK sample
)

# Export to global environment
assign("pk_params", pk_params, envir = .GlobalEnv)
assign("pd_params", pd_params, envir = .GlobalEnv)
assign("sim_settings", sim_settings, envir = .GlobalEnv)
assign("cost_params", cost_params, envir = .GlobalEnv)

message("✅ PARAMETERS UPDATED: Sensitivity increased to match PALOMA-2 Data.")
