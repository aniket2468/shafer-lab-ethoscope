#!/usr/bin/env Rscript

get_script_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    path <- gsub("~\\+~", " ", sub("^--file=", "", file_arg[1]))
    return(dirname(normalizePath(path, winslash = "/")))
  }
  if (file.exists("analysis_config.r")) {
    return(normalizePath(getwd(), winslash = "/"))
  }
  stop("Run from Analysis scripts/ or via Rscript with full path.")
}

PIPELINE_SCRIPTS <- c(
  "extract_ethoscope_data.r",
  "01_ethoscope_notebook_10sec_bins.r",
  "03_CreateSleepDataFilesFromRawEthoscopeOutput.r",
  "plot_wavy_actogram.r",
  "daily_sleep_summary.r"
)

run_pipeline_steps <- function(script_dir) {
  source(file.path(script_dir, "prompt_pipeline_settings.r"), local = TRUE)
  env <- pipeline_env_prefix(script_dir)

  for (i in seq_along(PIPELINE_SCRIPTS)) {
    script <- PIPELINE_SCRIPTS[i]
    cat(sprintf("\n[%d/%d] Running %s\n", i, length(PIPELINE_SCRIPTS), script))
    cat(strrep("=", 50), "\n\n")

    cmd <- paste0(env, "Rscript ", shQuote(file.path(script_dir, script)))
    status <- system(cmd)
    if (!identical(status, 0L)) {
      stop("Pipeline stopped: ", script, " failed (exit code ", status, ").")
    }
  }
  cat("\n", strrep("=", 50), "\n✓ Pipeline complete.\n", sep = "")
}

# --- run when executed directly: Rscript run_analysis_pipeline.r ---
if (sys.nframe() == 0L) {
  script_dir <- get_script_dir()
  cat("=== Ethoscope analysis pipeline ===\n")
  source(file.path(script_dir, "prompt_pipeline_settings.r"), local = TRUE)
  prompt_pipeline_settings()
  source(file.path(script_dir, "analysis_config.r"), local = TRUE)
  cat(sprintf("Config: do_crop = %s | SLEEP_BIN_MIN = %d min\n\n", do_crop, SLEEP_BIN_MIN))
  run_pipeline_steps(script_dir)
}
