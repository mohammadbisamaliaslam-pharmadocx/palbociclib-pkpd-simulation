# ==============================================================================
# FINAL ASHP POSTER GENERATOR
# Combines all outputs into a print-ready PDF
# ==============================================================================
if(!require(grid)) install.packages("grid")
if(!require(png)) install.packages("png")
library(grid)
library(png)

# 1. SETUP
img_risk     <- "outputs/ASHP_01_Risk_Reduction.png"
img_cmin     <- "outputs/ASHP_03_Cmin_Distribution.png"
img_cases    <- "outputs/ASHP_06_Cases_Prevented.png"
img_dose     <- "outputs/ASHP_05_Dose_Adjustment.png"
img_nnt      <- "outputs/ASHP_02_NNT_Visual.png"
img_cost     <- "outputs/ASHP_04_Economic_Impact.png"

pdf("outputs/FINAL_ASHP_POSTER.pdf", width = 48, height = 36)
grid.newpage()

col_sidebar  <- "#002855"
col_center   <- "#FFFFFF"
col_header   <- "#FFD700"
col_accent   <- "#27AE60"

# Background
grid.rect(x=0, y=0, width=0.25, height=1, just=c(0,0), gp=gpar(fill=col_sidebar, col=NA))
grid.rect(x=0.25, y=0, width=0.50, height=1, just=c(0,0), gp=gpar(fill=col_center, col=NA))
grid.rect(x=0.75, y=0, width=0.25, height=1, just=c(0,0), gp=gpar(fill=col_sidebar, col=NA))

# Title
grid.text("Therapeutic Drug Monitoring of Palbociclib:", 
          x=0.5, y=0.955, gp=gpar(col="black", fontsize=64, fontface="bold"), just="center")
grid.text("A PALOMA-Calibrated Population PK-PD Analysis", 
          x=0.5, y=0.915, gp=gpar(col="black", fontsize=56, fontface="bold"), just="center")
grid.text("Mohammad Bisam Ali Aslam | Akhtar Saeed College of Pharmacy (ASCP)", 
          x=0.5, y=0.875, gp=gpar(col="#444444", fontsize=38, fontface="italic"), just="center")

# Impact boxes
grid.rect(x=0.5, y=0.82, width=0.48, height=0.075, gp=gpar(fill="#E8F8F5", col=col_accent, lwd=6))
grid.text("TDM Prevents 158 Grade 3/4 Neutropenia Cases per 1,000 Patients", 
          x=0.5, y=0.84, gp=gpar(col=col_accent, fontsize=44, fontface="bold"), just="center")
grid.text("NNT = 6.4  |  Absolute Risk Reduction = 15.8%", 
          x=0.5, y=0.80, gp=gpar(col=col_accent, fontsize=42, fontface="bold"), just="center")

grid.rect(x=0.5, y=0.74, width=0.48, height=0.055, gp=gpar(fill="#FFF9E6", col="#D4A500", lwd=4))
grid.text("Economic Benefit: ~$3.4M Saved per 1,000 Patients", 
          x=0.5, y=0.74, gp=gpar(col="#333333", fontsize=40, fontface="bold"), just="center")

# IMAGES
w_fig <- 0.22; h_fig <- 0.16
if(file.exists(img_risk)) grid.raster(readPNG(img_risk), x=0.375, y=0.62, width=w_fig, height=h_fig)
grid.text("Fig 1: Risk Reduction", x=0.375, y=0.53, gp=gpar(fontsize=26, fontface="bold"))
if(file.exists(img_cmin)) grid.raster(readPNG(img_cmin), x=0.625, y=0.62, width=w_fig, height=h_fig)
grid.text("Fig 2: Cmin Distribution", x=0.625, y=0.53, gp=gpar(fontsize=26, fontface="bold"))
if(file.exists(img_cases)) grid.raster(readPNG(img_cases), x=0.375, y=0.42, width=w_fig, height=h_fig)
grid.text("Fig 3: Cases Prevented", x=0.375, y=0.33, gp=gpar(fontsize=26, fontface="bold"))
if(file.exists(img_dose)) grid.raster(readPNG(img_dose), x=0.625, y=0.42, width=w_fig, height=h_fig)
grid.text("Fig 4: Dose Adjustments", x=0.625, y=0.33, gp=gpar(fontsize=26, fontface="bold"))
if(file.exists(img_nnt)) grid.raster(readPNG(img_nnt), x=0.375, y=0.22, width=w_fig, height=h_fig)
grid.text("Fig 5: NNT Visualization", x=0.375, y=0.13, gp=gpar(fontsize=26, fontface="bold"))
if(file.exists(img_cost)) grid.raster(readPNG(img_cost), x=0.625, y=0.22, width=w_fig, height=h_fig)
grid.text("Fig 6: Economic Impact", x=0.625, y=0.13, gp=gpar(fontsize=26, fontface="bold"))

# SIDEBARS
# (Simplified for brevity in file saving, but includes key text)
y_pos <- 0.94
grid.text("BACKGROUND", x=0.02, y=y_pos, gp=gpar(col=col_header, fontsize=50, fontface="bold"), just="left")
grid.text("• Palbociclib PK variability: CV 45%", x=0.025, y=y_pos-0.07, gp=gpar(col="white", fontsize=34), just="left")
grid.text("• Standard 125 mg: 66% Grade 3/4", x=0.025, y=y_pos-0.112, gp=gpar(col="white", fontsize=34), just="left")
grid.text("• TDM targets Cmin < 100 ng/mL", x=0.025, y=y_pos-0.154, gp=gpar(col="white", fontsize=34), just="left")

grid.text("RESULTS", x=0.76, y=y_pos, gp=gpar(col=col_header, fontsize=50, fontface="bold"), just="left")
grid.text("Baseline Risk: 65.9%", x=0.765, y=y_pos-0.07, gp=gpar(col="white", fontsize=34), just="left")
grid.text("TDM Risk: 50.2%", x=0.765, y=y_pos-0.112, gp=gpar(col="white", fontsize=34), just="left")
grid.text("NNT: 6.4 ★ EXCELLENT", x=0.765, y=y_pos-0.154, gp=gpar(col="white", fontsize=34), just="left")

# Footer
grid.text("ASHP Midyear Meeting 2026 | GitHub: mohammadbisamaliaslam-pharmadocx/palbociclib-pkpd-simulation", 
          x=0.5, y=0.02, gp=gpar(col="#AAAAAA", fontsize=26), just="center")

dev.off()
cat("✅ PDF Poster Generated: outputs/FINAL_ASHP_POSTER.pdf")
