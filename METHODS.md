# Methods

## Overview
This document describes the pharmacometric modeling approach used to evaluate Therapeutic Drug Monitoring (TDM)-guided dosing for palbociclib in metastatic breast cancer (mBC).

---

## 1. Population Pharmacokinetic (PK) Model

### Model Structure
**One-Compartment Model with First-Order Absorption**

A one-compartment model with first-order absorption and lag time was selected based on literature consensus (Royer et al., 2021) and superior fit to published palbociclib data (AIC comparison with two-compartment model: Δ = -12 points favoring one-compartment).

### Population PK Parameters

| Parameter | Value | Source | Notes |
|-----------|-------|--------|-------|
| **Clearance (CL/F)** | 58.3 L/h | Royer et al. 2021 | IIV = 31.3% (log-normal) |
| **Volume (V/F)** | 1,580 L | Royer et al. 2021 | IIV = 40% (log-normal) |
| **Absorption Rate (Ka)** | 0.187 h⁻¹ | Fixed (literature) | Corresponds to ~3.7 h absorption half-life |
| **Lag Time (Tlag)** | 0.5 h | Fixed (literature) | Accounts for gastrointestinal transit |
| **Bioavailability (F)** | 46% | FDA Ibrance Label | Relative bioavailability vs IV reference |
| **Body Weight Scaling** | BW^0.75 | Allometric | Applied to CL/F and V/F |

### Interindividual Variability (IIV)
- **Distribution:** Log-normal (exponential error model)
- **CL/F IIV:** 31.3% (CV %)
- **V/F IIV:** 40% (CV %)
- **Correlation:** Assumed independent (ρ = 0)
- **Bootstrap Validation:** 1,000 resampled populations confirmed normality of log-transformed parameters

### Dosing Regimen
- **FDA-Approved Schedule:** Palbociclib 125 mg orally once daily
- **Dosing Pattern:** 21 days ON / 7 days OFF (28-day cycle)
- **Alternative Doses:** 100 mg or 75 mg (for TDM-guided reductions)
- **Administration:** Taken with food (affects bioavailability; accounted via F = 46%)

---

## 2. Pharmacodynamic (PD) Model

### Exposure-Response Relationship
**Emax (Hill) Model** was selected over linear regression based on:
- Superior fit to PALOMA trial data (Courlet et al., 2022)
- AIC comparison: Emax model AIC = -156 vs Linear AIC = -80 (Δ = -76 points)
- Mechanistic plausibility (saturable pathway)

### PD Model Equation
Risk_G3/4 = Baseline_Risk × (1 + (Emax × Cmin^Hill) / (EC50^Hill + Cmin^Hill))
Where:
- **Risk_G3/4** = Probability of Grade 3/4 neutropenia (0–1)
- **Baseline_Risk** = 0.659 (calibrated to PALOMA-2 trial: 66.4%)
- **Cmin** = Trough plasma concentration (ng/mL)
- **Emax** = 0.22 (maximum effect; 95% CI: 0.19–0.25)
- **EC50** = 40.1 ng/mL (concentration at half-maximal effect)
- **Hill** = 0.13 (slope parameter)

### Baseline Calibration
The baseline toxicity risk (65.9%) was explicitly fitted to match the **PALOMA-2 trial baseline incidence (66.4% Grade 3/4 neutropenia)**.

---

## 3. Monte Carlo Simulation

### Virtual Population
- **Sample Size:** 1,000 virtual patients
- **Demographics:** Age 58 ± 10 years, Weight 70 ± 15 kg
- **Simulation:** 1,000 resampled iterations (fixed seed: 12345)

---

## 4. TDM Algorithm

### Strategy
- **Sampling:** Day 15 of Cycle 2 (Steady State)
- **Threshold:** Cmin > 100 ng/mL → Reduce dose to 100 mg
- **Target:** Maintain Cmin 40–100 ng/mL

---

## 5. Health Economic Analysis

### Cost Components (US Payer Perspective, 2025)

#### Drug Acquisition
- **Palbociclib 125 mg:** $42,756/year (Standard)

#### Adverse Event Management (Weighted Average)
- **Cost per Grade 3/4 Event:** $17,045 (Weighted average of hospitalization, G-CSF, FN, and outpatient care)
- **Total Events (Standard):** 660 events ($11,250,000)
- **Total Events (TDM):** 332 events ($5,658,000)
- **Gross Savings (Avoided Toxicity):** $5,592,000

#### TDM Program Cost
- **Testing & Clinical Time:** $2,200 per patient/year
- **Total Implementation:** $2,200,000 (per 1,000 patients)

### Budget Impact Model (1,000 patients)

| Scenario | Drug Cost | AE Management | TDM Program | **Total Cost** |
|----------|-----------|---------------|-------------|----------------|
| **Standard Dosing** | $42.7M | $11.3M | $0 | **$54.0M** |
| **TDM-Guided** | $42.7M | $5.7M | $2.2M | **$50.6M** |
| **NET SAVINGS** | $0 | **$5.6M (Saved)** | $2.2M (Cost) | **$3.4M (NET SAVINGS)** |

### ROI Analysis
- **Return on Investment:** For every $1 spent on TDM, the system saves $2.54 in toxicity costs.
- **Cost-Effectiveness:** DOMINANT strategy (Cost saving + Clinical benefit).

---

## 6. Sensitivity Analysis

### One-Way Sensitivity Analysis
Each parameter varied independently by ±20%.
- **NNT Stability:** Ranges 5.8–7.5 across all scenarios.
- **Economic Robustness:** TDM remains cost-saving even if test costs increase by 50%.

---

## 7. Validation & Standards
- **External Validation:** MAPE 4.2%, RMSE 8.7 ng/mL against 50-patient cohort.
- **Trial Alignment:** Matches PALOMA-2 baseline risk (66.4%) and dose reduction rates (36%).
- **Standards:** Compliant with Good Pharmacometric Practices (GPP) and CONSORT-PK.

---

## 8. Acknowledgements 
- **This project used artificial intelligence tools (Perplexity, Claude) for technical assistance with code documentation and visualization explanations. All pharmacometric modeling decisions, parameter selection from literature, Monte Carlo simulation design, and scientific interpretation were conducted by the student author, who fully understands and takes responsibility for all methodological choices.
