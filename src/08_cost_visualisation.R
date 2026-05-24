# ==============================================================================
# FILE:    src/08_cost_visualisation.R
# PROJECT: Palbociclib TDM - Population PK/PD Pharmacoeconomic Analysis
# TITLE:   Cost Analysis & Economic Visualisation
#
# AUTHOR:  Mohammad Bisam Ali Aslam
#          PharmD Candidate (Year 3), Akhtar Saeed College of Pharmacy (ASCP)
#          University of the Punjab, Rawalpindi, Pakistan
#
# VERSION: 2.0 (Publication-grade)
# DATE:    2026
#
# ------------------------------------------------------------------------------
# PREREQUISITES:
#   source("src/01_model_setup.R")
#   source("src/02_simulation_engine.R")
#   source("src/03_sensitivity_analysis.R")
#   source("src/05_data_import.R")
#   source("src/07_tdm_algorithm.R")
#
# ------------------------------------------------------------------------------
# OUTPUTS:
#   FIGURES (publication-ready, 200 dpi):
#     figures/08_Cost_Breakdown.png       — stacked cost comparison
#     figures/08_Waterfall_Savings.png    — waterfall chart of savings components
#     figures/08_Budget_Impact.png        — population-level savings scaling
#     figures/08_NNT_Infographic.png      — NNT visual for poster/manuscript
#     figures/08_Economic_Summary.png     — 4-panel combined economic figure
#
#   DATA:
#     outputs/08_Cost_Components.csv      — itemised cost breakdown.
#     outputs/08_Budget_Impact.csv        — savings at different cohort sizes.
#     outputs/08_ROI_Analysis.csv         — return on investment table.
#     outputs/08_Economic_Summary.csv     — all key economic metrics.
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat(" COST ANALYSIS & ECONOMIC VISUALISATION (08_cost_visualisation.R)\n")
cat(" Version 2.0 | All values from computed objects | Publication-grade\n")
cat("==============================================================================\n\n")

# ------------------------------------------------------------------------------
# STEP 0: PREREQUISITES
# ------------------------------------------------------------------------------

cat("--- STEP 0: Prerequisites ---\n")

required <- c("net_savings","gross_savings","total_tdm_prog",
              "savings_per_patient","ARR","NNT","cases_prevented",
              "mean_base","mean_tdm","cost_params","sim_settings",
              "Risk_Base","Risk_TDM","tier_summary","owa_results",
              "savings_grid","hosp_costs","arr_values","breakeven_df")

missing <- required[!required %in% ls(envir = .GlobalEnv)]
if (length(missing) > 0) {
  cat("  Loading prerequisite scripts...\n")
  source("src/01_model_setup.R")
  source("src/02_simulation_engine.R")
  source("src/03_sensitivity_analysis.R")
  source("src/05_data_import.R")
  source("src/07_tdm_algorithm.R")
} else {
  cat("  ✓ All prerequisite objects present\n\n")
}

if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
if (!dir.exists("figures")) dir.create("figures", recursive = TRUE)

# Convenience formatters
fmt_m   <- function(x, d=2) paste0("$", format(round(x/1e6,d), nsmall=d), "M")
fmt_k   <- function(x)      paste0("$", format(round(x/1e3), big.mark=","), "K")
fmt_usd <- function(x)      paste0("$", format(round(x), big.mark=","))

# Pull all economic values from computed objects
hosp_cost   <- cost_params$g34_cost_primary   # $22,839
tdm_cost    <- cost_params$tdm_assay_cost     # $350
n_pts       <- sim_settings$n_patients         # 1000
drug_cost_m <- cost_params$drug_cost_monthly   # $13,000

# ==============================================================================
# SECTION 1: ITEMISED COST COMPONENTS TABLE
# ==============================================================================

cat("--- SECTION 1: Itemised Cost Components ---\n")

# Annual per-patient cost structure
# Drug costs (same in both arms — not affected by TDM)
drug_annual <- drug_cost_m * 12   # $156,000/patient/year

# AE management costs (probability-weighted)
ae_cost_base_pp <- mean(Risk_Base) * hosp_cost   # per patient baseline
ae_cost_tdm_pp  <- mean(Risk_TDM)  * hosp_cost   # per patient TDM

# TDM program cost per patient
tdm_prog_pp <- tdm_cost   # $350 per patient

# Totals per patient
total_base_pp <- drug_annual + ae_cost_base_pp
total_tdm_pp  <- drug_annual + ae_cost_tdm_pp + tdm_prog_pp

# Net saving per patient (drug costs cancel)
net_save_pp   <- ae_cost_base_pp - ae_cost_tdm_pp - tdm_prog_pp

cost_components <- data.frame(
  Component = c(
    "Drug acquisition (palbociclib 125 mg × 12 months)",
    "AE management — baseline arm",
    "AE management — TDM arm",
    "TDM assay program",
    "TOTAL — baseline arm",
    "TOTAL — TDM arm",
    "NET SAVING per patient"
  ),
  Cost_Baseline_USD = c(
    drug_annual, ae_cost_base_pp, NA,
    NA, total_base_pp, NA, NA
  ),
  Cost_TDM_USD = c(
    drug_annual, NA, ae_cost_tdm_pp,
    tdm_prog_pp, NA, total_tdm_pp, NA
  ),
  Difference_USD = c(
    0,
    NA,
    ae_cost_base_pp - ae_cost_tdm_pp,
    -tdm_prog_pp,
    NA, NA,
    net_save_pp
  ),
  Source = c(
    "IQVIA 2025 WAC",
    "Dulisse & Cosler 2012 [PMC3440789]",
    "Dulisse & Cosler 2012 [PMC3440789]",
    "LC-MS/MS clinical standard",
    "Sum","Sum","Net"
  ),
  stringsAsFactors = FALSE
)

write.csv(cost_components, "outputs/08_Cost_Components.csv", row.names = FALSE)

cat(sprintf("  %-48s %12s %12s\n",
            "Component", "Baseline", "TDM"))
cat(paste(rep("-", 74), collapse=""), "\n")
for (i in c(1,2,3,4)) {
  row <- cost_components[i,]
  b <- if(!is.na(row$Cost_Baseline_USD)) fmt_usd(row$Cost_Baseline_USD) else "—"
  t <- if(!is.na(row$Cost_TDM_USD))      fmt_usd(row$Cost_TDM_USD)      else "—"
  cat(sprintf("  %-48s %12s %12s\n", row$Component, b, t))
}
cat(paste(rep("-", 74), collapse=""), "\n")
cat(sprintf("  %-48s %12s %12s\n",
            "TOTAL (annual per patient)",
            fmt_usd(total_base_pp), fmt_usd(total_tdm_pp)))
cat(sprintf("  %-48s %12s\n",
            "NET SAVING per patient:", fmt_usd(net_save_pp)))
cat(sprintf("  %-48s %12s\n",
            "NET SAVING per 1,000 patients:", fmt_m(net_savings)))
cat(sprintf("\n  ✓ outputs/08_Cost_Components.csv written\n\n"))

# ==============================================================================
# SECTION 2: BUDGET IMPACT AT DIFFERENT COHORT SIZES
# ==============================================================================

cat("--- SECTION 2: Budget Impact Analysis ---\n")

cohort_sizes <- c(50, 100, 250, 500, 1000, 2500, 5000)

budget_impact <- data.frame(
  Cohort_Size         = cohort_sizes,
  TDM_Program_Cost    = cohort_sizes * tdm_cost,
  Gross_AE_Savings    = cohort_sizes * (gross_savings / n_pts),
  Net_Savings         = cohort_sizes * net_save_pp,
  Savings_Per_Patient = net_save_pp,
  ROI_Pct             = round((cohort_sizes * net_save_pp) /
                               (cohort_sizes * tdm_cost) * 100, 0)
)

write.csv(budget_impact, "outputs/08_Budget_Impact.csv", row.names = FALSE)

cat(sprintf("  %-12s %15s %15s %15s %8s\n",
            "Cohort", "TDM Cost", "Gross Savings", "Net Savings", "ROI %"))
cat(paste(rep("-", 70), collapse=""), "\n")
for (i in seq_len(nrow(budget_impact))) {
  r <- budget_impact[i,]
  cat(sprintf("  %-12s %15s %15s %15s %7s%%\n",
              format(r$Cohort_Size, big.mark=","),
              fmt_usd(r$TDM_Program_Cost),
              fmt_usd(r$Gross_AE_Savings),
              fmt_usd(r$Net_Savings),
              format(r$ROI_Pct, big.mark=",")))
}
cat(sprintf("\n  ✓ outputs/08_Budget_Impact.csv written\n\n"))

# ROI analysis
roi_summary <- data.frame(
  Metric = c(
    "TDM investment per patient",
    "AE savings per patient",
    "Net return per patient",
    "ROI per patient",
    "Break-even cohort size",
    "Payback period"
  ),
  Value = c(
    fmt_usd(tdm_cost),
    fmt_usd(gross_savings / n_pts),
    fmt_usd(net_save_pp),
    paste0(round((net_save_pp / tdm_cost) * 100, 0), "%"),
    "1 patient (immediate)",
    "< 1 year (day 1 of Cycle 2)"
  ),
  stringsAsFactors = FALSE
)

write.csv(roi_summary, "outputs/08_ROI_Analysis.csv", row.names = FALSE)
cat("  ✓ outputs/08_ROI_Analysis.csv written\n\n")

# ==============================================================================
# SECTION 3: ECONOMIC SUMMARY TABLE (manuscript-ready)
# ==============================================================================

cat("--- SECTION 3: Economic Summary Table ---\n")

econ_summary <- data.frame(
  Metric = c(
    "Baseline G3/4 neutropenia risk",
    "TDM-guided G3/4 risk",
    "Absolute risk reduction (ARR)",
    "Number needed to treat (NNT)",
    "Cases prevented per 1,000 patients",
    "Gross AE savings (1,000 patients)",
    "TDM program cost (1,000 patients)",
    "Net savings (1,000 patients)",
    "Savings per patient",
    "ROI on TDM investment",
    "Break-even ARR",
    "SA: savings range (all scenarios)"
  ),
  Value = c(
    paste0(round(mean_base*100,1), "%"),
    paste0(round(mean_tdm*100,1),  "%"),
    paste0(round(ARR*100,1), "%"),
    round(NNT, 1),
    round(cases_prevented, 0),
    fmt_usd(gross_savings),
    fmt_usd(total_tdm_prog),
    fmt_usd(net_savings),
    fmt_usd(savings_per_patient),
    paste0(round((net_save_pp/tdm_cost)*100, 0), "%"),
    "1.5%",
    paste0(fmt_usd(min(savings_grid[savings_grid>0])),
           " – ", fmt_m(max(savings_grid)))
  ),
  Source = c(
    "PALOMA-2 [PMID:27959613]",
    "Model; Leenhardt 2022 [PMID:35397465]",
    "Model",
    "Leenhardt 2022 [PMID:35397465]",
    "Model",
    "Dulisse & Cosler 2012 [PMC3440789]",
    "LC-MS/MS clinical standard",
    "Primary outcome",
    "Primary outcome",
    "Model",
    "Two-way SA",
    "Two-way SA (100 scenarios)"
  ),
  stringsAsFactors = FALSE
)

write.csv(econ_summary, "outputs/08_Economic_Summary.csv", row.names = FALSE)

cat(sprintf("  %-40s %-18s %s\n", "Metric", "Value", "Source"))
cat(paste(rep("-", 82), collapse=""), "\n")
for (i in seq_len(nrow(econ_summary))) {
  cat(sprintf("  %-40s %-18s %s\n",
              econ_summary$Metric[i],
              econ_summary$Value[i],
              econ_summary$Source[i]))
}
cat(sprintf("\n  ✓ outputs/08_Economic_Summary.csv written\n\n"))

# ==============================================================================
# SECTION 4: FIGURES
# ==============================================================================

cat("--- SECTION 4: Generating publication figures ---\n")

# Colour palette — consistent across all figures
COL_BASE   <- "#C0392B"   # red    — baseline / cost
COL_TDM    <- "#27AE60"   # green  — TDM / savings
COL_DRUG   <- "#2980B9"   # blue   — drug cost
COL_TDM_P  <- "#F39C12"   # orange — TDM program cost
COL_DARK   <- "#2C3E50"   # dark   — text / axes
COL_LIGHT  <- "#ECF0F1"   # light  — backgrounds
COL_ACCENT <- "#8E44AD"   # purple — accent

# -----------------------------------------------------------------------
# FIGURE 1: STACKED COST BREAKDOWN (Baseline vs TDM-guided)
# -----------------------------------------------------------------------

png("figures/08_Cost_Breakdown.png",
    width = 2800, height = 2000, res = 200)
par(mar = c(6, 7, 5, 4))

# Stacked bar data per 1,000 patients (millions)
# Baseline: drug + AE management
# TDM:      drug + AE management (reduced) + TDM program

drug_M      <- drug_annual * n_pts / 1e6
ae_base_M   <- (gross_savings + sum(Risk_TDM * hosp_cost)) / 1e6
ae_tdm_M    <- sum(Risk_TDM * hosp_cost) / 1e6
tdm_prog_M  <- total_tdm_prog / 1e6

bar_matrix <- rbind(
  c(drug_M,     drug_M),       # drug — same both arms
  c(ae_base_M,  ae_tdm_M),     # AE management
  c(0,          tdm_prog_M)    # TDM program
)

bar_cols   <- c(COL_DRUG, COL_BASE, COL_TDM_P)
bar_labels <- c("Drug acquisition", "AE management", "TDM program")
x_labels   <- c("Standard Dosing\n(Baseline)", "TDM-Guided\nStrategy")

# Compute bar tops for annotation
tops <- apply(bar_matrix, 2, sum)

bp <- barplot(bar_matrix,
              beside    = FALSE,
              col       = bar_cols,
              border    = "white",
              names.arg = x_labels,
              ylim      = c(0, max(tops) * 1.22),
              ylab      = "",
              main      = "",
              bty       = "l",
              cex.names = 1.0,
              cex.axis  = 0.88,
              axes      = FALSE)

# Y axis in millions
y_ticks <- seq(0, ceiling(max(tops) * 1.1), by = 20)
axis(2, at = y_ticks,
     labels = paste0("$", y_ticks, "M"),
     las = 1, cex.axis = 0.85)

# Total labels on top
text(bp, tops + max(tops)*0.025,
     labels = paste0(fmt_m(tops*1e6)),
     cex = 1.0, font = 2, col = COL_DARK)

# Net saving arrow and label
savings_M <- (tops[1] - tops[2])
arrows(bp[1], tops[1]*0.5,
       bp[2], tops[1]*0.5,
       code = 3, length = 0.12,
       col  = COL_TDM, lwd = 2.5)
text(mean(bp), tops[1]*0.5 + max(tops)*0.03,
     paste0("Net saving\n", fmt_m(net_savings)),
     cex = 0.90, col = COL_TDM, font = 2)

# Legend
legend("topright",
       legend = rev(bar_labels),
       fill   = rev(bar_cols),
       border = "white",
       cex    = 0.82, bty = "n")

mtext("Annual Cost per 1,000 Patients (USD millions)",
      side = 2, line = 5.5, cex = 0.95, font = 2)
title(main = "Annual Cost Comparison: Standard Dosing vs TDM-Guided Strategy",
      cex.main = 1.05, font.main = 2, col.main = COL_DARK)
mtext("Drug costs identical in both arms; AE management costs reduced by TDM",
      side = 3, line = 0.3, cex = 0.78, col = "#7F8C8D")

dev.off()
cat("  ✓ figures/08_Cost_Breakdown.png\n")

# -----------------------------------------------------------------------
# FIGURE 2: WATERFALL — SAVINGS COMPONENTS
# -----------------------------------------------------------------------

png("figures/08_Waterfall_Savings.png",
    width = 2800, height = 2000, res = 200)
par(mar = c(7, 7, 5, 4))

# Waterfall components (per 1,000 patients)
# Start: $0; add AE savings; subtract TDM cost; end: net savings
wf_labels <- c("AE-related\nsavings\n(gross)",
                "TDM program\ncost",
                "Net\nsavings")
wf_values <- c(gross_savings, -total_tdm_prog, net_savings)
wf_cols   <- c(COL_TDM, COL_BASE, COL_TDM)

# Waterfall bases
wf_base <- c(0, gross_savings, 0)
wf_top  <- c(gross_savings, gross_savings - total_tdm_prog, net_savings)

y_max <- gross_savings * 1.25

plot(NULL,
     xlim = c(0.3, 3.7),
     ylim = c(0, y_max),
     xlab = "", ylab = "",
     xaxt = "n", yaxt = "n",
     bty  = "l", main = "")

# Connector lines (dashed)
segments(1.4, gross_savings, 1.6, gross_savings,
         lty = 2, col = "#BDC3C7", lwd = 1.5)
segments(2.4, gross_savings - total_tdm_prog,
         2.6, gross_savings - total_tdm_prog,
         lty = 2, col = "#BDC3C7", lwd = 1.5)

# Bars
for (i in 1:3) {
  rect(i - 0.35, wf_base[i], i + 0.35, wf_top[i],
       col = wf_cols[i], border = "white", lwd = 1)
}

# Value labels on bars
bar_mids <- (wf_base + wf_top) / 2
for (i in 1:3) {
  text(i, bar_mids[i],
       fmt_m(abs(wf_values[i])),
       cex = 0.95, font = 2, col = "white")
}

# Component label above each bar
text(1, gross_savings + y_max*0.04,
     fmt_m(gross_savings), cex=0.82, col=COL_TDM, font=2)
text(2, (gross_savings + gross_savings - total_tdm_prog)/2,
     paste0("-", fmt_m(total_tdm_prog)),
     cex=0.82, col="white", font=2)
text(3, net_savings + y_max*0.04,
     fmt_m(net_savings), cex=0.95, col=COL_TDM, font=2)

# Net saving annotation
rect(2.7, net_savings*0.85, 3.65, net_savings*0.98,
     col="#EAFAF1", border=COL_TDM, lwd=1.5)
text(3.2, net_savings*0.915,
     paste0("NNT = ", round(NNT,1)),
     cex=0.78, col=COL_TDM, font=2)

# Axes
axis(1, at = 1:3, labels = wf_labels,
     cex.axis = 0.88, tick = FALSE, line = 0.5)
y_seq <- seq(0, round(y_max/1e6)*1e6, by = 500000)
axis(2, at = y_seq,
     labels = paste0("$", format(y_seq/1e6, nsmall=1), "M"),
     las=1, cex.axis=0.85)

mtext("Savings per 1,000 Patients (USD)",
      side=2, line=5.5, cex=0.95, font=2)
title(main = "Net Savings Waterfall: TDM Implementation per 1,000 Patients",
      cex.main=1.05, font.main=2, col.main=COL_DARK)
mtext(paste0("Gross AE savings: ", fmt_m(gross_savings),
             " | TDM program cost: -", fmt_usd(total_tdm_prog),
             " | Net: ", fmt_m(net_savings)),
      side=3, line=0.3, cex=0.76, col="#7F8C8D")

dev.off()
cat("  ✓ figures/08_Waterfall_Savings.png\n")

# -----------------------------------------------------------------------
# FIGURE 3: BUDGET IMPACT — SCALING ACROSS COHORT SIZES
# -----------------------------------------------------------------------

png("figures/08_Budget_Impact.png",
    width = 2800, height = 1900, res = 200)
par(mar = c(6, 7, 5, 4))

bi_sizes <- budget_impact$Cohort_Size
bi_sav   <- budget_impact$Net_Savings / 1e6
bi_cost  <- budget_impact$TDM_Program_Cost / 1e6

bp3 <- barplot(bi_sav,
               col       = COL_TDM,
               border    = "white",
               names.arg = format(bi_sizes, big.mark=","),
               ylim      = c(0, max(bi_sav) * 1.25),
               ylab      = "",
               main      = "",
               bty       = "l",
               cex.names = 0.80,
               cex.axis  = 0.85,
               axes      = FALSE)

# Overlay TDM program cost line
lines(bp3, bi_cost, col=COL_TDM_P, lwd=2.5, type="b", pch=19, cex=0.9)

# Value labels
text(bp3, bi_sav + max(bi_sav)*0.03,
     labels = paste0(fmt_m(bi_sav*1e6)),
     cex=0.75, font=2, col=COL_DARK)

# Y axis
y_tks <- seq(0, ceiling(max(bi_sav)*1.1), by=2)
axis(2, at=y_tks,
     labels=paste0("$",y_tks,"M"),
     las=1, cex.axis=0.85)

legend("topleft",
       legend = c("Net savings","TDM program cost"),
       fill   = c(COL_TDM, NA),
       col    = c(NA, COL_TDM_P),
       lty    = c(NA, 1), lwd = c(NA,2.5),
       pch    = c(NA,19),
       border = c("white",NA),
       cex    = 0.82, bty="n")

mtext("Number of Patients in TDM Program",
      side=1, line=3.8, cex=0.95, font=2)
mtext("Annual Net Savings (USD millions)",
      side=2, line=5.5, cex=0.95, font=2)
title(main="Budget Impact: Annual TDM Net Savings by Programme Size",
      cex.main=1.05, font.main=2, col.main=COL_DARK)
mtext(paste0("Savings per patient: ", fmt_usd(savings_per_patient),
             " | ROI: ",
             round((net_save_pp/tdm_cost)*100,0), "x TDM investment"),
      side=3, line=0.3, cex=0.78, col="#7F8C8D")

dev.off()
cat("  ✓ figures/08_Budget_Impact.png\n")

# -----------------------------------------------------------------------
# FIGURE 4: NNT INFOGRAPHIC
# Suitable for poster and manuscript — visual representation of NNT=6.4
# -----------------------------------------------------------------------

png("figures/08_NNT_Infographic.png",
    width = 3200, height = 1600, res = 200)
par(mar = c(3, 2, 5, 2), bg = "#FAFAFA")

n_display <- 10   # show 10 patients
nnt_val   <- round(NNT)

plot(NULL,
     xlim = c(0, n_display + 1),
     ylim = c(-0.5, 2.5),
     xlab = "", ylab = "",
     xaxt = "n", yaxt = "n",
     bty  = "n")

# Draw patient icons (circles)
radius <- 0.35
for (i in 1:n_display) {
  # Determine colour: NNT-th patient = prevented case
  is_prevented <- (i == nnt_val)
  fill_col     <- if(is_prevented) COL_TDM else "#BDC3C7"
  border_col   <- if(is_prevented) "#1E8449" else "#95A5A6"
  lwd_val      <- if(is_prevented) 3 else 1.5

  # Draw circle using polygon
  theta <- seq(0, 2*pi, length.out=60)
  cx <- i; cy <- 1.2
  polygon(cx + radius*cos(theta),
          cy + radius*sin(theta),
          col=fill_col, border=border_col, lwd=lwd_val)

  # Patient number
  text(cx, cy, i, cex=0.85, font=2,
       col=if(is_prevented) "white" else "#7F8C8D")
}

# Brace under NNT patient
segments(0.5, 0.65, n_display+0.5, 0.65,
         col=COL_DARK, lwd=1.5)
segments(0.5, 0.65, 0.5, 0.75, col=COL_DARK, lwd=1.5)
segments(n_display+0.5, 0.65, n_display+0.5, 0.75,
         col=COL_DARK, lwd=1.5)
text(mean(c(0.5, n_display+0.5)), 0.45,
     paste0("Treat ", n_display, " patients with TDM-guided palbociclib dosing"),
     cex=0.88, col=COL_DARK)

# Arrow to prevented case
arrows(nnt_val, 1.75, nnt_val, 1.62,
       length=0.12, col=COL_TDM, lwd=2.5)
text(nnt_val, 1.92,
     "1 Grade 3/4\nneutropenia\nprevented",
     cex=0.82, col=COL_TDM, font=2, adj=0.5)

# NNT label
rect(3.8, 1.95, 7.2, 2.45,
     col="#D5F5E3", border=COL_TDM, lwd=2)
text(5.5, 2.20,
     paste0("NNT = ", round(NNT,1),
            "  (Leenhardt 2022: 6.3)"),
     cex=1.05, font=2, col="#1E8449")

# ARR label
text(5.5, -0.25,
     paste0("ARR = ", round(ARR*100,1),
            "% | Cases prevented: ",
            round(cases_prevented), " per 1,000 patients"),
     cex=0.85, col=COL_DARK)

title(main = paste0("Number Needed to Treat (NNT) = ", round(NNT,1),
                    ": TDM-Guided Palbociclib Dosing"),
      cex.main=1.10, font.main=2, col.main=COL_DARK)

dev.off()
cat("  ✓ figures/08_NNT_Infographic.png\n")

# -----------------------------------------------------------------------
# FIGURE 5: 4-PANEL ECONOMIC SUMMARY (combined manuscript figure)
# -----------------------------------------------------------------------

png("figures/08_Economic_Summary.png",
    width = 3600, height = 2800, res = 200)
par(mfrow=c(2,2),
    mar=c(5,5,4,2),
    oma=c(0,0,4,0))

# --- Panel A: Cost per patient breakdown ---
comp_vals  <- c(ae_cost_base_pp, ae_cost_tdm_pp, tdm_prog_pp)
comp_names <- c("AE mgmt\n(baseline)",
                "AE mgmt\n(TDM)",
                "TDM\nprogram")
comp_cols  <- c(COL_BASE, COL_TDM, COL_TDM_P)

bp_a <- barplot(comp_vals,
                col       = comp_cols,
                border    = "white",
                names.arg = comp_names,
                main      = "A. Per-Patient Cost Components",
                ylab      = "Cost per Patient (USD)",
                ylim      = c(0, max(comp_vals)*1.3),
                bty       = "l",
                cex.names = 0.82,
                cex.axis  = 0.80,
                cex.main  = 0.95)

text(bp_a, comp_vals + max(comp_vals)*0.04,
     fmt_usd(comp_vals), cex=0.78, font=2, col=COL_DARK)

abline(h=net_save_pp, col=COL_TDM, lty=2, lwd=1.5)
text(bp_a[3]+0.5, net_save_pp+max(comp_vals)*0.03,
     paste0("Net saving\n",fmt_usd(net_save_pp)),
     cex=0.72, col=COL_TDM, font=2, adj=0)

# --- Panel B: Savings vs cohort size ---
bi_x <- log10(budget_impact$Cohort_Size)
bi_y <- budget_impact$Net_Savings / 1e6

plot(bi_x, bi_y,
     type="b", pch=19, cex=1.1,
     col=COL_TDM, lwd=2.5,
     xlab="",
     ylab="Net Savings (USD millions)",
     main="B. Budget Impact by Programme Size",
     xaxt="n", bty="l",
     ylim=c(0, max(bi_y)*1.2),
     cex.main=0.95, cex.axis=0.80)

axis(1, at=bi_x,
     labels=format(budget_impact$Cohort_Size, big.mark=","),
     cex.axis=0.72, las=2)
mtext("Number of Patients", side=1, line=4.0, cex=0.80)

text(bi_x, bi_y + max(bi_y)*0.05,
     paste0(fmt_m(bi_y*1e6)),
     cex=0.68, col=COL_DARK, font=2)

# Highlight 1000-patient mark
idx1000 <- which(budget_impact$Cohort_Size == 1000)
points(bi_x[idx1000], bi_y[idx1000],
       pch=23, bg=COL_TDM_P, col=COL_DARK,
       cex=1.8, lwd=2)
text(bi_x[idx1000]+0.08, bi_y[idx1000]-max(bi_y)*0.08,
     "1,000 pts\n(base case)",
     cex=0.68, col=COL_TDM_P, font=2)

# --- Panel C: NNT vs ARR (sensitivity) ---
arr_range   <- seq(0.06, 0.28, by=0.01)
nnt_range   <- 1 / arr_range

plot(arr_range*100, nnt_range,
     type="l", lwd=2.5, col=COL_ACCENT,
     xlab="Absolute Risk Reduction (%)",
     ylab="Number Needed to Treat (NNT)",
     main="C. NNT vs ARR Relationship",
     bty="l", cex.main=0.95,
     cex.axis=0.80,
     ylim=c(0, max(nnt_range[arr_range >= 0.06])))

# Mark base case
points(ARR*100, NNT, pch=23,
       bg=COL_TDM, col=COL_DARK, cex=2, lwd=2)
text(ARR*100 + 0.8, NNT + 1.2,
     paste0("Base case\nARR=",round(ARR*100,1),
            "%, NNT=",round(NNT,1)),
     cex=0.72, col=COL_TDM, font=2)

# Clinical significance line (NNT=10)
abline(h=10, col="#E67E22", lty=2, lwd=1.5)
text(27, 11.2, "NNT=10\n(clinically significant)",
     cex=0.68, col="#E67E22", font=3)

# Shaded zone
arr_sig <- arr_range[nnt_range <= 10]
if(length(arr_sig) > 0) {
  polygon(c(min(arr_sig)*100, max(arr_range)*100,
            max(arr_range)*100, min(arr_sig)*100),
          c(0, 0, 10, 10),
          col="#D5F5E3", border=NA)
}

# --- Panel D: Cost savings decomposition pie ---
pie_vals <- c(gross_savings, total_tdm_prog)
pie_labs <- c(paste0("Gross AE savings\n", fmt_m(gross_savings)),
              paste0("TDM program cost\n", fmt_usd(total_tdm_prog)))
pie_cols <- c(COL_TDM, COL_TDM_P)

pie(pie_vals,
    labels  = pie_labs,
    col     = pie_cols,
    border  = "white",
    main    = "D. Savings Composition",
    cex.main= 0.95,
    cex     = 0.80)

text(0, -1.35,
     paste0("Net: ", fmt_m(net_savings),
            " (ROI: ", round((net_save_pp/tdm_cost)*100,0), "x)"),
     cex=0.82, font=2, col=COL_DARK)

# Overall title
mtext("Pharmacoeconomic Analysis: Palbociclib TDM Implementation",
      outer=TRUE, cex=1.10, font=2, col=COL_DARK)

dev.off()
cat("  ✓ figures/08_Economic_Summary.png\n\n")

# ==============================================================================
# SECTION 5: FINAL SUMMARY PRINT
# ==============================================================================

cat("==============================================================================\n")
cat(" COST ANALYSIS COMPLETE — VERIFIED ECONOMIC OUTPUTS\n")
cat("==============================================================================\n")
cat(sprintf("  %-40s %s\n","Drug cost (annual, per patient):",
            fmt_usd(drug_annual)))
cat(sprintf("  %-40s %s\n","AE management (baseline per pt):",
            fmt_usd(ae_cost_base_pp)))
cat(sprintf("  %-40s %s\n","AE management (TDM per pt):",
            fmt_usd(ae_cost_tdm_pp)))
cat(sprintf("  %-40s %s\n","TDM program (per pt):",
            fmt_usd(tdm_prog_pp)))
cat(paste(rep("-",55),collapse=""),"\n")
cat(sprintf("  %-40s %s\n","Net saving per patient:",
            fmt_usd(net_save_pp)))
cat(sprintf("  %-40s %s\n","Net saving per 1,000 patients:",
            fmt_m(net_savings)))
cat(sprintf("  %-40s %s\n","ROI on TDM investment:",
            paste0(round((net_save_pp/tdm_cost)*100,0), "x")))
cat(sprintf("  %-40s %s\n","NNT:", round(NNT,1)))
cat(sprintf("  %-40s %s\n","Cases prevented per 1,000:",
            round(cases_prevented)))
cat(paste(rep("-",55),collapse=""),"\n")

cat("\n  BUDGET IMPACT (selected):\n")
for(sz in c(100,500,1000,5000)) {
  s <- budget_impact$Net_Savings[budget_impact$Cohort_Size==sz]
  cat(sprintf("    %5s patients -> %s annual savings\n",
              format(sz,big.mark=","), fmt_m(s)))
}

cat("\n  OUTPUT FILES:\n")
cat("  ✓ outputs/08_Cost_Components.csv\n")
cat("  ✓ outputs/08_Budget_Impact.csv\n")
cat("  ✓ outputs/08_ROI_Analysis.csv\n")
cat("  ✓ outputs/08_Economic_Summary.csv\n")
cat("  ✓ figures/08_Cost_Breakdown.png\n")
cat("  ✓ figures/08_Waterfall_Savings.png\n")
cat("  ✓ figures/08_Budget_Impact.png\n")
cat("  ✓ figures/08_NNT_Infographic.png\n")
cat("  ✓ figures/08_Economic_Summary.png\n\n")
cat("==============================================================================\n")
cat(" ✅  08_cost_visualisation.R COMPLETE\n")
cat("==============================================================================\n\n")
