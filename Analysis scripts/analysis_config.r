# ============================================================
# Pipeline settings — set interactively when you run the pipeline,
# or via environment variables (see prompt_pipeline_settings.r).
# Defaults below are used only for non-interactive runs (e.g. CI).
# ============================================================

DEFAULT_DO_CROP <- FALSE
DEFAULT_SLEEP_BIN_MIN <- 60

# Optional: set only if auto-detect fails (parent folder of this directory)
# PROJECT_ROOT <- "/path/to/your/Ethoscope"

# ============================================================
# Auto path detection — do not edit below
# ============================================================

if (!exists("PROJECT_ROOT", inherits = FALSE)) {
  PROJECT_ROOT <- NULL
}

.detect_scripts_dir <- function() {
  env_dir <- Sys.getenv("ETHOSCOPE_SCRIPTS_DIR", unset = "")
  if (nzchar(env_dir)) {
    return(normalizePath(env_dir, winslash = "/"))
  }
  for (i in rev(seq_along(sys.frames()))) {
    ofile <- sys.frames()[[i]]$ofile
    if (!is.null(ofile) && grepl("analysis_config\\.r$", ofile, ignore.case = TRUE)) {
      ofile <- gsub("~\\+~", " ", ofile)
      return(dirname(normalizePath(ofile, winslash = "/")))
    }
  }
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    script_path <- gsub("~\\+~", " ", sub("^--file=", "", file_arg[1]))
    return(dirname(normalizePath(script_path, winslash = "/")))
  }
  if (file.exists("analysis_config.r")) {
    return(normalizePath(getwd(), winslash = "/"))
  }
  if (file.exists("Analysis scripts/analysis_config.r")) {
    return(normalizePath("Analysis scripts", winslash = "/"))
  }
  stop(
    "Cannot locate Analysis scripts folder.\n",
    "  Run via: Rscript path/to/script.r\n",
    "  Or set PROJECT_ROOT above and source this file from Analysis scripts/."
  )
}

if (!exists("SCRIPTS_DIR", inherits = FALSE)) {
  SCRIPTS_DIR <- .detect_scripts_dir()
}

if (is.null(PROJECT_ROOT)) {
  PROJECT_ROOT <- normalizePath(file.path(SCRIPTS_DIR, ".."), winslash = "/")
} else {
  PROJECT_ROOT <- normalizePath(PROJECT_ROOT, winslash = "/")
}

OUTPUT_DIR         <- paste0(normalizePath(file.path(SCRIPTS_DIR, "analysis_output"), winslash = "/"), "/")
ETHOSCOPE_DATA_DIR <- normalizePath(file.path(PROJECT_ROOT, "ethoscope_data"), winslash = "/")

if (dir.exists(PROJECT_ROOT)) {
  setwd(PROJECT_ROOT)
}

ALLOWED_SLEEP_BINS <- c(5, 30, 60)

crop_env <- Sys.getenv("ETHOSCOPE_DO_CROP", unset = "")
bin_env  <- Sys.getenv("ETHOSCOPE_SLEEP_BIN_MIN", unset = "")

if (nzchar(crop_env)) {
  do_crop <- identical(toupper(crop_env), "TRUE")
} else {
  do_crop <- DEFAULT_DO_CROP
}

if (nzchar(bin_env)) {
  SLEEP_BIN_MIN <- as.integer(bin_env)
} else {
  SLEEP_BIN_MIN <- DEFAULT_SLEEP_BIN_MIN
}

if (!SLEEP_BIN_MIN %in% ALLOWED_SLEEP_BINS) {
  stop("SLEEP_BIN_MIN must be one of ", paste(ALLOWED_SLEEP_BINS, collapse = ", "),
       ", got: ", SLEEP_BIN_MIN)
}

BIN_HOURS     <- SLEEP_BIN_MIN / 60
BINS_PER_DAY  <- (24 * 60) / SLEEP_BIN_MIN
CROP_TAG      <- if (isTRUE(do_crop)) "" else "_uncropped"

read_applied_bin <- function(output_dir) {
  marker <- file.path(output_dir, ".sleep_bin_min")
  if (file.exists(marker)) {
    bin <- as.integer(readLines(marker, n = 1))
    if (!bin %in% ALLOWED_SLEEP_BINS) stop("Invalid .sleep_bin_min marker in ", output_dir)
    return(bin)
  }
  SLEEP_BIN_MIN
}

source_script <- function(filename) {
  source(file.path(SCRIPTS_DIR, filename), local = parent.frame())
}
