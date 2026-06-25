#!/usr/bin/env Rscript
# Double-click RUN_ETHOSCOPE_ANALYSIS.command (Mac) or:
#   Rscript RUN_ETHOSCOPE_ANALYSIS.r

get_script_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    path <- gsub("~\\+~", " ", sub("^--file=", "", file_arg[1]))
    return(dirname(normalizePath(path, winslash = "/")))
  }
  normalizePath(getwd(), winslash = "/")
}

script_dir <- get_script_dir()

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║         Ethoscope sleep analysis pipeline            ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

# Packages (only if missing)
source(file.path(script_dir, "install_dependencies.r"), local = TRUE)
if (length(missing_packages()) > 0L) install_if_missing()

# Settings
source(file.path(script_dir, "prompt_pipeline_settings.r"), local = TRUE)
prompt_pipeline_settings()
source(file.path(script_dir, "analysis_config.r"), local = FALSE)

cat("Project:  ", PROJECT_ROOT, "\n")
cat("Data:     ", ETHOSCOPE_DATA_DIR, "\n")
cat("Output:   ", OUTPUT_DIR, "\n")
cat("Crop:     ", if (do_crop) "yes" else "no (uncropped)", "\n")
cat("Bin size: ", SLEEP_BIN_MIN, "min\n\n")

if (!dir.exists(ETHOSCOPE_DATA_DIR)) {
  stop("Missing folder: ", ETHOSCOPE_DATA_DIR)
}
dbs <- Sys.glob(file.path(ETHOSCOPE_DATA_DIR, "results", "*", "ETHOSCOPE_*", "*", "*.db"))
if (length(dbs) == 0L) stop("No .db files in ethoscope_data/results/")
cat("Found", length(dbs), ".db file(s). Starting pipeline...\n\n")

dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

source(file.path(script_dir, "run_analysis_pipeline.r"), local = TRUE)
run_pipeline_steps(script_dir)

cat("\n✓ Done. Outputs in:\n  ", OUTPUT_DIR, "\n\n")
