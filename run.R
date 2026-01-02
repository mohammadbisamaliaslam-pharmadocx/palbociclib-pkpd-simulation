# One-command execution
source("run.R")

# Then immediately access results
cat(readLines("outputs/22_Final_Health_Economic_Report.md"))
tdm <- read.csv("outputs/10_TDM_Recommendations.csv")

