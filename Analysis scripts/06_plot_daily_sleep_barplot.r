# PLOT DAILY SLEEP SUMMARY - BAR CHART

library(data.table)
library(ggplot2)

setwd("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/")
OUTPUT_DIR <- "Analysis scripts/analysis_output/"

# Run daily_sleep_summary.r first to get results
source("Analysis scripts/daily_sleep_summary.r")

# Prepare data for plotting
plot_data <- melt(results, id.vars = c("eth", "type", "pair"), 
                  measure.vars = c("base", "sd", "rec1", "rec2", "rec3", "rec4"),
                  variable.name = "period", value.name = "sleep")

# Add sex column
plot_data[, sex := ifelse(eth %in% c("Eth008", "Eth010"), "Male", "Female")]

# Calculate mean and SEM per group
summary_data <- plot_data[, .(
  mean = mean(sleep, na.rm = TRUE),
  sem = sd(sleep, na.rm = TRUE) / sqrt(.N)
), by = .(sex, type, period)]

# Set factor order
summary_data[, period := factor(period, levels = c("base", "sd", "rec1", "rec2", "rec3", "rec4"),
                                 labels = c("Baseline", "SD", "Rec1", "Rec2", "Rec3", "Rec4"))]

# Create plot for each sex
for (s in c("Male", "Female")) {
  p <- ggplot(summary_data[sex == s], aes(x = period, y = mean, fill = type)) +
    geom_bar(stat = "identity", position = position_dodge(0.8), width = 0.7) +
    geom_errorbar(aes(ymin = mean - sem, ymax = mean + sem),
                  position = position_dodge(0.8), width = 0.2) +
    scale_fill_manual(values = c("Focal" = "red", "Yoked" = "blue")) +
    labs(title = paste(s, "Daily Sleep Summary"),
         x = "Period", y = "Sleep (minutes/24h)", fill = "") +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 16, face = "bold"),
      axis.text = element_text(size = 12),
      legend.position = "top"
    )
  
  ggsave(paste0(OUTPUT_DIR, s, "_Daily_Sleep_BarPlot.pdf"), p, width = 10, height = 6)
  cat("✓ Created:", s, "_Daily_Sleep_BarPlot.pdf\n")
}
