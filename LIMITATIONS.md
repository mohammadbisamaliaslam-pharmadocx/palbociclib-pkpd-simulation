# Study Limitations & Transparency Statement

## Key Limitations

### A. Simulation-Based (Not Real Patient Data)
- Results are theoretical predictions, NOT from a prospective clinical trial
- Baseline risk calibrated to PALOMA-2 (simulated 65.9% vs. observed 66.4%)
- Internal validation cohort is **synthetic** — generated via Bernoulli sampling
  at published dose-level probabilities (125 mg: 66%, 100 mg: 38%, 75 mg: 22%)
  — this is NOT independent external validation against real patient data
- Prospective clinical validation is required before any implementation

### B. Simulation Structure Limitations
- This simulation uses a **scenario-based subgroup approach**, not individual-level
  mechanistic PK/PD computation
- 1,000 patients are assigned to two pre-specified exposure groups (Group A:
  Cmin > 100 ng/mL, n=360; Group B: Cmin ≤ 100 ng/mL, n=640); group risk
  estimates are derived from the Hill equation at group mean Cmin values
- Individual CL/F is not sampled per patient; steady-state Cmin is not computed
  individually from the PK model
- A mechanistic individual-level simulation is planned for Version 2.0

### C. PK Model Limitations
- Population PK parameters (Royer et al. 2021) inform group Cmin distributions
  but are not directly solved in the simulation engine
- No CYP3A4 drug interaction modelling (CYP3A4 inhibitors can increase
  palbociclib exposure 3–4 fold)
- 100% adherence assumed (real-world adherence: 80–90%)
- Fixed bioavailability assumed (no food effect variability modelled)
- No renal or hepatic impairment covariate effects included

### D. PD Model Limitations
- EC50 = 40.1 ng/mL and γ = 0.13 sourced from Courlet et al. (2022);
  these are not primary data from this study
- Hill model applied at group mean Cmin level, not individually per patient
- Instantaneous risk model assumed (no temporal lag between Cmin change
  and neutropenia onset)
- Risk estimates may vary by subgroup (age, renal/hepatic function, ethnicity)
  — no subgroup analysis performed

### E. Economic Limitations
- Hospitalisation cost per Grade 3/4 neutropenia event: $22,839
  (Tai et al. 2017) — not adjusted for inflation since 2017
- Regional cost variation is substantial (approximate range: $15,000–$40,000
  per event); US-derived figures may not apply to other healthcare systems
- Drug acquisition cost ($42,756/year) reflects US list price and will
  differ significantly in other countries
- Indirect costs not modelled (lost productivity, caregiver burden,
  quality of life impact)

### F. Clinical Generalizability
- Population-averaged results; individual patient risk varies widely
  around group estimates
- CYP3A4 inhibitor co-medications not modelled
- Analysis limited to HR+/HER2− metastatic breast cancer (PALOMA population)
- Results may not generalise to male patients, premenopausal patients,
  or patients with significant organ impairment

### G. What Is Not Modelled
- Other toxicities: anaemia, diarrhoea, thrombocytopenia, fatigue
- Efficacy endpoints: progression-free survival (PFS), overall survival (OS)
- Time-dependent clearance or cumulative toxicity across cycles
- Impact of dose reduction on long-term treatment efficacy
- Quality-adjusted life year (QALY) analysis beyond simple estimation

---

## Robustness Evidence

✓ Sensitivity analysis: NNT ranges 5.2–7.8 across EC50 ±20%
✓ Sensitivity analysis: NNT ranges 4.8–8.2 across CL/F ±20%
✓ Sensitivity analysis: NNT ranges 5.5–7.5 across baseline risk ±10%
✓ Economic benefit remains positive even if TDM assay costs increase 50%
✓ Calibration: Simulated baseline 65.9% matches PALOMA-2 observed 66.4%
  (absolute difference 0.5 percentage points)
✓ Dose reduction rate 36.4% consistent with published real-world range (34–40%)
✓ NNT = 6.4 convergent with independently published real-world TDM study
  (Leenhardt et al. 2022, Ther Drug Monit: NNT = 6.3)

---

## Recommendations Before Implementation

1. Pilot validation in a small prospective cohort (20–50 patients) measuring
   individual Cmin at steady state (Day 14–15, Cycle 1)
2. Confirm local hospitalisation and TDM assay costs before applying the
   economic model to non-US healthcare settings
3. Establish LC-MS/MS assay capability with appropriate analytical validation
4. Develop a CYP3A4 co-medication screening protocol before clinical use
5. Plan a prospective controlled validation study (recommended: 60–80 patients
   per arm based on projected 15.8 percentage point ARR, 80% power, α = 0.05)

---

## Verdict

**Classification:** Proof-of-concept scenario-based simulation

- ✓ Appropriate for feasibility assessment and hypothesis generation
- ✓ Appropriate for prospective study design and sample size estimation
- ✓ Appropriate for pharmacoeconomic planning and budget impact analysis
- ✗ NOT validated for individual patient clinical decision-making
- ✗ NOT a substitute for prospective clinical trial evidence

**Next Step:** Prospective clinical validation study required before
implementation in clinical practice.

---

**Version:** 1.0 | **Date:** March 2, 2026 | **Status:** Ready for Peer Review
