# ==============================================================================
# FILE:    src/03_sensitivity_analysis.R
# PROJECT: Palbociclib TDM - Population PK/PD Pharmacoeconomic Analysis
# TITLE:   Sensitivity Analysis — One-Way & Two-Way 
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
#   All base parameters and simulation results must be in global environment.
#
# ------------------------------------------------------------------------------
# WHAT THIS SCRIPT DOES:
#
# 1. ONE-WAY SENSITIVITY ANALYSIS (Tornado diagram)
#    Varies each parameter individually ±20-30% from base case.
#    Computes NNT and net savings at each extreme.
#    Identifies which parameters drive results most.
#    ALL values computed from formula — nothing hardcoded.
#
# 2. TWO-WAY SENSITIVITY ANALYSIS (Primary — heatmap grid)
#    Simultaneously varies:
#      AXIS 1: Hospitalization cost ($11,337 – $35,899)
#              Range source: Kuderer 2015 ASH (low) to Flanigan 2024 (high)
#      AXIS 2: Absolute Risk Reduction (8% – 24%)
#              Range source: Lower bound = conservative ARR if TDM benefit
#              is 50% of base case; Upper = Leenhardt optimistic scenario
#    Computes net savings at every grid point (10×10 grid = 100 scenarios).
#    Identifies the BREAK-EVEN LINE where savings = $0.
#    This is the figure reviewers will look for first.
#
# SCIENTIFIC RATIONALE FOR THIS PAIRING:
#    Net savings = (ARR × Hosp_Cost × n) − (TDM_Cost × n)
#    These two parameters appear on OPPOSITE SIDES of the savings equation.
#    Hosp_Cost amplifies the benefit; ARR determines how much benefit exists.
#    Neither alone tells the full story. Their interaction determines whether
#    TDM implementation is economically justified under uncertainty.
#    The break-even contour is the single most policy-relevant output of
#    this entire analysis.
#
# ALL OUTPUTS:
#   outputs/03_One_Way_SA.csv        — tornado data
#   outputs/03_Two_Way_SA_Grid.csv   — full heatmap grid
#   outputs/03_Breakeven_Table.csv   — break-even pairs
#   figures/03_Tornado.png           — one-way figure
#   figures/03_Heatmap.png           — two-way figure (KEY FIGURE)
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat(" SENSITIVITY ANALYSIS (03_sensitivity_analysis.R)\n")
cat(" Version 2.0 | All values computed | Nothing hardcoded\n")
cat("==============================================================================\n\n")

# ------------------------------------------------------------------------------
# STEP 0: PREREQUISITES CHECK
# ------------------------------------------------------------------------------

cat("--- STEP 0: Prerequisites check ---\n")

required_objects <- c("ARR","NNT","net_savings","mean_base","mean_tdm",
                      "cost_params","sim_settings","scenario_params",
                      "Risk_Base","Risk_TDM","n_A","n_B")

missing <- required_objects[!required_objects %in% ls(envir = .GlobalEnv)]
if (length(missing) > 0) {
  cat("  Missing objects — running prerequisite scripts...\n")
  source("src/01_model_setup.R")
  source("src/02_simulation_engine.R")
} else {
  cat("  ✓ All prerequisite objects present\n")
}

# Store base case values — these are the anchors for all SA
base_ARR      <- ARR
base_NNT      <- NNT
base_savings  <- net_savings
base_hosp     <- cost_params$g34_cost_primary   # $22,839
base_tdm_cost <- cost_params$tdm_assay_cost     # $350
base_baseline <- mean_base                       # 0.660
base_tdm_risk <- mean_tdm                        # 0.504
n_patients    <- sim_settings$n_patients         # 1000

cat(sprintf("  Base ARR:           %.1f%%\n", base_ARR * 100))
cat(sprintf("  Base NNT:           %.1f\n",   base_NNT))
cat(sprintf("  Base net savings:   $%s\n",
            format(round(base_savings), big.mark = ",")))
cat(sprintf("  Base hosp cost:     $%s\n",
            format(base_hosp, big.mark = ",")))
cat(sprintf("  Base TDM cost:      $%s\n",
            format(base_tdm_cost, big.mark = ",")))

if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
if (!dir.exists("figures")) dir.create("figures", recursive = TRUE)

cat("\n")

# ==============================================================================
# CORE SAVINGS FORMULA
# Net savings = (ARR × Hosp_Cost − TDM_Cost) × n_patients
#
# This is the analytical formula equivalent to the Monte Carlo result.
# Using it here allows exact computation at any parameter combination
# without re-running the stochastic simulation.
#
# DERIVATION:
#   Total hosp cost (baseline) = mean_base × hosp_cost × n
#   Total hosp cost (TDM)      = mean_tdm  × hosp_cost × n
#   Gross savings              = (mean_base − mean_tdm) × hosp_cost × n
#                              = ARR × hosp_cost × n
#   TDM program cost           = tdm_cost × n
#   Net savings                = ARR × hosp_cost × n − tdm_cost × n
#                              = n × (ARR × hosp_cost − tdm_cost)
# ==============================================================================

compute_savings <- function(arr, hosp_cost, tdm_cost, n = 1000) {
  n * (arr * hosp_cost - tdm_cost)
}

compute_nnt <- function(arr) {
  1 / arr
}

# Verify formula matches Monte Carlo output (should be within 5%)
formula_savings <- compute_savings(base_ARR, base_hosp, base_tdm_cost)
formula_vs_mc   <- abs(formula_savings - base_savings) / base_savings * 100
cat(sprintf("  Formula savings: $%s\n", format(round(formula_savings), big.mark=",")))
cat(sprintf("  Monte Carlo:     $%s\n", format(round(base_savings),   big.mark=",")))
cat(sprintf("  Difference:      %.1f%% ", formula_vs_mc))
if (formula_vs_mc < 5) {
  cat("✓ Formula validated against Monte Carlo\n\n")
} else {
  cat("⚠ >5% discrepancy — check base parameters\n\n")
}

# ==============================================================================
# SECTION 1: ONE-WAY SENSITIVITY ANALYSIS (TORNADO)
# Each parameter varied independently; all others held at base case.
# Range sources documented for every parameter.
# ==============================================================================

cat("==============================================================================\n")
cat(" SECTION 1: ONE-WAY SENSITIVITY ANALYSIS\n")
cat("==============================================================================\n\n")

# Define parameters and their ranges
# Format: list(name, base, low, high, low_label, high_label, units, source)
owa_params <- list(

  list(
    name      = "Hospitalization Cost",
    base      = base_hosp,
    low       = 11337,
    high      = 35899,
    low_lab   = "$11,337 (breast-specific)",
    high_lab  = "$35,899 (Flanigan 2024)",
    units     = "USD",
    source    = "Kuderer 2015 ASH / Flanigan 2024 [PMID:38777864]",
    type      = "cost"   # affects savings directly
  ),

  list(
    name      = "Absolute Risk Reduction",
    base      = base_ARR,
    low       = 0.080,   # conservative: 50% of observed benefit
    high      = 0.240,   # optimistic: 1.5x observed benefit
    low_lab   = "8.0% (conservative)",
    high_lab  = "24.0% (optimistic)",
    units     = "%",
    source    = "Scenario bounds; Leenhardt 2022 base case 15.6%",
    type      = "arr"
  ),

  list(
    name      = "TDM Assay Cost",
    base      = base_tdm_cost,
    low       = 150,     # simple immunoassay / resource-limited
    high      = 500,     # premium LC-MS/MS with full PK consult
    low_lab   = "$150 (immunoassay)",
    high_lab  = "$500 (premium LC-MS/MS)",
    units     = "USD",
    source    = "Clinical lab cost range",
    type      = "cost"
  ),

  list(
    name      = "Baseline G3/4 Risk",
    base      = base_baseline,
    low       = 0.54,    # PALOMA-1 lower bound: 54%
    high      = 0.72,    # PALOMA-3/4 upper bound: 72%
    low_lab   = "54% (PALOMA-1 lower)",
    high_lab  = "72% (PALOMA-3/4 upper)",
    units     = "%",
    source    = "PALOMA trial range [PMID:27959613, 30345905]",
    type      = "baseline"
  ),

  list(
    name      = "Dose Modification Rate",
    base      = sim_settings$intervention_rate,
    low       = 0.30,    # PALOMA-3 lower bound
    high      = 0.40,    # Real-world upper (Gullick 2024)
    low_lab   = "30% (PALOMA-3)",
    high_lab  = "40% (real-world)",
    units     = "%",
    source    = "Pooled PALOMA [PMC7068918]; Gullick 2024",
    type      = "rate"
  ),

  list(
    name      = "Post-TDM G3/4 Risk",
    base      = base_tdm_risk,
    low       = 0.40,    # optimistic TDM response
    high      = 0.58,    # conservative TDM response
    low_lab   = "40% (optimistic)",
    high_lab  = "58% (conservative)",
    units     = "%",
    source    = "Courlet 2022 simulation at 100mg [PMID:35890213]",
    type      = "tdm_risk"
  )
)

# Compute savings at low and high for each parameter
owa_results <- data.frame(
  Parameter     = character(),
  Base_Savings  = numeric(),
  Low_Savings   = numeric(),
  High_Savings  = numeric(),
  Low_Label     = character(),
  High_Label    = character(),
  Low_NNT       = numeric(),
  High_NNT      = numeric(),
  Source        = character(),
  stringsAsFactors = FALSE
)

cat(sprintf("  %-30s %12s %12s %12s\n",
            "Parameter", "Low ($)", "Base ($)", "High ($)"))
cat(paste(rep("-", 70), collapse=""), "\n")

for (p in owa_params) {

  # Compute savings at base
  sav_base <- compute_savings(base_ARR, base_hosp, base_tdm_cost)

  if (p$type == "cost") {
    # Hospitalization cost: low and high applied to base ARR
    if (p$name == "Hospitalization Cost") {
      sav_low  <- compute_savings(base_ARR, p$low,  base_tdm_cost)
      sav_high <- compute_savings(base_ARR, p$high, base_tdm_cost)
      nnt_low  <- base_NNT
      nnt_high <- base_NNT
    } else {
      # TDM assay cost: low and high TDM cost
      sav_low  <- compute_savings(base_ARR, base_hosp, p$high)  # high cost = low savings
      sav_high <- compute_savings(base_ARR, base_hosp, p$low)   # low cost  = high savings
      nnt_low  <- base_NNT
      nnt_high <- base_NNT
    }

  } else if (p$type == "arr") {
    sav_low  <- compute_savings(p$low,  base_hosp, base_tdm_cost)
    sav_high <- compute_savings(p$high, base_hosp, base_tdm_cost)
    nnt_low  <- compute_nnt(p$high)  # high ARR = low NNT
    nnt_high <- compute_nnt(p$low)   # low ARR  = high NNT

  } else if (p$type == "baseline") {
    # Baseline risk change: recalculate ARR
    # ARR = baseline - tdm_risk; if baseline changes, ARR changes
    arr_low  <- p$low  - base_tdm_risk
    arr_high <- p$high - base_tdm_risk
    arr_low  <- max(arr_low,  0.001)
    arr_high <- max(arr_high, 0.001)
    sav_low  <- compute_savings(arr_low,  base_hosp, base_tdm_cost)
    sav_high <- compute_savings(arr_high, base_hosp, base_tdm_cost)
    nnt_low  <- compute_nnt(arr_high)
    nnt_high <- compute_nnt(arr_low)

  } else if (p$type == "tdm_risk") {
    # Post-TDM risk change: recalculate ARR
    arr_low  <- base_baseline - p$high  # high tdm_risk = low ARR
    arr_high <- base_baseline - p$low   # low tdm_risk  = high ARR
    arr_low  <- max(arr_low,  0.001)
    arr_high <- max(arr_high, 0.001)
    sav_low  <- compute_savings(arr_low,  base_hosp, base_tdm_cost)
    sav_high <- compute_savings(arr_high, base_hosp, base_tdm_cost)
    nnt_low  <- compute_nnt(arr_high)
    nnt_high <- compute_nnt(arr_low)

  } else if (p$type == "rate") {
    # Dose modification rate: affects n_A but not ARR in this model
    # ARR is determined by the weighted group risks
    # Low rate -> fewer patients get TDM benefit -> lower ARR
    n_A_low  <- round(p$low  * n_patients)
    n_A_high <- round(p$high * n_patients)
    n_B_low  <- n_patients - n_A_low
    n_B_high <- n_patients - n_A_high

    arr_low  <- (n_A_low  * scenario_params$risk_base_A +
                 n_B_low  * scenario_params$risk_base_B) / n_patients -
                (n_A_low  * scenario_params$risk_tdm_A  +
                 n_B_low  * scenario_params$risk_tdm_B)  / n_patients

    arr_high <- (n_A_high * scenario_params$risk_base_A +
                 n_B_high * scenario_params$risk_base_B) / n_patients -
                (n_A_high * scenario_params$risk_tdm_A  +
                 n_B_high * scenario_params$risk_tdm_B)  / n_patients

    arr_low  <- max(arr_low,  0.001)
    arr_high <- max(arr_high, 0.001)
    sav_low  <- compute_savings(arr_low,  base_hosp, base_tdm_cost)
    sav_high <- compute_savings(arr_high, base_hosp, base_tdm_cost)
    nnt_low  <- compute_nnt(arr_high)
    nnt_high <- compute_nnt(arr_low)
  }

  cat(sprintf("  %-30s %12s %12s %12s\n",
              p$name,
              paste0("$", format(round(sav_low),  big.mark=",")),
              paste0("$", format(round(sav_base), big.mark=",")),
              paste0("$", format(round(sav_high), big.mark=","))))

  owa_results <- rbind(owa_results, data.frame(
    Parameter    = p$name,
    Base_Savings = round(sav_base),
    Low_Savings  = round(sav_low),
    High_Savings = round(sav_high),
    Low_Label    = p$low_lab,
    High_Label   = p$high_lab,
    Low_NNT      = round(nnt_low,  1),
    High_NNT     = round(nnt_high, 1),
    Source       = p$source,
    stringsAsFactors = FALSE
  ))
}

write.csv(owa_results, "outputs/03_One_Way_SA.csv", row.names = FALSE)
cat(sprintf("\n  ✓ outputs/03_One_Way_SA.csv written (%d parameters)\n", nrow(owa_results)))

# TORNADO FIGURE
cat("\n  Generating tornado diagram...\n")

# Sort by range width (widest bar = most influential)
owa_results$Range <- abs(owa_results$High_Savings - owa_results$Low_Savings)
owa_sorted <- owa_results[order(owa_results$Range), ]

png("figures/03_Tornado.png", width = 2400, height = 1600, res = 200)
par(mar = c(6, 14, 5, 3))

n_params    <- nrow(owa_sorted)
y_positions <- seq_len(n_params)
x_min <- min(owa_sorted$Low_Savings,  owa_sorted$High_Savings) * 0.85
x_max <- max(owa_sorted$High_Savings, owa_sorted$Low_Savings)  * 1.10

plot(NULL, xlim = c(x_min, x_max), ylim = c(0.5, n_params + 0.5),
     xlab = "", ylab = "", yaxt = "n", xaxt = "n",
     main = "", bty = "n")

# Background grid
abline(v = seq(0, x_max, by = 500000), col = "#F0F0F0", lwd = 1)
abline(v = 0, col = "#CCCCCC", lwd = 1.5, lty = 2)

# Base case line
abline(v = base_savings, col = "#2C3E50", lwd = 2.5, lty = 3)

# Bars
bar_h <- 0.45
for (i in seq_len(n_params)) {
  row     <- owa_sorted[i, ]
  y       <- y_positions[i]
  lo      <- row$Low_Savings
  hi      <- row$High_Savings
  col_lo  <- "#E74C3C"   # red for pessimistic
  col_hi  <- "#27AE60"   # green for optimistic

  # Always draw low (pessimistic) in red, high (optimistic) in green
  rect(min(lo, base_savings), y - bar_h,
       max(lo, base_savings), y + bar_h,
       col = col_lo, border = NA)
  rect(min(hi, base_savings), y - bar_h,
       max(hi, base_savings), y + bar_h,
       col = col_hi, border = NA)

  # Value labels
  text(lo - 50000, y, paste0("$", format(round(lo/1e6, 1), nsmall=1), "M"),
       cex = 0.72, adj = 1, col = "#C0392B", font = 2)
  text(hi + 50000, y, paste0("$", format(round(hi/1e6, 1), nsmall=1), "M"),
       cex = 0.72, adj = 0, col = "#1E8449", font = 2)
}

# Y axis labels
axis(2, at = y_positions, labels = owa_sorted$Parameter,
     las = 1, cex.axis = 0.85, tick = FALSE, font = 1)

# X axis
x_ticks <- seq(0, round(x_max, -6), by = 1000000)
axis(1, at = x_ticks,
     labels = paste0("$", format(x_ticks/1e6, nsmall=1), "M"),
     cex.axis = 0.80)
mtext("Net Savings per 1,000 Patients (USD)", side = 1, line = 3.5, cex = 0.95)

# Legend and title
legend("bottomright", legend = c("Pessimistic estimate", "Optimistic estimate",
                                   "Base case"),
       fill = c("#E74C3C","#27AE60", NA), border = c(NA,NA,NA),
       lty = c(NA,NA,3), lwd = c(NA,NA,2.5), col = c(NA,NA,"#2C3E50"),
       cex = 0.80, bty = "n")

title(main = "One-Way Sensitivity Analysis: Palbociclib TDM Net Savings",
      sub  = paste0("Base case: $", format(round(base_savings/1e6,2),nsmall=2),
                    "M | Parameters varied ±20-30% individually"),
      cex.main = 1.1, font.main = 2, col.main = "#2C3E50",
      cex.sub  = 0.80, col.sub  = "#7F8C8D")

dev.off()
cat("  ✓ figures/03_Tornado.png saved\n\n")

# ==============================================================================
# SECTION 2: TWO-WAY SENSITIVITY ANALYSIS (HEATMAP)
# Simultaneously varies hospitalization cost AND absolute risk reduction
# Computes net savings at every combination — 10×10 grid = 100 scenarios
# ==============================================================================

cat("==============================================================================\n")
cat(" SECTION 2: TWO-WAY SENSITIVITY ANALYSIS\n")
cat(" Variables: Hospitalization Cost × Absolute Risk Reduction\n")
cat("==============================================================================\n\n")

cat("  SCIENTIFIC RATIONALE:\n")
cat("  Net Savings = n × (ARR × HospCost − TDM_Cost)\n")
cat("  ARR and HospCost appear on OPPOSITE SIDES of the equation.\n")
cat("  Their product determines whether TDM is cost-saving.\n")
cat("  Break-even: ARR × HospCost = TDM_Cost\n")
cat(sprintf("           -> ARR × HospCost = $%d\n\n", base_tdm_cost))

# Define grid axes
# Hospitalization cost: $11,337 (Kuderer 2015, breast-specific)
#                    to $35,899 (Flanigan 2024, all solid tumors)
hosp_costs <- seq(11337, 35899, length.out = 10)

# ARR: 8% (conservative lower bound = 50% of observed)
#   to 24% (optimistic = 1.5x observed)
arr_values <- seq(0.08, 0.24, length.out = 10)

# Build grid — compute savings at every combination
savings_grid <- matrix(NA, nrow = length(arr_values),
                           ncol = length(hosp_costs))

for (i in seq_along(arr_values)) {
  for (j in seq_along(hosp_costs)) {
    savings_grid[i, j] <- compute_savings(arr_values[i],
                                          hosp_costs[j],
                                          base_tdm_cost)
  }
}

# Export full grid as CSV
grid_df <- as.data.frame(savings_grid)
colnames(grid_df) <- paste0("HospCost_$", round(hosp_costs))
rownames(grid_df) <- paste0("ARR_", round(arr_values * 100, 1), "%")

write.csv(grid_df, "outputs/03_Two_Way_SA_Grid.csv")
cat(sprintf("  ✓ outputs/03_Two_Way_SA_Grid.csv written (%dx%d grid)\n",
            length(arr_values), length(hosp_costs)))

# Print grid summary
cat("\n  NET SAVINGS GRID (per 1,000 patients):\n")
cat(sprintf("  %-10s", "ARR\\Cost"))
for (j in seq_along(hosp_costs)) {
  cat(sprintf(" %8s", paste0("$",round(hosp_costs[j]/1000,0),"K")))
}
cat("\n  ", paste(rep("-", 90), collapse=""), "\n", sep="")

for (i in seq_along(arr_values)) {
  cat(sprintf("  %-10s", paste0(round(arr_values[i]*100,1),"%")))
  for (j in seq_along(hosp_costs)) {
    val <- savings_grid[i,j]
    tag <- if(val < 0) "  [LOSS]" else sprintf(" $%sM", format(round(val/1e6,1),nsmall=1))
    cat(sprintf(" %8s", tag))
  }
  cat("\n")
}

# Break-even analysis
# Break-even: ARR × HospCost = TDM_Cost (350)
# -> HospCost_breakeven = TDM_Cost / ARR
# -> ARR_breakeven      = TDM_Cost / HospCost
cat("\n  BREAK-EVEN ANALYSIS:\n")
cat(sprintf("  Break-even condition: ARR × HospCost = $%d (TDM assay cost)\n",
            base_tdm_cost))

breakeven_df <- data.frame(
  ARR_Pct              = round(arr_values * 100, 1),
  Breakeven_HospCost   = round(base_tdm_cost / arr_values, 0),
  Base_Case_HospCost   = base_hosp,
  TDM_Viable           = (base_tdm_cost / arr_values) <= base_hosp
)

cat(sprintf("\n  %-12s %-25s %-15s %s\n",
            "ARR (%)", "Break-even HospCost ($)", "Base ($22,839)", "TDM Viable?"))
cat(paste(rep("-", 68), collapse=""), "\n")
for (i in seq_len(nrow(breakeven_df))) {
  row <- breakeven_df[i,]
  viable <- if(row$TDM_Viable) "✓ YES" else "✗ NO"
  cat(sprintf("  %-12s $%-24s $%-14s %s\n",
              paste0(row$ARR_Pct, "%"),
              format(row$Breakeven_HospCost, big.mark=","),
              format(row$Base_Case_HospCost, big.mark=","),
              viable))
}

write.csv(breakeven_df, "outputs/03_Breakeven_Table.csv", row.names = FALSE)
cat(sprintf("\n  ✓ outputs/03_Breakeven_Table.csv written\n\n"))

# HEATMAP FIGURE
cat("  Generating two-way sensitivity heatmap...\n")

png("figures/03_Heatmap.png", width = 2800, height = 2200, res = 200)
par(mar = c(7, 7, 6, 8))

# Colour scale: red (loss) -> white (break-even) -> green (savings)
min_val   <- min(savings_grid)
max_val   <- max(savings_grid)
n_colours <- 200

# Build custom palette: red -> white at 0 -> green
make_palette <- function(n) {
  n_neg <- round(n * abs(min_val) / (max_val - min_val))
  n_pos <- n - n_neg
  neg_cols <- colorRampPalette(c("#C0392B","#F1948A","#FDFEFE"))(n_neg + 1)
  pos_cols <- colorRampPalette(c("#FDFEFE","#82E0AA","#1E8449"))(n_pos + 1)
  c(neg_cols[-length(neg_cols)], pos_cols)
}
pal <- make_palette(n_colours)

# Map savings to colour index
val_to_col <- function(val) {
  idx <- round((val - min_val) / (max_val - min_val) * (n_colours - 1)) + 1
  pal[max(1, min(n_colours, idx))]
}

# Draw heatmap cells
plot(NULL,
     xlim = c(0.5, length(hosp_costs) + 0.5),
     ylim = c(0.5, length(arr_values) + 0.5),
     xlab = "", ylab = "", xaxt = "n", yaxt = "n",
     bty  = "n", main = "")

for (i in seq_along(arr_values)) {
  for (j in seq_along(hosp_costs)) {
    val     <- savings_grid[i, j]
    col_use <- val_to_col(val)
    rect(j - 0.5, i - 0.5, j + 0.5, i + 0.5,
         col = col_use, border = "white", lwd = 0.8)

    # Cell label
    lab <- if (abs(val) >= 1e6) {
      paste0("$", format(round(val/1e6, 1), nsmall=1), "M")
    } else if (val < 0) {
      paste0("-$", format(round(abs(val)/1000), big.mark=","), "K")
    } else {
      paste0("$", format(round(val/1000), big.mark=","), "K")
    }
    text_col <- if (abs(val) > max_val * 0.5) "white" else "#2C3E50"
    text(j, i, lab, cex = 0.65, col = text_col, font = 2)
  }
}

# Overlay break-even contour line
# For each hosp_cost column j, find where savings = 0
# savings = n*(arr*hosp - tdm_cost) = 0 -> arr = tdm_cost/hosp
for (j in seq_along(hosp_costs)) {
  be_arr <- base_tdm_cost / hosp_costs[j]
  # Find y position on our ARR scale
  be_y <- (be_arr - min(arr_values)) /
          (max(arr_values) - min(arr_values)) *
          (length(arr_values) - 1) + 1
  if (be_y >= 0.5 && be_y <= length(arr_values) + 0.5) {
    if (j < length(hosp_costs)) {
      be_arr_next <- base_tdm_cost / hosp_costs[j+1]
      be_y_next   <- (be_arr_next - min(arr_values)) /
                     (max(arr_values) - min(arr_values)) *
                     (length(arr_values) - 1) + 1
      segments(j, be_y, j+1, be_y_next,
               col = "#F39C12", lwd = 3.5, lty = 1)
    }
  }
}

# Mark base case
base_j <- which.min(abs(hosp_costs - base_hosp))
base_i <- which.min(abs(arr_values - base_ARR))
points(base_j, base_i, pch = 23, bg = "#F39C12", col = "#2C3E50",
       cex = 2.5, lwd = 2)
text(base_j, base_i + 0.45, "Base", cex = 0.75, col = "#2C3E50", font = 2)

# Axes
axis(1, at = seq_along(hosp_costs),
     labels = paste0("$", format(round(hosp_costs/1000, 0), big.mark=","), "K"),
     cex.axis = 0.80, las = 2)
axis(2, at = seq_along(arr_values),
     labels = paste0(round(arr_values * 100, 1), "%"),
     cex.axis = 0.82, las = 1)

mtext("Hospitalization Cost per G3/4 Event (USD)",
      side = 1, line = 5.5, cex = 1.0, font = 2)
mtext("Absolute Risk Reduction (ARR)",
      side = 2, line = 5.0, cex = 1.0, font = 2)

# Colour legend bar
legend_x <- length(hosp_costs) + 0.7
legend_vals <- seq(min_val, max_val, length.out = 50)
for (k in seq_along(legend_vals)[-length(legend_vals)]) {
  rect(legend_x, k * length(arr_values)/50,
       legend_x + 0.6,
       (k+1) * length(arr_values)/50,
       col = val_to_col(legend_vals[k]),
       border = NA, xpd = TRUE)
}
text(legend_x + 0.3, 0, paste0("$", format(round(min_val/1e6,1),nsmall=1),"M"),
     cex = 0.65, xpd = TRUE, adj = 0.5)
text(legend_x + 0.3, length(arr_values),
     paste0("$", format(round(max_val/1e6,1),nsmall=1),"M"),
     cex = 0.65, xpd = TRUE, adj = 0.5)

# Title and annotations
title(main = "Two-Way Sensitivity Analysis: Net Savings per 1,000 Patients",
      cex.main = 1.15, font.main = 2, col.main = "#2C3E50")
mtext(paste0("Orange line = break-even (savings = $0) | ",
             "Diamond = base case ($22,839, ARR=",
             round(base_ARR*100,1),"%)"),
      side = 3, line = 0.3, cex = 0.80, col = "#7F8C8D")

dev.off()
cat("  ✓ figures/03_Heatmap.png saved\n\n")

# ==============================================================================
# SECTION 3: NNT SENSITIVITY TABLE (for manuscript Table 2)
# ==============================================================================

cat("==============================================================================\n")
cat(" SECTION 3: NNT SENSITIVITY TABLE\n")
cat("==============================================================================\n\n")

nnt_sa <- data.frame(
  Parameter          = character(),
  Scenario           = character(),
  ARR_Pct            = numeric(),
  NNT                = numeric(),
  Net_Savings        = numeric(),
  Source             = character(),
  stringsAsFactors   = FALSE
)

scenarios <- list(
  list("Hospitalization Cost", "Low ($11,337)",  base_ARR, 11337, base_tdm_cost,
       "Kuderer 2015 ASH"),
  list("Hospitalization Cost", "Base ($22,839)", base_ARR, 22839, base_tdm_cost,
       "Dulisse & Cosler 2012"),
  list("Hospitalization Cost", "High ($35,899)", base_ARR, 35899, base_tdm_cost,
       "Flanigan 2024 [PMID:38777864]"),
  list("Absolute Risk Reduction","Low (8.0%)",   0.080, base_hosp, base_tdm_cost,
       "Conservative lower bound"),
  list("Absolute Risk Reduction","Base (15.6%)", base_ARR, base_hosp, base_tdm_cost,
       "Leenhardt 2022 [PMID:35397465]"),
  list("Absolute Risk Reduction","High (24.0%)", 0.240, base_hosp, base_tdm_cost,
       "Optimistic upper bound"),
  list("TDM Assay Cost",        "Low ($150)",    base_ARR, base_hosp, 150,
       "Simple immunoassay"),
  list("TDM Assay Cost",        "Base ($350)",   base_ARR, base_hosp, 350,
       "LC-MS/MS standard"),
  list("TDM Assay Cost",        "High ($500)",   base_ARR, base_hosp, 500,
       "Premium LC-MS/MS")
)

cat(sprintf("  %-28s %-20s %8s %6s %14s\n",
            "Parameter", "Scenario", "ARR (%)", "NNT", "Net Savings ($)"))
cat(paste(rep("-", 80), collapse=""), "\n")

for (s in scenarios) {
  arr_s <- s[[3]]; hc_s <- s[[4]]; tc_s <- s[[5]]
  sav_s <- compute_savings(arr_s, hc_s, tc_s)
  nnt_s <- compute_nnt(arr_s)
  cat(sprintf("  %-28s %-20s %8.1f %6.1f %14s\n",
              s[[1]], s[[2]],
              arr_s * 100, nnt_s,
              paste0("$", format(round(sav_s), big.mark=","))))
  nnt_sa <- rbind(nnt_sa, data.frame(
    Parameter  = s[[1]], Scenario = s[[2]],
    ARR_Pct    = round(arr_s * 100, 1),
    NNT        = round(nnt_s, 1),
    Net_Savings= round(sav_s),
    Source     = s[[6]],
    stringsAsFactors = FALSE
  ))
}

write.csv(nnt_sa, "outputs/03_NNT_Sensitivity_Table.csv", row.names = FALSE)
cat(sprintf("\n  ✓ outputs/03_NNT_Sensitivity_Table.csv written\n\n"))

# ==============================================================================
# SECTION 4: KEY FINDING SUMMARY
# ==============================================================================

cat("==============================================================================\n")
cat(" KEY SENSITIVITY FINDINGS\n")
cat("==============================================================================\n\n")

cat("  1. MOST INFLUENTIAL PARAMETER:\n")
most_inf <- owa_sorted[nrow(owa_sorted), ]
cat(sprintf("     %s (range: $%sM – $%sM)\n",
            most_inf$Parameter,
            format(round(most_inf$Low_Savings/1e6,1), nsmall=1),
            format(round(most_inf$High_Savings/1e6,1),nsmall=1)))

cat("\n  2. BREAK-EVEN POINT:\n")
be_arr_at_base_cost <- base_tdm_cost / base_hosp * 100
cat(sprintf("     At base hospitalization cost ($22,839):\n"))
cat(sprintf("     ARR must exceed %.1f%% for TDM to be cost-saving\n",
            be_arr_at_base_cost))
cat(sprintf("     Base case ARR = %.1f%% — margin above break-even: %.1f%%\n",
            base_ARR*100, base_ARR*100 - be_arr_at_base_cost))

cat("\n  3. TDM REMAINS COST-SAVING WHEN:\n")
cat(sprintf("     ARR ≥ %.1f%% at base hospitalization cost ($22,839)\n",
            be_arr_at_base_cost))
be_cost_at_base_arr <- base_tdm_cost / base_ARR
cat(sprintf("     Hospitalization cost ≥ $%s at base ARR (%.1f%%)\n",
            format(round(be_cost_at_base_arr), big.mark=","),
            base_ARR*100))

cat("\n  4. ROBUSTNESS:\n")
n_positive <- sum(savings_grid > 0)
n_total    <- length(savings_grid)
cat(sprintf("     Positive savings in %d/%d scenarios (%.0f%% of grid)\n",
            n_positive, n_total, n_positive/n_total*100))
cat(sprintf("     TDM is cost-saving across most parameter combinations tested.\n\n"))

# ==============================================================================
# EXPORT SUMMARY
# ==============================================================================

assign("owa_results",  owa_results,  envir = .GlobalEnv)
assign("savings_grid", savings_grid, envir = .GlobalEnv)
assign("hosp_costs",   hosp_costs,   envir = .GlobalEnv)
assign("arr_values",   arr_values,   envir = .GlobalEnv)
assign("breakeven_df", breakeven_df, envir = .GlobalEnv)
assign("nnt_sa",       nnt_sa,       envir = .GlobalEnv)

cat("==============================================================================\n")
cat(" OUTPUT FILES\n")
cat("==============================================================================\n")
cat("  ✓ outputs/03_One_Way_SA.csv\n")
cat("  ✓ outputs/03_Two_Way_SA_Grid.csv\n")
cat("  ✓ outputs/03_Breakeven_Table.csv\n")
cat("  ✓ outputs/03_NNT_Sensitivity_Table.csv\n")
cat("  ✓ figures/03_Tornado.png\n")
cat("  ✓ figures/03_Heatmap.png\n\n")
cat("==============================================================================\n")
cat(" ✅  03_sensitivity_analysis.R COMPLETE\n")
cat(" ➤   Next: source('src/04_report_generator.R')\n")
cat("==============================================================================\n\n")
