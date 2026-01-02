# ============================================================================
# COMPLETION MESSAGE
# ============================================================================

end_time <- Sys.time()
elapsed_time <- difftime(end_time, start_time, units = "mins")

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║                                                                    ║\n")
cat("║                    ANALYSIS COMPLETED SUCCESSFULLY                ║\n")
cat("║                                                                    ║\n")
cat(sprintf("║   Total Time: %.1f minutes                                    ║\n", as.numeric(elapsed_time)))
cat("║                                                                    ║\n")
cat("║   Output Location: results/ folder                                ║\n")
cat("║   Main Report: results/ANALYSIS_REPORT.md                         ║\n")
cat("║                                                                    ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("Next Steps:\n")
cat("  1. Open results/ANALYSIS_REPORT.md for full analysis\n")
cat("  2. Review PNG figures in results/ folder\n")
cat("  3. Check results/summary_table.csv for key metrics\n")
cat("  4. Share findings with stakeholders\n\n")

