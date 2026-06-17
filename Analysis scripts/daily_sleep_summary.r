# DAILY SLEEP PER FLY (minutes) - WITH PAIR EXCLUSIONS

library(data.table)
setwd("/Users/aniketsharma/Documents/Ethoscope/Ethoscope/")

# ============================================================
# CONFIG — mirrors plot_wavy_actogram.r exactly
# ============================================================

# Pair mapping: pair 1 = T1/T12, pair 2 = T3/T14, pair 3 = T5/T16, pair 4 = T7/T18, pair 5 = T9/T20
FOCAL_BY_PAIR <- c("T1", "T3", "T5", "T7", "T9")
YOKED_BY_PAIR <- c("T12", "T14", "T16", "T18", "T20")

ETHOSCOPES <- c(
  "Eth007"
)

SEX_GROUPS <- c(
  Eth007 = "Male"
)

# Ethoscope-specific pairs to exclude (same as actogram)
EXCLUDE <- list(
  Eth007 = c()
)

SKIP_ROWS <- 0

# Storage for all days
all_results <- list()

for (eth in ETHOSCOPES) {
  focal_path <- paste0("Analysis scripts/analysis_output/Sleep_", eth, "_Focal.txt")
  yoked_path <- paste0("Analysis scripts/analysis_output/Sleep_", eth, "_Yoked.txt")
  if (!file.exists(focal_path) || !file.exists(yoked_path)) {
    cat("\n===", eth, "=== ⚠ file(s) not found, skipping\n")
    next
  }

  cat("\n===", eth, "===\n")

  focal <- fread(focal_path)
  yoked <- fread(yoked_path)

  excluded <- if (eth %in% names(EXCLUDE)) EXCLUDE[[eth]] else c()

  cat("Excluded pairs:", if (length(excluded) == 0) "none" else paste(excluded, collapse = ", "), "\n\n")
  cat("Pair\tBase\tSD\tRec1\tRec2\tRec3\tRec4\n")

  for (pair in 1:5) {
    if (pair %in% excluded) next

    fcol <- FOCAL_BY_PAIR[pair]
    ycol <- YOKED_BY_PAIR[pair]

    if (!(fcol %in% names(focal)) || !(ycol %in% names(yoked))) next

    # Apply row skip before slicing days
    fvals <- focal[[fcol]]
    yvals <- yoked[[ycol]]
    if (SKIP_ROWS > 0) {
      fvals <- fvals[(SKIP_ROWS + 1):length(fvals)]
      yvals <- yvals[(SKIP_ROWS + 1):length(yvals)]
    }

    # Each day = 48 rows (30-min bins × 48 = 24 hours)
    get_day <- function(vals, day) {
      start <- (day - 1) * 48 + 1
      end   <- day * 48
      if (start > length(vals)) return(NA)
      end <- min(end, length(vals))
      round(sum(vals[start:end], na.rm = TRUE), 1)
    }

    # Focal
    f_base <- get_day(fvals, 1)
    f_sd   <- get_day(fvals, 2)
    f_rec1 <- get_day(fvals, 3)
    f_rec2 <- get_day(fvals, 4)
    f_rec3 <- get_day(fvals, 5)
    f_rec4 <- get_day(fvals, 6)

    cat(fcol, "\t", f_base, "\t", f_sd, "\t", f_rec1, "\t", f_rec2, "\t", f_rec3, "\t", f_rec4, "\n")

    all_results[[length(all_results) + 1]] <- data.table(
      eth = eth, sex = SEX_GROUPS[eth], type = "Focal", pair = pair,
      base = f_base, sd = f_sd, rec1 = f_rec1, rec2 = f_rec2, rec3 = f_rec3, rec4 = f_rec4
    )

    # Yoked
    y_base <- get_day(yvals, 1)
    y_sd   <- get_day(yvals, 2)
    y_rec1 <- get_day(yvals, 3)
    y_rec2 <- get_day(yvals, 4)
    y_rec3 <- get_day(yvals, 5)
    y_rec4 <- get_day(yvals, 6)

    cat(ycol, "\t", y_base, "\t", y_sd, "\t", y_rec1, "\t", y_rec2, "\t", y_rec3, "\t", y_rec4, "\n")

    all_results[[length(all_results) + 1]] <- data.table(
      eth = eth, sex = SEX_GROUPS[eth], type = "Yoked", pair = pair,
      base = y_base, sd = y_sd, rec1 = y_rec1, rec2 = y_rec2, rec3 = y_rec3, rec4 = y_rec4
    )
  }
}

# ============================================================
# COMBINE AND SUMMARIZE
# ============================================================
results <- rbindlist(all_results)

print_summary <- function(data, label) {
  cat("\n========== ", label, " ==========\n", sep = "")
  cat(sprintf("%-10s  %10s  %10s  %10s\n", "Period", "Focal_Avg", "Yoked_Avg", "Diff"))
  for (period in c("base", "sd", "rec1", "rec2", "rec3", "rec4")) {
    focal_avg <- round(mean(data[type == "Focal", get(period)], na.rm = TRUE), 1)
    yoked_avg <- round(mean(data[type == "Yoked", get(period)], na.rm = TRUE), 1)
    diff      <- round(focal_avg - yoked_avg, 1)
    cat(sprintf("%-10s  %10.1f  %10.1f  %10.1f\n", period, focal_avg, yoked_avg, diff))
  }
  cat("Pairs included: Focal =", nrow(data[type == "Focal"]),
      "| Yoked =", nrow(data[type == "Yoked"]), "\n")
}

print_summary(results, "SUMMARY")
