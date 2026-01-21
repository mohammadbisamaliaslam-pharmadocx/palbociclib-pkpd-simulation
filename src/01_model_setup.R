# CALIBRATED PARAMETERs
pk_params <- list(
  CL_pop = 31.0,    # Lower CL -> Higher Exposure -> Higher Risk
  V_pop  = 2500,
  omega_CL = 0.45,
  omega_V  = 0.40
)

pd_params <- list(
  E0      = 5.0,
  Emax    = 4.9,
  EC50    = 32.0,   # Lower EC50 -> Higher Sensitivity -> Matches 66% Risk
  Gamma   = 1.2,
  Prob_G34_Base = 0.66
)

sim_settings <- list(
  n_patients = 1000,
  dose_mg    = 125,
  tdm_threshold = 100.0,
  cycle_days = 28,
  n_cycles   = 3
)

cost_params <- list(
  drug_cost_monthly = 13000,
  g34_manage_cost   = 22839,
  tdm_test_cost     = 150
)

assign('pk_params', pk_params, envir = .GlobalEnv)
assign('pd_params', pd_params, envir = .GlobalEnv)
assign('sim_settings', sim_settings, envir = .GlobalEnv)
assign('cost_params', cost_params, envir = .GlobalEnv)
