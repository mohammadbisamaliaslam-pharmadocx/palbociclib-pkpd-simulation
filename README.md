# Palbociclib Population PK/PD Simulation

## Overview

This repository contains R code for a population pharmacokinetic/pharmacodynamic (PK/PD) simulation of **palbociclib**, a CDK4/6 inhibitor used in breast cancer treatment. The simulation characterizes dose-exposure-response relationships and predicts clinical outcomes under various dosing regimens.

**Status**: Active development (Jan–Aug 2026) | Prepared for ASHP presentation (Dec 2026) and CPT tutorial publication (2027)

---

## Project Objectives

1. **Develop reproducible PK/PD model** for palbociclib using published pharmacometric literature
2. **Simulate dose-exposure-response** across patient populations (weight, age, organ function variations)
3. **Validate against clinical trial data** (e.g., PALOMA trials)
4. **Create publication-quality visualization** and sensitivity analysis
5. **Demonstrate R proficiency** in pharmacometric modeling 

---

## Scientific Background

### What is Palbociclib?
Palbociclib (Ibrance®) is a selective inhibitor of cyclin-dependent kinases 4 and 6 (CDK4/6). It is used in combination with hormonal therapy to treat hormone receptor–positive (HR+) breast cancer.

### Why PK/PD Modeling?
Palbociclib exhibits nonlinear pharmacokinetics, drug-drug interactions (CYP3A4 metabolism), and population variability. A mechanistic PK/PD model enables:
- Prediction of pharmacological response across subpopulations
- Identification of dose-limiting toxicities
- Optimization of clinical dosing recommendations

### Model Structure
- **PK**: 2-compartment model with first-order absorption (fasted state)
- **PD**: Inhibitory E_max model relating plasma concentration to CDK4/6 target occupancy and tumor growth inhibition
- **Population effects**: Allometric scaling (weight), CYP3A4 phenotype (metabolizer status)

---

## Repository Structure

| Folder/File | Purpose |
|-------------|---------|
| `data/` | Raw data (PK parameters, trial data) |
| `scripts/` | R analysis code (**6 modular scripts**) |
| `outputs/` | Results (PDF plots, CSV data) |
| `docs/` | Documentation (equations, **references.bib**) |
| `01_model_setup.R` | PK parameters + model functions |
| `02_simulation.R` | **TDM simulation engine** |
| `03_visualization.R` | Publication-quality plots |
| `04_sensitivity_analysis.R` | Parameter uncertainty analysis |
| `05_validation.R` | Trial data comparison |
| `renv.lock` | Reproducible R environment |


---

## Installation & Setup

### Prerequisites
- **R** (≥4.0.0) – Download from [cran.r-project.org](https://cran.r-project.org/)
- **RStudio** (recommended) – Download from [posit.co/products/open-source/rstudio](https://posit.co/products/open-source/rstudio/)

### Required R Packages

Install these packages before running simulations:
Install from CRAN
packages <- c("rxode2", "tidyverse", "ggplot2", "gridExtra", "knitr", "rmarkdown")
install.packages(packages)

Load libraries in your script
library(rxode2) # ODE solver for PK/PD simulation
library(tidyverse) # Data wrangling & visualization
library(ggplot2) # Advanced plotting

### Reproducible Environment (Optional but Recommended)

Use `renv` to ensure everyone can replicate your exact environment:

First time setup
renv::init()

After installing packages, snapshot your environment
renv::snapshot()

Others can restore your environment
renv::restore()

## Quick Start: Running the Simulation

### Step 1: Clone This Repository
git clone https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation.git
cd palbociclib-pkpd-simulation

### Step 2: Install Dependencies
Open R/RStudio and run:
Source the setup script (one time)
source("scripts/01_model_setup.R")

### Step 3: Run Simulation
Load and execute main simulation
source("scripts/02_simulation.R")

Generate plots
source("scripts/03_visualization.R")

Output files saved to: outputs/


### Step 4: View Results
- PK profiles: `outputs/pk_profiles.pdf`
- PD relationships: `outputs/pd_relationships.pdf`
- Data: `outputs/simulation_results.csv`

**Expected runtime**: ~2–5 minutes on standard laptop

---

## Model Specification

### Pharmacokinetics (PK)

**Two-compartment model with first-order absorption:**

Input (Oral Dose)
↓ (Ka)
Central Compartment (Vc) ↔ Peripheral (Vp)
↓ (CL)
Elimination


**Key parameters:**
- **Ka** (h⁻¹): Absorption rate constant
- **CL** (L/h): Clearance (CYP3A4-dependent)
- **Vc** (L): Central volume of distribution
- **Vp** (L): Peripheral volume
- **Q** (L/h): Inter-compartmental clearance

**Allometric scaling** (to account for body weight):

CL_individual = CL_ref × (Weight / Weight_ref)^0.75
Vc_individual = Vc_ref × (Weight / Weight_ref)^1.00

### Pharmacodynamics (PD)

**Inhibitory E_max model:**

Effect = E_max × Conc / (EC50 + Conc)

text

Where:
- **E_max**: Maximum target occupancy (%)
- **EC50**: Concentration producing 50% effect
- **Conc**: Plasma concentration at time t

**Tumor growth inhibition** depends on duration and intensity of target occupancy.

---

## Key Assumptions

1. **Linear PK within therapeutic dose range** (no saturation)
2. **Food effect not modeled** (fasted-state parameters)
3. **No active metabolites** (metabolite-mediated toxicity ignored)
4. **Drug-disease interaction**: Assumes stable disease state (no disease progression feedback)
5. **Population model**: Uses published population parameters from literature (see `docs/references.bib`)

**Limitations** are documented in `docs/assumptions.md`

---

## Outputs & Interpretation

### PK Profiles (`pk_profiles.pdf`)
- X-axis: Time (hours)
- Y-axis: Plasma concentration (ng/mL)
- Multiple lines: Different patients (varying weights, CYP3A4 phenotypes)
- **Interpretation**: Shows inter-individual variability in drug exposure

### PD Relationships (`pd_relationships.pdf`)
- X-axis: Plasma concentration (ng/mL)
- Y-axis: CDK4/6 target occupancy or tumor growth inhibition (%)
- **Interpretation**: Relationship between dose/concentration and therapeutic effect

### Sensitivity Analysis (`sensitivity_tornado.pdf`)
- Shows which parameters have largest impact on model predictions
- **Interpretation**: Identifies where more precise parameter estimates are needed

---

## Publication & Citation

### How to Cite This Work

If you use code or methods from this repository in your own research, please cite:

**BibTeX format:**
@software{Khan2026_Palbociclib_PKPD,
author = {Khan, Mohammad Bisam Ali Aslam},
title = {palbociclib-pkpd-simulation: Population PK/PD modeling of CDK4/6 inhibitor in breast cancer},
year = {2026},
url = {https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation},
version = {1.0}
}


**In-text citation:**
"We used the open-source palbociclib PKPD simulation model (Khan, 2026; https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation) to characterize dose-exposure-response relationships."

### Acknowledgments

This project was developed under the mentorship of **Dr. Zubair Anwar** as part of ASHP presenter preparation and CPT tutorial development.

**Funding/Support**: Akhtar saeed college of pharmacy rawalpindi

---

## Development Timeline

| Phase | Dates | Deliverables | Status |
|-------|-------|--------------|--------|
| **Phase 1: Setup & Literature** | Jan 2026 | GitHub repo, model equations, parameter compilation | In progress |
| **Phase 2: Code & Simulation** | Feb–Mar 2026 | Functional ODE solver, population simulation, validation | Planned |
| **Phase 3: Visualization & Polish** | Apr 2026 | Publication-quality plots, sensitivity analysis | Planned |
| **Phase 4: ASHP Preparation** | May–Jun 2026 | Abstract, presentation materials, peer review | Planned |
| **Phase 5: CPT Tutorial** | Jul–Aug 2026 | Full tutorial manuscript, submitted to journal | Planned |
| **Phase 6: Final Polish & Archival** | Sep–Dec 2026 | Code review, documentation finalization, GitHub release | Planned |

---

## Contributing & Feedback

**This is a solo project for academic purposes.** However, if you find errors or have suggestions:

1. **Open an Issue** on GitHub (describe problem + expected behavior)
2. **Provide data**: Share minimal reproducible example if bug-related

**Author & Maintainer**: Mohammad Bisam Ali Aslam, pharmD

---

## License

This project is licensed under the **MIT License** – see `LICENSE` file for details.

**In short**: You're free to use, modify, and distribute this code, provided you include the original license and copyright notice.

---

## References

Key publications informing this TDM simulation model:

### Population PK Parameters (CL/F=63 L/h, V/F=2710 L)
- Royer, B., et al. (2021). "Population Pharmacokinetics of Palbociclib in a Real-World Setting." *Cancers*, 13(5), 1006. [PMC Full Text](https://pmc.ncbi.nlm.nih.gov/articles/PMC7996283/)
- European Medicines Agency (2020). "Ibrance (palbociclib) EPAR - Product Information." Geometric mean CL/F = 63 L/h. [EMA PDF](https://ec.europa.eu/health/documents/community-register/2020/20200213147046/anx_147046_en.pdf)
- Pfizer Medical Information (2018). "IBRANCE® (palbociclib) Fact Sheet." CL/F = 63.1 L/hr (29% CV). [Pfizer ASCO](https://cdn.pfizer.com/pfizercom/news/asco/IBRANCE(palbociclib)_Fact_Sheet_16MAY2018.pdf)

### TDM & Neutropenia Exposure-Response
- Leenhardt, E., et al. (2022). "Pharmacokinetic Variability Drives Palbociclib-Induced Neutropenia: Interest of Therapeutic Drug Monitoring Proposal." *Therapeutic Drug Monitoring*, 44(4), 567-575. TDM target: Cmin 40-100 ng/mL. [PMC Full Text](https://pmc.ncbi.nlm.nih.gov/articles/PMC9032884/)
- Courlet, M., et al. (2022). "Population Pharmacokinetics of Palbociclib and Its Correlation with Neutropenia in Patients with HR+/HER2− Metastatic Breast Cancer." *Clinical Pharmacology & Therapeutics*, 112(6), 1320-1331. [PMC Full Text](https://pmc.ncbi.nlm.nih.gov/articles/PMC9322950/)

### Economic & Clinical Validation
- U.S. Food and Drug Administration (2022). "IBRANCE® (palbociclib) Prescribing Information." Neutropenia incidence: 66% Grade ≥3. [FDA Label](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/207103s015lbl.pdf)

**Full bibliography**: See `docs/references.bib`


---

## Contact & Support

**Questions about the model?**
- Email: mohammadbisamaliaslam@gmail.com
- GitHub Issues: [https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation/issues](https://github.com/mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation/issues)


**Last updated**: January 2026
**Repository last modified**: [Auto-updates with each commit]

---

**Made with ❤️ for the pharmacometrics community.**
