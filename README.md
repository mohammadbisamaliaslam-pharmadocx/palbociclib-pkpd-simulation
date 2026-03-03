# Palbociclib Therapeutic Drug Monitoring: A PALOMA-2-Calibrated Scenario-Based Monte Carlo Simulation

**Author:** Mohammad Bisam Ali Aslam, PharmD Candidate
**Affiliation:** Akhtar Saeed College of Pharmacy (ASCP), Rawalpindi, Pakistan
**GitHub:** https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation
**License:** MIT | **Version:** 1.0 | **Date:** March 2, 2026

---

## Executive Summary

This repository contains a scenario-based Monte Carlo simulation demonstrating
the projected clinical and pharmacoeconomic impact of Therapeutic Drug
Monitoring (TDM)-guided dosing for palbociclib in HR+/HER2− metastatic breast
cancer. The simulation is calibrated to PALOMA-2 trial outcomes and built on
published population pharmacokinetic and pharmacodynamic parameters from three
independent peer-reviewed sources.

**Important:** This is a proof-of-concept simulation study. Results are
model-derived projections under stated assumptions, not clinical trial evidence.
See LIMITATIONS.md for full disclosure.

---

## Key Results (PALOMA-2 Calibrated)

| Outcome | Value |
|---------|-------|
| Baseline Grade 3/4 Neutropenia | 65.9% (PALOMA-2 observed: 66.4%) |
| TDM-Guided Neutropenia Risk | 50.2% |
| Absolute Risk Reduction | 15.8 percentage points |
| Number Needed to Treat (NNT) | 6.4 |
| Dose Reduction Rate | 36.4% (real-world range: 34–40%) |
| Net Cost Savings | $3.4M per 1,000 patients annually |

---

## Model Parameters

### Population Pharmacokinetics
Source: Royer et al. (2021)

| Parameter | Value | IIV (CV%) |
|-----------|-------|-----------|
| CL/F (apparent oral clearance) | 58.3 L/h | 31.3% |
| V/F (apparent volume) | 1,580 L | 40.0% |
| Ka (absorption rate constant) | 0.187 h⁻¹ | — |
| Tlag (lag time) | 0.5 h | — |
| F (oral bioavailability) | 46% | — |

### Exposure-Response (Pharmacodynamics)
Source: Courlet et al. (2022)

| Parameter | Value |
|-----------|-------|
| Emax | 0.22 (95% CI: 0.19–0.25) |
| EC50 | 40.1 ng/mL |
| Hill coefficient (γ) | 0.13 |
| Baseline risk | 0.659 (calibrated to PALOMA-2) |

### TDM Decision Rule
- **Threshold:** Cmin **above** 100 ng/mL → proactive dose reduction to 100 mg
- **Target range:** 40–100 ng/mL
- **Sampling:** Day 15 of Cycle 2 (steady-state trough)
- **Source:** Le Marouille et al. (2021); Leenhardt et al. (2022)

---

## Simulation Structure

This repository uses a **scenario-based Monte Carlo approach**. 1,000 virtual
patients are assigned to two exposure subgroups informed by the published
population PK distribution:

- **Group A (n=360, 36%):** High exposure, Cmin > 100 ng/mL
- **Group B (n=640, 64%):** Standard exposure, Cmin ≤ 100 ng/mL

Group-level neutropenia risk estimates are derived from the Hill equation
(Courlet 2022) at each group's mean Cmin. This differs from a fully mechanistic
individual-level simulation; see METHODS.md Section 9 for full explanation.
A mechanistic individual-level Version 2.0 is planned.

---

## Quick Start

Clone the repository and run the master script:

```r
source('run.R')
```

---

## Key Findings

### Clinical Impact
- **NNT = 6.4:** Treat 6–7 patients with TDM-guided dosing to prevent one
  case of Grade 3/4 neutropenia versus standard reactive management
- **158 cases prevented** per 1,000 patients annually
- **Convergent validity:** Leenhardt et al. (2022) reported NNT = 6.3 in
  a real-world TDM cohort — independent confirmation of the simulation result

### Economic Impact
- Hospitalisation cost per Grade 3/4 neutropenia event: $22,839
  (Tai et al. 2017, J Oncol Pract)
- TDM assay cost: $150 per patient per cycle
- Net savings: **$3.4M per 1,000 patients annually**
- ROI: $2.54 saved per $1 invested in TDM

### Sensitivity Analysis
NNT remains between 4.8 and 8.2 across all ±20% parameter variations,
confirming robustness of the primary clinical conclusion.

---

## Documentation

- **Full methodology:** See [METHODS.md](METHODS.md)
- **Limitations and transparency:** See [LIMITATIONS.md](LIMITATIONS.md)
- **Changelog:** See [NEWS.md](NEWS.md)

---

## Citation

If you use this repository, please cite:

> Aslam MBA, A Scenario-Based Monte Carlo Simulation Framework for
> Therapeutic Drug Monitoring-Guided Palbociclib Dosing: Methodology,
> Calibration to PALOMA-2, and Projected Clinical Outcomes.
> [Under review, 2026]
> Repository: https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation

---

## AI Tools Disclosure

This project used AI tools (Perplexity AI and Claude, Anthropic, 2025–2026)
for technical assistance with code documentation and visualisation elements.
All pharmacometric modelling decisions, parameter selection from the published
literature, simulation design, and scientific interpretation were conducted by
the primary author, who takes full responsibility for all methodological choices.

---

## Status

| Item | Status |
|------|--------|
| Simulation | ✅ Complete |
| PALOMA-2 Calibration | ✅ Confirmed (65.9% vs 66.4%) |
| Parameter Sources | ✅ Literature verified (Royer 2021, Courlet 2022) |
| Sensitivity Analysis | ✅ Complete |
| METHODS.md | ✅ Updated March 2, 2026 |
| LIMITATIONS.md | ✅ Updated March 2, 2026 |
| Manuscript | ✅ Under preparation for Pharmaceutics (MDPI) |
| Prospective Validation | ⏳ Planned — Version 2.0 |
