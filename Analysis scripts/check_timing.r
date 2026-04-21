# ===================================================================
# Check Timing Synchronization Across All Ethoscopes
# ===================================================================

library(data.table)

setwd("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/")

# List of files
files <- c(
  "ethoscope_008.txt",
  "ethoscope_010.txt",
  "ethoscope_007.txt",
  "ethoscope_014.txt"
)

folder <- "Analysis scripts/analysis_output"

cat("\n========================================\n")
cat("ETHOSCOPE TIMING ANALYSIS\n")
cat("========================================\n\n")

# Store timing info for each ethoscope
timing_summary <- list()

for (file in files) {
  filepath <- file.path(folder, file)
  
  cat("---", file, "---\n")
  
  # Read data
  dt <- fread(filepath)
  
  # Get unique IDs (individuals)
  unique_ids <- unique(dt$id)
  
  # Get time range (t is in seconds)
  min_t <- min(dt$t)
  max_t <- max(dt$t)
  
  # Convert to hours for readability
  min_hours <- min_t / 3600
  max_hours <- max_t / 3600
  duration_hours <- (max_t - min_t) / 3600
  
  # Check for gaps in time series
  all_t <- sort(unique(dt$t))
  time_diffs <- diff(all_t)
  expected_interval <- 10  # Expected 10-second intervals
  
  # Find gaps larger than expected
  gaps <- which(time_diffs > expected_interval)
  
  cat(sprintf("  Individuals: %d\n", length(unique_ids)))
  cat(sprintf("  Start time: t = %d sec (%.2f hours)\n", min_t, min_hours))
  cat(sprintf("  End time:   t = %d sec (%.2f hours)\n", max_t, max_hours))
  cat(sprintf("  Duration:   %.2f hours\n", duration_hours))
  cat(sprintf("  Total data points: %d\n", nrow(dt)))
  
  if (length(gaps) > 0) {
    cat(sprintf("  ⚠️  GAPS DETECTED: %d gaps\n", length(gaps)))
    cat("  Gap details:\n")
    for (i in 1:min(5, length(gaps))) {  # Show first 5 gaps
      gap_idx <- gaps[i]
      gap_start <- all_t[gap_idx]
      gap_end <- all_t[gap_idx + 1]
      gap_size <- time_diffs[gap_idx]
      cat(sprintf("    Gap %d: from t=%d to t=%d (%.1f sec gap)\n", 
                  i, gap_start, gap_end, gap_size))
    }
    if (length(gaps) > 5) {
      cat(sprintf("    ... and %d more gaps\n", length(gaps) - 5))
    }
  } else {
    cat("  ✓ No gaps detected\n")
  }
  
  cat("\n")
  
  # Store summary
  timing_summary[[file]] <- list(
    file = file,
    n_individuals = length(unique_ids),
    min_t = min_t,
    max_t = max_t,
    duration_hours = duration_hours,
    n_gaps = length(gaps)
  )
}

cat("\n========================================\n")
cat("SYNCHRONIZATION SUMMARY\n")
cat("========================================\n\n")

# Compare start and end times
all_starts <- sapply(timing_summary, function(x) x$min_t)
all_ends <- sapply(timing_summary, function(x) x$max_t)
all_durations <- sapply(timing_summary, function(x) x$duration_hours)

cat("Start times (seconds):\n")
for (i in seq_along(files)) {
  cat(sprintf("  %s: %d sec (%.2f hours)\n", 
              files[i], all_starts[i], all_starts[i]/3600))
}

cat("\nEnd times (seconds):\n")
for (i in seq_along(files)) {
  cat(sprintf("  %s: %d sec (%.2f hours)\n", 
              files[i], all_ends[i], all_ends[i]/3600))
}

cat("\nDurations:\n")
for (i in seq_along(files)) {
  cat(sprintf("  %s: %.2f hours\n", files[i], all_durations[i]))
}

# Check synchronization
start_range <- max(all_starts) - min(all_starts)
end_range <- max(all_ends) - min(all_ends)

cat("\n========================================\n")
cat("SYNCHRONIZATION CHECK\n")
cat("========================================\n\n")

cat(sprintf("Start time range: %d seconds (%.2f minutes)\n", 
            start_range, start_range/60))
cat(sprintf("End time range: %d seconds (%.2f minutes)\n", 
            end_range, end_range/60))

if (start_range < 300) {  # Within 5 minutes
  cat("✓ Start times are well synchronized (within 5 minutes)\n")
} else {
  cat("⚠️  Start times have significant variation (>5 minutes)\n")
}

if (end_range < 300) {  # Within 5 minutes
  cat("✓ End times are well synchronized (within 5 minutes)\n")
} else {
  cat("⚠️  End times have significant variation (>5 minutes)\n")
}

cat("\n")
