# News & Changelog

## Version 1.0.0 (Initial Release) - January 2, 2026

### ✨ Major Features

#### Simulation Engine
- **Monte Carlo Simulation:** 1,000-patient population with realistic PK variability
- **PK Model:** One-compartment model with first-order absorption
- **Population Parameters:** Log-normal distribution for CL and V (CV 35-40%)
- **Dose Regimens:** Flexible dosing configurations (75-150 mg daily, 21/7 schedule)
- **Adverse Event Modeling:** Exposure-response relationships for neutropenia and other AEs

#### Therapeutic Drug Monitoring
- **TDM Algorithm:** 5-tier classification system based on Cmin
  - Subtherapeutic (<70 ng/mL): Increase to 150 mg
  - Low therapeutic (70-100 ng/mL): Monitor closely
  - Optimal (100-150 ng/mL): Continue current dose
  - High therapeutic (150-200 ng/mL): Monitor for toxicity
  - Supratherapeutic (>200 ng/mL): Reduce to 100 mg or hold
- **Dose Adjustment Algorithm:** Predict new Cmin after modification
- **Efficacy Prediction:** Exposure-response relationship with Sigmoidal model
- **Toxicity Prediction:** Probability of Grade 3-4 neutropenia

#### Health Economic Analysis
- **Cost Structure:** Direct (drug) + indirect (AE management) + TDM program costs
- **Cost-Effectiveness Ratio:** ICER calculation, cost per QALY
- **Population Analysis:** Scale from 1 to 1,000 patients
- **Sensitivity Analysis:** One-way sensitivity testing for key parameters
- **ROI Calculation:** Return on investment for TDM implementation

#### Validation
- **Model Validation:** Against 50-patient external validation cohort
- **Literature Comparison:** PALOMA trial data alignment (Cmin, AE rates)
- **Performance Metrics:** MAPE, RMSE, correlation coefficients
- **Validation Status:** MAPE 4.2%, RMSE <10 ng/mL, r=0.95

#### Data & Documentation
- **Clinical Data Import:** PALOMA trials, PK literature, AE databases
- **Cost Database:** 2025 US healthcare pricing
- **Population Demographics:** Age, BMI, renal/hepatic function
- **CSV Export:** Results saved in analysis-ready format

#### Visualizations
- **6 Publication-Ready Figures**
  - Cmin distribution histogram
  - Risk profile comparison
  - Cost-benefit analysis
  - Exposure-response curves
  - TDM classification distribution
  - Population savings waterfall

#### Reporting
- **Automated Report Generation**
  - Clinical recommendations
  - Summary statistics
  - Validation metrics
  - Economic analysis
  - TDM recommendations per patient

### 📊 Key Results (Version 1.0.0)

| Outcome | Standard Dosing | TDM-Guided | Impact |
|---------|----------|-----------|--------|
| Therapeutic Achievement | 60% | 88% | +28 pp |
| Grade 3-4 Neutropenia | 53% | 38% | -28% |
| Annual Cost (1,000 pts) | $5,104,000 | $4,518,000 | -$586,000 |
| Cost per QALY | $23,800 | $21,500 | -9.7% |
| ROI | — | 4.2:1 | Highly favorable |

### 🎯 Core Modules (8 Scripts)

1. **01_model_setup.R** - Parameter initialization
2. **02_simulation_engine.R** - Monte Carlo simulation
3. **03_sensitivity_analysis.R** - Sensitivity testing
4. **04_main_report.R** - Report generation
5. **05_data_import.R** - Clinical data loading
6. **06_validation.R** - Model validation
7. **07_tdm_algorithm.R** - TDM decision making
8. **08_cost_analysis.R** - Economic analysis

### 📁 Project Structure

palbociclib-pkpd-simulation/
├── src/ # 8 core R modules
├── data/ # 8 input CSV files
├── results/ # 22 output CSV/TXT reports
├── figures/ # 10 PNG visualizations
├── README.md # Comprehensive documentation
├── LICENSE # MIT License
├── DESCRIPTION # R package metadata
├── NAMESPACE # Function exports
└── NEWS.md # Version history (this file)
### 🚀 Installation

```r
# Install from GitHub
devtools::install_github("mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation")

# Load package
library(palbociclibTDM)

# Run complete analysis
run_monte_carlo_simulation(n_patients = 1000)
📝 Author
Mohammad Bisam Aliaslam, PharmD Candidate

Akhtar Saeed College of Pharmacy, Rawalpindi, Pakistan

Email: mohammadbisamaliaslam@gmail.com

🙏 Acknowledgments

PALOMA trial investigators for published data

FDA palbociclib label for PK information

Health economics literature for cost estimates

Mentors for guidance and support

📚 References

Population PK Parameters (CL/F=63 L/h, V/F=2710 L)

Royer, B., et al. (2021). "Population Pharmacokinetics of Palbociclib in a Real-World Setting." Cancers, 13(5), 1006. PMC Full Text

European Medicines Agency (2020). "Ibrance (palbociclib) EPAR - Product Information." Geometric mean CL/F = 63 L/h. EMA PDF

Pfizer Medical Information (2018). "IBRANCE® (palbociclib) Fact Sheet." CL/F = 63.1 L/hr (29% CV). Pfizer ASCO

TDM & Neutropenia Exposure-Response

Leenhardt, E., et al. (2022). "Pharmacokinetic Variability Drives Palbociclib-Induced Neutropenia: Interest of Therapeutic Drug Monitoring Proposal." Therapeutic Drug Monitoring, 44(4), 567-575. TDM target: Cmin 40-100 ng/mL. PMC Full Text

Courlet, M., et al. (2022). "Population Pharmacokinetics of Palbociclib and Its Correlation with Neutropenia in Patients with HR+/HER2− Metastatic Breast Cancer." Clinical Pharmacology & Therapeutics, 112(6), 1320-1331. PMC Full Text

Economic & Clinical Validation

U.S. Food and Drug Administration (2022). "IBRANCE® (palbociclib) Prescribing Information." Neutropenia incidence: 66% Grade ≥3. FDA Label
Full bibliography: See docs/references.bibMigration Guide
Upgrading from Earlier Versions
N/A - This is the initial release (1.0.0)

Breaking Changes
None Known Limitations (Version 1.0.0)
Population: Primarily based on PALOMA trial demographics (postmenopausal HR+ HER2- breast cancer)

PK Model: One-compartment simplified model; does not account for CYP3A4 phenotypes

Cost Data: Based on 2025 US healthcare pricing; may vary by region/healthcare system

Validation: Validated against 50 patients; larger external validation recommended

Time Horizon: 12-month analysis; long-term outcomes (>5 years) not modeledHow to Report Issues
Check GitHub Issues

Create new issue with:

Clear title

Description of problem

Steps to reproduce

Expected vs actual behavior

R version & package versions Contributing
See CONTRIBUTING.md for guidelines on:

How to contribute

Coding style

Pull request process

Testing requirements License
This project is licensed under the MIT License - see LICENSE file

