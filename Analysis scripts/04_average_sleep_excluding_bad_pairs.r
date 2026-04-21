# ============================================
# CREATE AVERAGE SLEEP FILES (EXCLUDING BAD PAIRS)
# ============================================

library(data.table)

INPUT_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/"
OUTPUT_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/"

# Pair mapping: pair 1 = T1/T12, pair 2 = T3/T14, pair 3 = T5/T16, pair 4 = T7/T18, pair 5 = T9/T20
FOCAL_COLS <- c("T1", "T3", "T5", "T7", "T9")    # pairs 1,2,3,4,5
YOKED_COLS <- c("T12", "T14", "T16", "T18", "T20")

# Exclusions by ethoscope and pair number
EXCLUDE <- list(
  Eth008 = c(4),
  Eth012 = c(),
  Eth015 = c()     
)

ETHOSCOPES <- names(EXCLUDE)

# Collect all focal and yoked data
all_focal <- list()
all_yoked <- list()

for (eth in ETHOSCOPES) {
  focal_file <- paste0(INPUT_DIR, "Sleep_", eth, "_Focal.txt")
  yoked_file <- paste0(INPUT_DIR, "Sleep_", eth, "_Yoked.txt")
  
  if (!file.exists(focal_file) || !file.exists(yoked_file)) {
    cat("Skipping", eth, "- files not found\n")
    next
  }
  
  focal <- fread(focal_file)
  yoked <- fread(yoked_file)
  
  excluded_pairs <- EXCLUDE[[eth]]
  
  for (pair in 1:5) {
    if (pair %in% excluded_pairs) {
      cat("Excluding", eth, "pair", pair, "\n")
      next
    }
    
    fcol <- FOCAL_COLS[pair]
    ycol <- YOKED_COLS[pair]
    
    if (fcol %in% names(focal)) {
      all_focal[[length(all_focal) + 1]] <- focal[[fcol]]
    }
    if (ycol %in% names(yoked)) {
      all_yoked[[length(all_yoked) + 1]] <- yoked[[ycol]]
    }
  }
}

# Find minimum length across all data
min_len <- min(sapply(c(all_focal, all_yoked), length))
cat("Using", min_len, "rows (minimum across all files)\n")

# Truncate all to same length
all_focal <- lapply(all_focal, function(x) x[1:min_len])
all_yoked <- lapply(all_yoked, function(x) x[1:min_len])

# Get ZT column from first file (truncated)
zt <- fread(file = paste0(INPUT_DIR, "Sleep_Eth008_Focal.txt"))[1:min_len, ZT]

# Calculate averages
focal_avg <- rowMeans(as.data.frame(all_focal), na.rm = TRUE)
yoked_avg <- rowMeans(as.data.frame(all_yoked), na.rm = TRUE)

# Create output
focal_out <- data.table(ZT = zt, Focal_Avg = round(focal_avg, 2))
yoked_out <- data.table(ZT = zt, Yoked_Avg = round(yoked_avg, 2))

# Write files
write.table(focal_out, paste0(OUTPUT_DIR, "Female_Sleep_Average_Focal.txt"),
            quote = FALSE, row.names = FALSE, sep = "\t")
write.table(yoked_out, paste0(OUTPUT_DIR, "Female_Sleep_Average_Yoked.txt"),
            quote = FALSE, row.names = FALSE, sep = "\t")

cat("\n✓ Created: Sleep_Average_Focal.txt")
cat("\n✓ Created: Sleep_Average_Yoked.txt")
cat("\nFocal pairs included:", length(all_focal))
cat("\nYoked pairs included:", length(all_yoked), "\n")
