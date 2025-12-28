library(rxode2)
library(tidyverse)
library(data.table)

pk_params <- list(CL = 63, V = 2710, CL_iiv = 0.35, V_iiv = 0.40, ka = 0.5, F = 0.68)
dose_params <- list(dose_standard = 125, dose_reduced = 100, cycle_length = 28, dosing_days = 21, rest_days = 7)
tdm_params <- list(tdm_sampling_day = 15, tdm_threshold = 100)
pd_params <- list(baseline_neutropenia_risk = 0.66, E0 = 0.10, Emax = 0.90, EC50 = 85, gamma = 1.5)
cost_params <- list(hospitalization_cost = 22839, tdm_assay_cost = 350, tdm_frequency = 1)
population_params <- list(n_patients = 1000, age_mean = 62, age_sd = 8, weight_mean = 72, weight_sd = 12)
simulation_params <- list(n_cycles = 4, sample_times = c(0, 1, 2, 4, 8, 12, 24, 36, 48), set_seed = 12345)
analysis_params <- list(n_monte_carlo = 10000, param_uncertainty = 0.30)
expected_results <- list(baseline_neutropenia_risk = 0.224, tdm_neutropenia_risk = 0.183, baseline_total_cost = 5104000, tdm_total_cost = 4145000, annual_savings = 586000)

all_params <- list(pk = pk_params, dose = dose_params, tdm = tdm_params, pd = pd_params, cost = cost_params, population = population_params, simulation = simulation_params, analysis = analysis_params, expected = expected_results)

saveRDS(all_params, "data/parameters.rds")

cat("\nPALBOCICLIB TDM SIMULATION - PARAMETERS LOADED\n")

