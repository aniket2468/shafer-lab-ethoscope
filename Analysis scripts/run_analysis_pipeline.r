#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg)))
} else {
  getwd()
}

scripts <- c(
  "extract_ethoscope_data.r",
  "01_ethoscope_notebook_10sec_bins.r",
  "03_CreateSleepDataFilesFromRawEthoscopeOutput.r",
  "plot_wavy_actogram.r",
  "daily_sleep_summary.r"
)

cat("=== Ethoscope analysis pipeline ===\n")
cat("Scripts:", paste(scripts, collapse = " → "), "\n\n")

for (i in seq_along(scripts)) {
  script <- scripts[i]
  script_path <- file.path(script_dir, script)

  cat(sprintf("\n[%d/%d] Running %s\n", i, length(scripts), script))
  cat(strrep("=", 50), "\n\n")

  status <- system2("Rscript", shQuote(script_path), stdout = "", stderr = "")
  if (!identical(status, 0L)) {
    stop("Pipeline stopped: ", script, " failed (exit code ", status, ").")
  }
}

cat("\n", strrep("=", 50), "\n", sep = "")
cat("✓ Pipeline complete.\n")
