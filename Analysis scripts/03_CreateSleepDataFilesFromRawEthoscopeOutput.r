# ============================================
# CREATE SLEEP DATA FILES - PER ETHOSCOPE
# ============================================

source("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/02_newSleepDataEtho.r")

RDS_FILE <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/all_ethoscopes_merged_06APR_10sec.rds"
OUTPUT_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/"

FOCAL_TUBES <- c(1, 3, 5, 7, 9)
YOKED_TUBES <- c(12, 14, 16, 18, 20)

# Load data
run1 <- readRDS(RDS_FILE)
ethoscope_names <- names(run1)

cat("Ethoscopes found:", paste(ethoscope_names, collapse = ", "), "\n\n")

# Process each ethoscope separately
for (eth_name in ethoscope_names) {
  cat("Processing", eth_name, "...\n")
  
  eth_data <- as.data.frame(run1[[eth_name]])
  if (ncol(eth_data) == 0) {
    cat("  ⚠ No data (empty entry in RDS), skipping\n\n")
    next
  }
  eth_cols <- colnames(eth_data)
  time_data <- eth_data[, 1, drop = FALSE]
  
  # Extract focal tubes
  focal_list <- list(time_data[,1])
  focal_names <- c("Time")
  for (tube in FOCAL_TUBES) {
    col <- paste0("Ind", sprintf("%02d", tube))
    if (col %in% eth_cols) {
      focal_list[[length(focal_list) + 1]] <- eth_data[, col]
      focal_names <- c(focal_names, paste0("T", tube))
    }
  }
  
  # Extract yoked tubes
  yoked_list <- list(time_data[,1])
  yoked_names <- c("Time")
  for (tube in YOKED_TUBES) {
    col <- paste0("Ind", sprintf("%02d", tube))
    if (col %in% eth_cols) {
      yoked_list[[length(yoked_list) + 1]] <- eth_data[, col]
      yoked_names <- c(yoked_names, paste0("T", tube))
    }
  }
  
  n_focal <- length(focal_names) - 1
  n_yoked <- length(yoked_names) - 1
  
  cat("  Focal tubes:", n_focal, "| Yoked tubes:", n_yoked, "\n")
  
  if (n_focal == 0) {
    cat("  ⚠ No focal tubes found, skipping focal\n")
  } else {
    focal.df <- as.data.frame(do.call(cbind, focal_list))
    colnames(focal.df) <- focal_names
    focal.sleep <- newSleepDataEtho(data = focal.df, sleep.def = 5, bin = 30, t.cycle = 24)
    colnames(focal.sleep) <- c("ZT", focal_names[2:(n_focal + 1)])
    write.table(focal.sleep, paste0(OUTPUT_DIR, "Sleep_", eth_name, "_Focal.txt"), 
                quote = FALSE, row.names = FALSE, sep = "\t")
    cat("  ✓ Saved: Sleep_", eth_name, "_Focal.txt\n", sep = "")
  }
  
  if (n_yoked == 0) {
    cat("  ⚠ No yoked tubes found, skipping yoked\n")
  } else {
    yoked.df <- as.data.frame(do.call(cbind, yoked_list))
    colnames(yoked.df) <- yoked_names
    yoked.sleep <- newSleepDataEtho(data = yoked.df, sleep.def = 5, bin = 30, t.cycle = 24)
    colnames(yoked.sleep) <- c("ZT", yoked_names[2:(n_yoked + 1)])
    write.table(yoked.sleep, paste0(OUTPUT_DIR, "Sleep_", eth_name, "_Yoked.txt"), 
                quote = FALSE, row.names = FALSE, sep = "\t")
    cat("  ✓ Saved: Sleep_", eth_name, "_Yoked.txt\n", sep = "")
  }
  
  cat("\n")
}

cat("Done! Files ready for plotting.\n")
