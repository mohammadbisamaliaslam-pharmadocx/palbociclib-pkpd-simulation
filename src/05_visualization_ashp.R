# ==============================================================================
# ASHP POSTER VISUALIZATION GENERATOR
# Generates 6 High-Quality Figures for the Poster
# ==============================================================================
library(ggplot2)
library(gridExtra)

# Load Data
metrics <- read.csv("outputs/04_Summary_Table.csv")
full_data <- read.csv("outputs/02_Simulation_Results_Full.csv")

# Extract Key Values
risk_base <- metrics$Value[metrics$Metric == "Baseline Risk (%)"]
risk_tdm  <- metrics$Value[metrics$Metric == "TDM Risk (%)"]
nnt_val   <- metrics$Value[metrics$Metric == "NNT"]
savings   <- metrics$Value[metrics$Metric == "Savings ($)"]

# FIGURE 1: RISK REDUCTION (Bar Plot)
p1 <- ggplot(data.frame(Group=c("Standard Dosing", "TDM-Guided"), Risk=c(risk_base, risk_tdm)), aes(x=Group, y=Risk, fill=Group)) +
  geom_bar(stat="identity", width=0.6) +
  geom_text(aes(label=paste0(round(Risk,1),"%")), vjust=-0.5, size=6, fontface="bold") +
  scale_fill_manual(values=c("#E74C3C", "#2ECC71")) +
  ylim(0, 100) +
  labs(title="Grade 3/4 Neutropenia Risk", y="Incidence (%)", x="") +
  theme_minimal(base_size = 14) + theme(legend.position="none")
ggsave("outputs/ASHP_01_Risk_Reduction.png", p1, width=6, height=5)

# FIGURE 2: NNT VISUAL (Text Graphic)
png("outputs/ASHP_02_NNT_Visual.png", width=600, height=400)
par(mar=c(0,0,0,0))
plot(0:10, 0:10, type="n", axes=FALSE, xlab="", ylab="")
rect(0,0,10,10, col="#f0f8ff", border=NA)
text(5, 7, "Number Needed to Treat", cex=2.5, font=2, col="#2c3e50")
text(5, 5, round(nnt_val, 1), cex=8, font=2, col="#e67e22")
text(5, 3, "Patients screened to prevent\n1 severe toxicity event", cex=1.5, col="#7f8c8d")
dev.off()

# FIGURE 3: CMIN DISTRIBUTION (Histogram)
p3 <- ggplot(full_data, aes(x=Cmin_Base)) +
  geom_histogram(fill="#3498db", color="white", bins=30, alpha=0.7) +
  geom_vline(xintercept=100, linetype="dashed", color="red", size=1.2) +
  annotate("text", x=120, y=50, label="TDM Threshold\n(100 ng/mL)", color="red", hjust=0) +
  labs(title="Distribution of Cmin Levels", x="Concentration (ng/mL)", y="Count") +
  theme_minimal(base_size = 14)
ggsave("outputs/ASHP_03_Cmin_Distribution.png", p3, width=7, height=5)

# FIGURE 4: ECONOMIC IMPACT (Bar Plot)
p4 <- ggplot(data.frame(Metric=c("Net Savings"), Value=c(savings)), aes(x=Metric, y=Value)) +
  geom_bar(stat="identity", fill="#27ae60", width=0.5) +
  geom_text(aes(label=paste0("$", formatC(Value, format="d", big.mark=","))), vjust=-0.5, size=6, fontface="bold") +
  labs(title="Total Cost Savings (per 1,000 patients)", y="USD", x="") +
  theme_minimal(base_size = 14)
ggsave("outputs/ASHP_04_Economic_Impact.png", p4, width=6, height=5)

# FIGURE 5: DOSE ADJUSTMENT (Pie Chart)
dose_red_count <- sum(full_data$TDM_Flag)
dose_keep_count <- nrow(full_data) - dose_red_count
df_pie <- data.frame(Group=c("Dose Reduced (100mg)", "Maintained (125mg)"), Count=c(dose_red_count, dose_keep_count))
p5 <- ggplot(df_pie, aes(x="", y=Count, fill=Group)) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  scale_fill_manual(values=c("#e67e22", "#95a5a6")) +
  geom_text(aes(label = paste0(round(Count/10,1), "%")), position = position_stack(vjust = 0.5), color = "white", size=5) +
  labs(title="Dose Adjustment Required", x="", y="") +
  theme_void(base_size = 14)
ggsave("outputs/ASHP_05_Dose_Adjustment.png", p5, width=6, height=5)

# FIGURE 6: CASES PREVENTED (Bar)
cases_base <- sum(full_data$Risk_Base)
cases_tdm <- sum(full_data$Risk_TDM)
p6 <- ggplot(data.frame(Scenario=c("Baseline", "With TDM"), Cases=c(cases_base, cases_tdm)), aes(x=Scenario, y=Cases, fill=Scenario)) +
  geom_bar(stat="identity", width=0.6) +
  geom_text(aes(label=round(Cases,0)), vjust=-0.5, size=6) +
  scale_fill_manual(values=c("#c0392b", "#2980b9")) +
  labs(title="Neutropenia Cases (Grade 3/4)", y="Number of Patients", x="") +
  theme_minimal(base_size = 14) + theme(legend.position="none")
ggsave("outputs/ASHP_06_Cases_Prevented.png", p6, width=6, height=5)

message("✅ ALL 6 ASHP FIGURES GENERATED SUCCESSFULLY")
