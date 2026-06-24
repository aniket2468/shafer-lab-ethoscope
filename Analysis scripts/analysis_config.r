# Pipeline settings — edit these before running

do_crop <- FALSE       # TRUE: trim to 24h before SD start; FALSE: keep full recording
ALLOWED_SLEEP_BINS <- c(5, 30, 60)
SLEEP_BIN_MIN <- 30   # sleep bin size in minutes: 5, 30, or 60

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
