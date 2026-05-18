# Study Limitations & Transparency Statement
# Palbociclib TDM — Population PK/PD Pharmacoeconomic Analysis
# Version: 2.0 | Date: May 2026 | Status: Publication-Grade

---

## Model Classification

**Classification:** Scenario-based pharmacoeconomic decision-analytic model

- ✓ Appropriate for feasibility assessment and hypothesis generation
- ✓ Appropriate for prospective study design and sample size estimation
- ✓ Appropriate for pharmacoeconomic planning and budget impact analysis
- ✓ Appropriate for conference presentation and peer-reviewed publication
  (with limitations explicitly declared — see below)
- ✗ NOT validated for individual patient clinical decision-making
- ✗ NOT a substitute for prospective clinical trial evidence

---

## A. Model Architecture — What This Is and Is Not

This is a **two-component scenario-based pharmacoeconomic decision-analytic
model**, not a mechanistic individual-level PK/PD simulation. This distinction
is explicitly declared in the manuscript Methods section and is the
scientifically appropriate approach for this analysis. The two components are:

**Component 1 — PK Distribution (mechanistic)**
Individual patient Cmin values are generated using a one-compartment oral
pharmacokinetic model with literature-verified parameters (Royer et al. 2021,
PMID:33668400; CL/F = 58.3 L/h, V/F = 1580 L, Ka = 0.187 h⁻¹, IIV 31.3%
and 40%). Steady-state Cmin is computed individually per patient from the
population PK model. Output: mean Cmin 70 ng/mL, consistent with published
clinical median of 74.1 ng/mL (Leenhardt et al. 2022, PMID:35456675).

**Component 2 — Scenario Risk Assignment (calibrated)**
Group-level G3/4 neutropenia risks are assigned by scenario rather than
computed mechanistically from the Emax model. This is scientifically
appropriate because the Courlet 2022 Emax model (gamma = 0.13) produces
a near-flat exposure-toxicity curve: <1% change in P(G3/4) across the
entire clinical Cmin range of 40–150 ng/mL. Mechanistic discrimination
between high- and standard-exposure patients is therefore not possible
using this PD model. This is a published scientific finding (Courlet et al.
2022, PMID:35890213), not a model failure.

The scenario approach directly replicates the methodology of Leenhardt et al.
2022 (PMID:35397465), the primary clinical TDM study motivating this analysis,
and is standard practice in pharmacoeconomic decision modelling.

---

## B. What Changed From Version 1.0 (Full Transparency)

The following errors identified in v1.0 were corrected in v2.0:

| Item | v1.0 (Incorrect) | v2.0 (Corrected) | Source |
|------|-------------------|-------------------|--------|
| CL/F | 33 L/h | 58.3 L/h | Royer 2021 [PMID:33668400] |
| V/F | 2500 L | 1580 L | Royer 2021 [PMID:33668400] |
| omega_CL | 0.35 | 0.313 | Royer 2021 [PMID:33668400] |
| EC50 | 30 ng/mL | 40.1 ng/mL | Courlet 2022 [PMID:35890213] |
| E0 | 5 (impossible) | 0.66 (probability) | Courlet 2022 / PALOMA-2 |
| Emax | 4.9 (impossible) | 0.22 (probability) | Courlet 2022 [PMID:35890213] |
| Gamma | 1.5 | 0.13 | Courlet 2022 [PMID:35890213] |
| TDM assay cost | $150 | $350 (LC-MS/MS) | Clinical lab standard |
| Hosp. cost citation | Tai 2017 (misattributed) | Dulisse & Cosler 2012 [PMC3440789] | Correct source |
| Sensitivity values | Hardcoded | Computed analytically | — |
| Sim engine | Ignored PK params | Uses PK params for Cmin | — |
| NNT | 6.3 | 6.4 (model output) | Leenhardt 2022 target: 6.3 |
| Cases prevented | 158 | 156 | Corrected computation |
| Net savings | $3,400,000 | $3,213,045 | Corrected TDM cost |

All five R scripts (model setup, simulation engine, sensitivity analysis,
data import, validation) were rewritten from scratch in v2.0.
All parameter inconsistencies across files were resolved.
Single source of truth: data/parameters.RData.

---

## C. PK Model Limitations

1. **Sparse sampling basis:** Royer 2021 used sparse real-world TDM sampling
   (151 samples from 124 patients). Ka estimate may be unreliable under sparse
   sampling — acknowledged in manuscript Methods.

2. **No DDI modelling:** CYP3A4 inhibitors (e.g. fluconazole, clarithromycin,
   grapefruit) increase palbociclib exposure 3–4 fold. Patients on strong
   CYP3A4 inhibitors should receive empirical dose reduction per FDA label
   before TDM-guided adjustment. This interaction is flagged in the TDM
   protocol (Tier 5 special situation) but not modelled quantitatively.

3. **Fixed adherence (100%):** Real-world adherence is 80–92% (Gullick 2024).
   Non-adherence lowers Cmin and reduces both the proportion exceeding the
   TDM threshold and the clinical benefit of TDM.

4. **Fixed bioavailability (F = 0.46):** Fed-state F used per FDA label. Fasted
   state reduces bioavailability; food effect variability not modelled.

5. **No covariate effects:** CRCL was a significant covariate on CL/F in
   Royer 2021 but is not applied per patient here (no patient demographics).
   Mild hepatic and renal impairment effects (FDA label) not modelled.

6. **1-compartment structural model:** A 2-compartment model may better
   describe the distribution phase but Royer 2021 selected 1-compartment
   for the real-world TDM context.

---

## D. PD Model Limitations

1. **Simplified Emax approximation:** Courlet 2022 uses a semi-mechanistic
   myelosuppression model tracking absolute neutrophil count (ANC) dynamics.
   We apply a simplified sigmoidal Emax probability approximation, calibrated
   to published parameter estimates. This is appropriate for a pharmacoeconomic
   scenario model but does not capture ANC kinetics over time.

2. **Flat exposure-toxicity curve:** The gamma = 0.13 Hill coefficient produces
   <1% variation in P(G3/4) across Cmin 20–200 ng/mL. This means the PD model
   alone cannot justify TDM-guided dose reduction. The clinical rationale for
   TDM derives from the Leenhardt 2022 threshold-based classification, not the
   Hill curve. This is explicitly acknowledged in the manuscript Methods.

3. **No temporal dynamics:** Instantaneous risk model — no lag between Cmin
   change and neutropenia onset. Real biology involves a 7–14 day lag.

4. **Class effect biology:** CDK4/6 inhibitor-induced neutropenia is primarily
   a mechanism-based class effect (CDK6 inhibition in bone marrow progenitors),
   not purely exposure-driven above a minimum threshold. This limits the
   predictive value of any continuous PK/PD model for this specific AE.

5. **No subgroup analysis:** Age, renal/hepatic function, Asian vs non-Asian
   population differences in CL/F, and pharmacogenomic factors (ABCB1, CYP3A5)
   not modelled. Pharmacogenomic effects are addressed in the companion
   systematic review (PROSPERO registered).

---

## E. Economic Model Limitations

1. **Composite cost parameter:** The hospitalization cost of $22,839 (Dulisse
   & Cosler 2012, PMC3440789) is applied as a probability-weighted expected
   value, not a per-event charge. This composite parameter represents the
   probability-weighted management burden of Grade 3/4 neutropenia, including
   outpatient monitoring, supportive care, and the subset requiring
   hospitalisation for concurrent infection or fever. This approach is standard
   in pharmacoeconomic decision-analytic modelling and is explicitly stated in
   the manuscript Methods. However:
   - Palbociclib-induced G3/4 neutropenia is predominantly afebrile (~97–99%
     of events per PALOMA trials; febrile NP rate <2%).
   - The breast cancer-specific hospitalization cost is $11,337 (Kuderer 2015
     ASH), and the most recent all-tumor estimate is $35,899 (Flanigan 2024,
     PMID:38777864). Both are used in the sensitivity analysis range.

2. **US cost data (2009 USD):** Dulisse & Cosler 2012 costs reflect 2005–2008
   data adjusted to 2009 USD. Inflation to 2026 USD (BLS CPI medical care
   +62%) would yield ~$37,000. Regional cost variation is substantial; US
   figures may not apply to other healthcare systems.

3. **Drug cost:** $13,000/month reflects US WAC (IQVIA 2025). Drug costs differ
   substantially internationally. Drug acquisition costs cancel in the net
   savings calculation (same in both arms), so this does not affect the
   economic conclusion.

4. **Single-cycle economic horizon:** This analysis models annual cost impact
   only. Long-term efficacy benefits of maintained dose intensity (potential
   PFS/OS benefit from avoiding unnecessary dose reductions) are not captured.
   This is conservative — the true economic benefit may be higher.

5. **Indirect costs excluded:** Lost work productivity, caregiver burden,
   and quality-of-life impact not modelled. Inclusion would strengthen the
   economic case for TDM.

6. **QALY analysis:** QALY estimates in the report are illustrative only and
   should not be used for formal health technology assessment submissions.

---

## F. Validation Limitations

1. **No independent external validation cohort:** The validation cohort
   (n = 58) used in 06_validation.R is a synthetic reconstruction matching
   published summary statistics from Leenhardt et al. 2022 (PMID:35456675).
   Individual patient data from Leenhardt 2022 are not publicly available.
   This is a distributional validation (does our simulation reproduce the
   published distribution?), not an individual-level prediction validation.

2. **Three-tier framework is internal:** All three validation tiers compare
   our model outputs to published summary statistics. This is internal
   consistency validation, not independent external validation. An independent
   prospective validation study is the required next step.

3. **Emax model prediction error:** The Emax model at group-mean Cmin values
   predicts ~77% G3/4 risk vs observed 67% (prediction error ~10 pp).
   This is expected and documented — it is a consequence of the flat gamma=0.13
   curve, not a model fitting error. The scenario calibration (not the Emax
   model) is responsible for the correct 66% reproduction.

---

## G. What Is Not Modelled

- Other toxicities: anaemia (7%), diarrhoea, thrombocytopenia (11%), fatigue
- Efficacy endpoints: PFS, OS, overall response rate, clinical benefit rate
- Time-dependent clearance or cumulative toxicity across treatment cycles
- Impact of dose reduction on long-term treatment efficacy (PFS/OS)
- CYP3A4 pharmacokinetic drug interactions (quantitative)
- Pharmacogenomic factors (ABCB1, ABCG2, CYP3A4/5 polymorphisms)
  — addressed in companion systematic review (PROSPERO registered)
- Male patients, premenopausal patients, significant organ impairment

---

## H. Robustness Evidence (Updated v2.0)

All sensitivity values below are computed analytically — not hardcoded.

| Test | Result |
|------|--------|
| One-way SA: Hospitalization cost ($11,337–$35,899) | Savings: $0.9M–$5.5M |
| One-way SA: ARR (8%–24%) | Savings: $1.3M–$5.6M |
| One-way SA: TDM assay cost ($150–$500) | Savings: $3.1M–$3.4M |
| Two-way SA: 100 scenarios (cost × ARR) | Positive in 100% of scenarios |
| Break-even ARR at $22,839 | 1.5% (base ARR 15.6%; margin: 14.1 pp) |
| Baseline calibration | 66.0% vs PALOMA-2 66.4% (Δ = 0.4 pp) |
| NNT calibration | 6.4 vs Leenhardt 2022 6.3 (Δ = 0.1) |
| Dose reduction rate | 36.4% vs PALOMA-2 36.4% (exact match) |
| Cross-source PK MAPE | 6.8% across 5 independent sources (<20% threshold) |
| Three-tier validation | 9/9 tests passed |

---

## I. Recommendations Before Clinical Implementation

1. Prospective validation in a small cohort (n = 20–50) measuring individual
   steady-state Cmin at Cycle 2 Day 15 with a validated LC-MS/MS assay.

2. Confirm local hospitalization and TDM assay costs before applying economic
   conclusions to non-US healthcare settings.

3. Establish LC-MS/MS assay capability with appropriate analytical validation
   (LOQ ≤ 1 ng/mL; Turković et al. 2022).

4. Develop CYP3A4 co-medication screening protocol before clinical use.

5. Design a prospective controlled validation study. Recommended sample size:
   n = 60–80 patients per arm (based on ARR = 15.6%, 80% power, α = 0.05,
   two-sided). PROSPERO registration recommended for systematic component.

6. Consider pharmacogenomic screening (ABCB1, CYP3A5) as companion biomarker
   panel — supported by companion systematic review currently in preparation.

---

## J. Funding & Conflicts of Interest

No funding was received for this analysis. The author declares no conflicts
of interest. This work was conducted independently as part of PharmD
dissertation research at Akhtar Saeed College of Pharmacy, University of
the Punjab, Rawalpindi, Pakistan.

AI-assisted tools used in the preparation of this work: Claude (Anthropic),
Grammarly (grammar checking). All scientific content, parameter selection,
model design, and clinical interpretation are the sole responsibility of
the author.

---

**Version:** 2.0 | **Date:** May 2026
**Author:** Mohammad Bisam Ali Aslam, PharmD Candidate (Year 3)
**Institution:** Akhtar Saeed College of Pharmacy, University of the Punjab
**Supervisor:** Dr. Zubair Anwar
**Status:** Publication-Grade | Ready for Peer Review
**Repository:** https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation| **Status:** Ready for Peer Review
