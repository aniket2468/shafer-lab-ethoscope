# ============================================
# SLEEP PROFILE PLOT - LD CYCLE WITH SD PERIOD
# ============================================

library(data.table)

INPUT_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/"
OUTPUT_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/"

# Read averaged data
focal <- fread(paste0(INPUT_DIR, "Female_Sleep_Average_Focal.txt"))
yoked <- fread(paste0(INPUT_DIR, "Female_Sleep_Average_Yoked.txt"))

# Convert 30-min bins to 60-min bins (sum pairs)
n_rows <- nrow(focal)
n_hours <- floor(n_rows / 2)

focal_60 <- numeric(n_hours)
yoked_60 <- numeric(n_hours)
zt_60 <- numeric(n_hours)

for (i in 1:n_hours) {
  idx1 <- (i - 1) * 2 + 1
  idx2 <- i * 2
  focal_60[i] <- sum(focal$Focal_Avg[idx1:idx2], na.rm = TRUE)
  yoked_60[i] <- sum(yoked$Yoked_Avg[idx1:idx2], na.rm = TRUE)
  zt_60[i] <- focal$ZT[idx1]
}

# Create x-axis (hours from start)
x <- 1:n_hours

# Define periods (each 24 hours = 24 bins in 60-min data)
baseline_end <- 24
sd_end <- 48
recovery_end <- min(72, n_hours)

# Set up plot colors
focal_col <- "red"
yoked_col <- "blue"

# Output to PDF
pdf(paste0(OUTPUT_DIR, "Female_Sleep_Profile_Plot.pdf"), width = 12, height = 5)

par(mar = c(4, 5, 2, 2))

# Create empty plot
plot(x, focal_60, type = "n", 
     ylim = c(0, 60), xlim = c(1, n_hours),
     xlab = "", ylab = "Sleep (minutes/60-min)",
     xaxt = "n", las = 1, cex.lab = 1.2)

# Add dark period shading (ZT 12-24 = dark period)
# Experiment starts at ZT 0, so:
# Hours 1-12 = light (ZT 0-12), Hours 13-24 = dark (ZT 12-24)
for (day in 0:5) {
  dark_start <- day * 24 + 12 
  dark_end <- day * 24 + 24 
  if (dark_start <= n_hours) {
    rect(dark_start, 0, min(dark_end, n_hours + 0.5), 60, col = "gray70", border = NA)
  }
}

# Add red SD period bar on x-axis (day 2 = hours 25-48)
rect(baseline_end, -2.3, sd_end, -4.1, col = "red", border = NA, xpd = TRUE)

# Add lines
lines(x, focal_60, col = focal_col, lwd = 1.3)
lines(x, yoked_60, col = yoked_col, lwd = 1.3)

# Add box
box()

# Add x-axis with day markers
axis(1, at = c(12, 36, 60, 84, 108, 132), labels = c("", "", "", "", "", ""), tick = TRUE)
axis(1, at = c(1, 24, 48, 72, 96, 120, 144), labels = FALSE, tick = TRUE, tcl = -0.3)

# Add labels
text(12, -8, "Baseline", xpd = TRUE, cex = 1)
text(36, -8, "Sleep Deprivation", xpd = TRUE, cex = 1)
text(60, -8, "Recovery", xpd = TRUE, cex = 1)

# Add title annotation
mtext("Ethoscope          220-s Trigger          Canton-S", side = 3, line = 0.5, cex = 1)

# Add legend
legend("topleft", legend = c("Focal", "Yoked"), 
       col = c(focal_col, yoked_col), lwd = 2, 
       bty = "n", cex = 1)

dev.off()

cat("✓ Created: Sleep_Profile_Plot.pdf\n")
