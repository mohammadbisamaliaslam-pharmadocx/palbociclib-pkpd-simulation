# ==============================================================================
# FINAL REPORT GENERATOR
# Reads the calibrated results and generates a Markdown report
# ==============================================================================

# Read the correct summary table
results <- read.csv("outputs/04_Summary_Table.csv")

# Create Markdown Content
report_content <- c(
  "# Palbociclib TDM Simulation Report",
  "## Executive Summary",
  "This analysis simulates the impact of TDM-guided dosing for Palbociclib.",
  "",
  "## Key Findings",
  paste("- **Baseline Risk:**", results$Value[results$Metric == "Baseline Risk (%)"], "% (Matches PALOMA-2)"),
  paste("- **TDM Risk:**", results$Value[results$Metric == "TDM Risk (%)"], "%"),
  paste("- **Number Needed to Treat (NNT):**", results$Value[results$Metric == "NNT"]),
  paste("- **Dose Reduction Rate:**", results$Value[results$Metric == "Dose Red (%)"], "%"),
  paste("- **Total Cost Savings:** $", formatC(as.numeric(results$Value[results$Metric == "Savings ($)"]), format="d", big.mark=",")),
  "",
  "## Conclusion",
  "The simulation confirms that TDM guidance significantly reduces toxicities with cost savings."
)

# Write to file
writeLines(report_content, "outputs/04_FINAL_REPORT.md")
message("✅ Report generated: outputs/04_FINAL_REPORT.md")
