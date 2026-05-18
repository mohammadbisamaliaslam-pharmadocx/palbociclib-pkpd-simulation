# Palbociclib TDM: A PALOMA-2-Calibrated Pharmacoeconomic Decision-Analytic Model

**Author:** Mohammad Bisam Ali Aslam, PharmD Candidate (Year 3)
**Affiliation:** Akhtar Saeed College of Pharmacy (ASCP), University of the Punjab, Rawalpindi, Pakistan
**Supervisor:** Dr. Zubair Anwar
**ORCID:** 0009-0001-2000-0417
**GitHub:** https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation
**License:** MIT | **Version:** 2.0 | **Date:** May 2026

---

> **This is a proof-of-concept pharmacoeconomic scenario model.**
> Results are model-derived projections under stated assumptions — not clinical
> trial evidence. See [LIMITATIONS.md](LIMITATIONS.md) for full disclosure.
> Version 2.0 corrects parameter errors and hardcoded sensitivity values
> present in v1.0. See [METHODS.md](METHODS.md) Section 8 for the complete
> change log.

---

## Executive Summary

This repository implements a **two-component scenario-based pharmacoeconomic
decision-analytic model** evaluating the clinical and economic impact of
Therapeutic Drug Monitoring (TDM)-guided palbociclib dosing in patients with
HR+/HER2− metastatic breast cancer.

The model is calibrated to PALOMA-2 trial outcomes (Finn et al. 2016
[PMID:27959613]) and built on literature-verified population pharmacokinetic
parameters (Royer et al. 2021 [PMID:33668400]) and pharmacodynamic parameters
(Courlet et al. 2022 [PMID:35890213]). The TDM intervention framework replicates
the 5-tier Cmin classification system of Leenhardt et al. 2022 [PMID:35397465].

All parameters trace to a single source of truth (`data/parameters.RData`).
All sensitivity values are computed analytically — nothing hardcoded.
Reproducibility: `set.seed(12345)`.

---

## Key Results (n = 1,000 virtual patients, seed = 12345)

| Outcome | Value | Reference |
|---------|-------|-----------|
| Mean Cmin (PK model) | 70.0 ng/mL | Published: 74.1 ng/mL (Leenhardt 2022) |
| Baseline G3/4 Neutropenia | **66.0%** | PALOMA-2 target: 66.4% ✓ |
| TDM-Guided G3/4 Risk | **50.4%** | Model |
| Absolute Risk Reduction (ARR) | **15.6%** | Model |
| Number Needed to Treat (NNT) | **6.4** | Leenhardt 2022 observed: 6.3 ✓ |
| Cases Prevented per 1,000 Patients | **156** | Model |
| Dose Reduction Rate | **36.4%** | PALOMA-2: 36.4% ✓ |
| Gross AE Savings (1,000 patients) | **$3,563,045** | Dulisse & Cosler 2012 |
| TDM Programme Cost (1,000 patients) | **$350,000** | $350/patient, LC-MS/MS |
| **Net Savings (1,000 patients)** | **$3,213,045** | Primary outcome |
| Savings per Patient | **$3,213** | Model |
| ROI on TDM Investment | **918%** | Model |
| Break-even ARR | **1.5%** | Two-way SA |
| Two-way SA positive scenarios | **100/100** | 10×10 grid |
| Validation tests passed | **9/9** | Three-tier framework |

---

## Model Architecture

### Component 1 — PK Distribution (Mechanistic)

Individual patient Cmin values are computed per-patient using a one-compartment
oral pharmacokinetic model at steady state:

```
Cmin_ss = (D/V_i) × [Ka/(Ka − ke_i)] ×
          [e^(−ke_i×τ)/(1−e^(−ke_i×τ)) − e^(−Ka×τ)/(1−e^(−Ka×τ))]
```

Individual CL/F and V/F are sampled from log-normal distributions using
published IIV parameters (Royer et al. 2021). This produces a population
Cmin distribution with mean 70 ng/mL, consistent with the published clinical
median of 74.1 ng/mL (Leenhardt 2022 [PMID:35456675]).

### Component 2 — Scenario Risk Assignment (Calibrated)

Group-level G3/4 risks are assigned by scenario — not computed mechanistically
from the Emax model. This is the correct approach because the Courlet 2022
Emax model (gamma = 0.13) produces <1% variation in P(G3/4) across the
entire clinical Cmin range of 40–150 ng/mL, precluding mechanistic
risk discrimination. See METHODS.md Section 2.3 for the flat-curve
documentation table.

The 36.4% intervention rate is calibrated to the observed dose modification
rate from pooled PALOMA-1/2/3 (Loibl et al. 2020 [PMC7068918]).

---

## Population PK Parameters

Source: Royer et al. 2021, *Pharmaceuticals* 14(3):181 [PMID:33668400]
Real-world TDM study, n = 124 patients, 151 samples, 500-replicate bootstrap.

| Parameter | Value | IIV (CV%) | PMID |
|-----------|-------|-----------|------|
| CL/F (apparent oral clearance) | 58.3 L/h | 31.3% | 33668400 |
| V/F (apparent volume) | 1,580 L | 40.0% | 33668400 |
| Ka (absorption rate constant) | 0.187 h⁻¹ | — | 33668400 |
| F (oral bioavailability) | 0.46 | — | FDA label |

Cross-source validation: CL/F = 58.3 L/h is within the published adult range
of 58.0–67.0 L/h across five independent sources (MAPE = 6.8%; threshold <20%).

---

## Pharmacodynamic Parameters

Source: Courlet et al. 2022, *Pharmaceutics* 14(7):1317 [PMID:35890213]

Emax model: `P(G3/4) = E0 + Emax × [Cmin^γ / (EC50^γ + Cmin^γ)]`

| Parameter | Value | Notes | PMID |
|-----------|-------|-------|------|
| E0 (baseline risk) | 0.66 | Calibrated to PALOMA-2 | 27959613 |
| Emax | 0.22 (95% CI: 0.19–0.25) | Max additional increment | 35890213 |
| EC50 | 40.1 ng/mL | Fixed from literature | 35890213 |
| γ (Hill coefficient) | 0.13 | Near-flat curve | 35890213 |

All PD outputs verified on valid probability scale (0–1).
Maximum possible P(G3/4) = E0 + Emax = 0.88 (88%). ✓

---

## TDM Algorithm — 5-Tier Classification

Source: Leenhardt et al. 2022 [PMID:35397465]

| Tier | Cmin Range | Label | Recommendation | G3/4 Risk |
|------|-----------|-------|---------------|-----------|
| 1 | <40 ng/mL | Sub-therapeutic | Evaluate adherence | 22% |
| 2 | 40–70 ng/mL | Low-therapeutic | Continue 125 mg | 38% |
| 3 | 70–100 ng/mL | **Optimal ★** | Continue 125 mg | 50% |
| 4 | 100–150 ng/mL | High-therapeutic | **Reduce to 100 mg** | 66% |
| 5 | >150 ng/mL | Supratherapeutic | **Reduce/hold; check DDIs** | 78% |

**Sampling:** Cycle 2, Day 15 (steady-state trough, pre-dose)
**Assay:** LC-MS/MS validated (LOQ ≤ 1 ng/mL); cost $350/sample

---

## Cost Model

**Hospitalization cost:** $22,839 per Grade 3/4 event
Source: Dulisse & Cosler 2012 [PMC3440789] — correctly attributed in v2.0.
Applied as a **probability-weighted composite expected value** per patient
(= P(G3/4) × $22,839), representing the management burden of Grade 3/4
neutropenia inclusive of outpatient and inpatient components.

Note: Palbociclib-induced G3/4 neutropenia is predominantly afebrile
(<2% febrile NP across PALOMA trials). The composite cost approach
explicitly acknowledges this heterogeneity.

**Sensitivity range:** $11,337 (Kuderer 2015 ASH, breast-specific) to
$35,899 (Flanigan et al. 2024 [PMID:38777864], most recent real-world).

---

## Repository Structure

```
palbociclib-pkpd-simulation/
├── src/
│   ├── 01_model_setup.R           # Single source of truth — all parameters
│   ├── 02_simulation_engine.R     # Monte Carlo; PK distribution; scenario risks
│   ├── 03_sensitivity_analysis.R  # One-way (tornado) + two-way (heatmap)
│   ├── 04_report_generator.R      # Markdown report; paste-ready Results text
│   ├── 05_data_import.R           # PALOMA reference; PK literature; AE costs
│   ├── 06_validation.R            # Three-tier validation framework; figures
│   ├── 07_tdm_algorithm.R         # 5-tier classifier; exposure-response figures
│   ├── 08_cost_visualisation.R    # Cost breakdown; waterfall; NNT infographic
├── data/
│   └── parameters.RData           # Single source of truth (auto-generated)
├── outputs/                       # CSV results (auto-generated)
├── figures/                       # Publication-ready figures (auto-generated)
├── DESCRIPTION                    # R package metadata
├── METHODS.md                     # Full methodology documentation
├── LIMITATIONS.md                 # Transparency and limitations statement
└── README.md                      # This file
```

---

## Quick Start

```r
# Run all scripts in sequence
source("src/01_model_setup.R")
source("src/02_simulation_engine.R")
source("src/03_sensitivity_analysis.R")
source("src/04_report_generator.R")
source("src/05_data_import.R")
source("src/06_validation.R")
source("src/07_tdm_algorithm.R")
source("src/08_cost_visualisation.R")
```

**Requirements:** Base R ≥ 4.0.0. No tidyverse required for core scripts.

---

## Three-Tier Validation (9/9 PASS)

| Tier | Test | Result |
|------|------|--------|
| Tier 1 — PK | Mean Cmin vs Leenhardt 2022 | PASS (70.0 vs 74.1 ng/mL) |
| Tier 1 — PK | IQR width consistency | PASS |
| Tier 1 — PK | CV% range | PASS |
| Tier 1 — PK | Median Cmin | PASS |
| Tier 2 — Calibration | Baseline G3/4 (target 66.4%) | PASS (66.0%) |
| Tier 2 — Calibration | NNT (target 6.3) | PASS (6.4) |
| Tier 2 — Calibration | Dose modification rate (target 36.4%) | PASS (36.4%) |
| Tier 2 — Calibration | ARR | PASS (derived) |
| Tier 3 — Cross-source | CL/F MAPE across 5 sources (<20%) | PASS (6.8%) |

---

## Conference Presentations

| Conference | Status | Abstract |
|-----------|--------|---------|
| ASHP Midyear Clinical Meeting 2026 | Pending | Palbociclib TDM, NNT=6.4, ARR=15.6% |
| ACoP Annual Meeting 2026, Maryland | Pending | Proposal ID: 2354016 |
| CETPS 2026 | ✅ Accepted | 1ST Position |
| NIHC 2026, NUST | ✅ Accepted | Domestic poster |

---

## Sensitivity Analysis Summary

**One-way SA (6 parameters, computed):**

| Parameter | Low | Base | High |
|-----------|-----|------|------|
| Hospitalization cost | $0.9M | $3.21M | $5.5M |
| ARR magnitude | $1.3M | $3.21M | $5.6M |
| TDM assay cost | $3.4M | $3.21M | $3.1M |

**Two-way SA (10×10 grid = 100 scenarios):**
- Variables: Hospitalization cost ($11,337–$35,899) × ARR (8%–24%)
- Break-even ARR = **1.5%** at base hospitalization cost ($22,839)
- Positive savings: **100% of 100 scenarios**

---

## Primary Citations

| Reference | Role in Model | PMID |
|-----------|--------------|------|
| Royer et al. *Pharmaceuticals* 2021 | PK parameters | 33668400 |
| Courlet et al. *Pharmaceutics* 2022 | PD parameters (Emax) | 35890213 |
| Leenhardt et al. *Pharmaceutics* 2022 | Cmin validation cohort | 35456675 |
| Leenhardt et al. *Ther Drug Monit* 2022 | TDM thresholds; NNT=6.3 | 35397465 |
| Finn et al. *NEJM* 2016 (PALOMA-2) | Baseline calibration target | 27959613 |
| Loibl et al. *Breast Cancer Res Treat* 2020 | Dose modification rate | PMC7068918 |
| Dulisse & Cosler *J Oncol Pract* 2012 | Hospitalization cost | PMC3440789 |
| Flanigan et al. *Support Care Cancer* 2024 | SA upper cost bound | 38777864 |

---

## Citation

If you use this repository, please cite:

> Aslam MBA. Palbociclib Therapeutic Drug Monitoring: A PALOMA-2-Calibrated
> Pharmacoeconomic Decision-Analytic Model with Three-Tier Validation.
> [Under preparation for peer-reviewed submission, 2026]
> Repository: https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation
> Version: 2.0 | DOI: [pending]

---

## AI Tools Disclosure

Claude (Anthropic, Sonnet 4, 2025–2026) was used for code review, parameter
verification, documentation, and sensitivity analysis design. Perplexity AI
and Grammarly were used for reference verification and grammar checking.
All pharmacometric decisions, parameter selection, model design, and scientific
interpretation are the sole responsibility of the primary author.

---

## Status

| Item | v1.0 | v2.0 |
|------|------|------|
| PK parameters | ✅ | ✅ Verified + corrected |
| PD parameters | ❌ Non-probability values | ✅ Corrected (E0=0.66, Emax=0.22) |
| Simulation engine | ❌ Ignored PK params | ✅ PK-derived Cmin |
| Sensitivity analysis | ❌ Hardcoded | ✅ Computed analytically |
| Hospitalization citation | ❌ Tai 2017 (wrong) | ✅ Dulisse & Cosler 2012 |
| Parameter consistency | ❌ 5 files disagreed | ✅ Single source: parameters.RData |
| Validation framework | ❌ Synthetic n=100 | ✅ Three-tier, 9/9 PASS |
| METHODS.md | ✅ | ✅ Fully updated |
| LIMITATIONS.md | ✅ | ✅ Fully updated |
| Manuscript target | Pharmaceutics (MDPI) | JOPP / PharmacoEconomics Open |
| Prospective validation | ⏳ Planned | ⏳ Planned (n=60–80 per arm) |
