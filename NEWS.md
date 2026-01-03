# News & Changelog

## Version 1.0.0 (Initial Release) - January 3, 2026

### ✨ Major Features

#### 1. Validated Pharmacometric Model
- **PK Model:** One-compartment, literature-verified (Royer et al. 2021)
- **PD Model:** Emax exposure-response, calibrated to PALOMA-2 (Finn et al. 2016)
- **Validation:** Matches clinical trial baseline toxicity (66.4%) and real-world dose reductions (36%)

#### 2. Clinical Impact (n=1,000 Simulation)
- **Risk Reduction:** 65.9% → 50.2% (Absolute Reduction: 15.8%)
- **NNT:** 6.4 (Treat 6 patients to prevent 1 severe toxicity)
- **Cases Prevented:** 328 Grade 3/4 neutropenia events prevented per 1,000 patients

#### 3. Economic Impact (Budget Impact Model)
- **Gross Savings (Toxicity Avoided):** ~$5.6 Million
- **TDM Implementation Cost:** ~$2.2 Million
- **Net Cost Savings:** **$3.4 Million per 1,000 patients**
- **ROI:** 2.5:1 (High return on investment)

---

### 📁 Project Structure

**Source Code (src/)**
- 01_model_setup.R
- 02_simulation_engine.R
- 03_sensitivity_analysis.R
- 04_main_report.R
- 05_visualization_ashp.R
- 06_generate_poster.R

**Key Outputs**
- `FINAL_ASHP_POSTER.pdf`: Print-ready conference poster
- `ASHP_04_Economic_Impact.png`: Visualization of the $3.4M savings
- `ASHP_02_NNT_Visual.png`: Visualization of NNT=6.4

---

### ✅ Status
- **Repository:** https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation
- **Version:** 1.0.0 - Production Ready
- **Validation:** PALOMA-2 Calibrated | Literature Verified
- **Last Updated:** January 3, 2026

---

### 🚀 Ready for Submission
All deliverables complete. Validated NNT=6.4 and Savings=$3.4M.
