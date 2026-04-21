# ============================================================
# MULTI-EXPERIMENT DAILY SLEEP SUMMARY
# ============================================================
# Mirrors daily_sleep_summary.r but across all experiments.
# Prints per-ethoscope detail, then summaries:
#   All / Male / Female / per experiment
# ============================================================

library(data.table)

BASE_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/"

FOCAL_BY_PAIR <- c("T1", "T3", "T5", "T7", "T9")
YOKED_BY_PAIR <- c("T12", "T14", "T16", "T18", "T20")

# ============================================================
# EXPERIMENT CONFIG — mirrors multi_experiment_actogram.r
# ============================================================

EXPERIMENTS <- list(

  "9-Feb-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_02_09/analysis_output/"),
    skip_rows  = 39,
    ethoscopes = c("Eth008", "Eth010", "Eth007", "Eth014"),
    sex_groups = c(Eth008="Male", Eth010="Male", Eth007="Female", Eth014="Female"),
    exclude    = list(
      Eth007 = c(1, 2, 5),
      Eth010 = c(1, 4, 5),
      Eth014 = c(1, 2, 3, 4)
    )
  ),

  "17-Mar-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_03_17/Analysis scripts/analysis_output/"),
    skip_rows  = 37,
    ethoscopes = c("Eth007", "Eth008", "Eth009", "Eth010",
                   "Eth011", "Eth012", "Eth013", "Eth015"),
    sex_groups = c(Eth007="Male", Eth008="Male", Eth009="Male", Eth010="Male",
                   Eth011="Male", Eth012="Male", Eth013="Male", Eth015="Male"),
    exclude    = list(
      Eth007 = c(3, 4, 5),
      Eth008 = c(3),
      Eth009 = c(1, 4, 5),
      Eth010 = c(1, 2, 3, 5),
      Eth011 = c(3),
      Eth012 = c(1, 2, 5),
      Eth013 = c(1, 2, 3, 4, 5),
      Eth015 = c(2, 5)
    )
  ),

  "27-Mar-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_03_27/Analysis scripts/analysis_output/"),
    skip_rows  = 43,
    ethoscopes = c("Eth007", "Eth008", "Eth011",
                   "Eth009", "Eth010", "Eth012", "Eth013", "Eth014", "Eth015"),
    sex_groups = c(Eth007="Male", Eth008="Male", Eth011="Male",
                   Eth009="Female", Eth010="Female", Eth012="Female",
                   Eth013="Female", Eth014="Female", Eth015="Female"),
    exclude    = list(
      Eth007 = c(1, 2, 3, 4, 5),
      Eth009 = c(3, 4, 5),
      Eth010 = c(1, 2, 3, 4, 5),
      Eth011 = c(3),
      Eth012 = c(1, 2, 3, 4, 5),
      Eth013 = c(1, 2, 3, 4, 5),
      Eth014 = c(1, 2, 3),
      Eth015 = c(1, 2, 3, 4, 5)
    )
  ),

  "6-Apr-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_04_06/analysis_output/"),
    skip_rows  = 34,
    ethoscopes = c("Eth008", "Eth009", "Eth011", "Eth014", "Eth015",
                   "Eth007", "Eth010", "Eth012"),
    sex_groups = c(Eth008="Male", Eth009="Male", Eth011="Male",
                   Eth014="Male", Eth015="Male",
                   Eth007="Female", Eth010="Female", Eth012="Female"),
    exclude    = list(
      Eth007 = c(3, 4, 5),
      Eth008 = c(2, 5),
      Eth009 = c(1, 3, 5),
      Eth010 = c(1, 2, 5),
      Eth011 = c(3),
      Eth012 = c(1, 3),
      Eth014 = c(1, 2, 5),
      Eth015 = c(1, 3)
    )
  )

)

# ============================================================
# HELPER: sum sleep for one day (48 bins = 24 h)
# ============================================================

get_day <- function(vals, day) {
  start <- (day - 1) * 48 + 1
  end   <- min(day * 48, length(vals))
  if (start > length(vals)) return(NA)
  round(sum(vals[start:end], na.rm = TRUE), 1)
}

# ============================================================
# HELPER: print summary table
# ============================================================

print_summary <- function(data, label) {
  cat(sprintf("\n========== %s ==========\n", label))
  cat(sprintf("%-10s  %10s  %10s  %10s\n", "Period", "Focal_Avg", "Yoked_Avg", "Diff"))
  for (period in c("base", "sd", "rec1", "rec2", "rec3", "rec4")) {
    focal_avg <- round(mean(data[type == "Focal", get(period)], na.rm = TRUE), 1)
    yoked_avg <- round(mean(data[type == "Yoked", get(period)], na.rm = TRUE), 1)
    diff      <- round(focal_avg - yoked_avg, 1)
    cat(sprintf("%-10s  %10.1f  %10.1f  %10.1f\n", period, focal_avg, yoked_avg, diff))
  }
  cat(sprintf("Pairs: Focal = %d  |  Yoked = %d\n",
              nrow(data[type == "Focal"]), nrow(data[type == "Yoked"])))
}

# ============================================================
# MAIN LOOP
# ============================================================

all_results <- list()

for (exp_name in names(EXPERIMENTS)) {
  cfg       <- EXPERIMENTS[[exp_name]]
  SKIP_ROWS <- cfg$skip_rows
  EXCLUDE   <- cfg$exclude

  cat(sprintf("\n\n══════════════════════════════════════════\n"))
  cat(sprintf("  %s  (skip_rows = %d)\n", exp_name, SKIP_ROWS))
  cat(sprintf("══════════════════════════════════════════\n"))

  for (eth in cfg$ethoscopes) {
    focal_path <- paste0(cfg$output_dir, "Sleep_", eth, "_Focal.txt")
    yoked_path <- paste0(cfg$output_dir, "Sleep_", eth, "_Yoked.txt")

    if (!file.exists(focal_path) || !file.exists(yoked_path)) {
      cat(sprintf("\n  [%s] ⚠ file(s) not found, skipping\n", eth)); next
    }

    focal <- fread(focal_path)
    yoked <- fread(yoked_path)

    excluded <- if (eth %in% names(EXCLUDE)) EXCLUDE[[eth]] else c()
    sex      <- cfg$sex_groups[eth]

    cat(sprintf("\n  [%s] (%s)  excluded pairs: %s\n", eth, sex,
                if (length(excluded) == 0) "none" else paste(excluded, collapse = ", ")))
    cat(sprintf("  %-6s  %-6s  %8s  %8s  %8s  %8s  %8s  %8s\n",
                "Tube", "Type", "Base", "SD", "Rec1", "Rec2", "Rec3", "Rec4"))

    for (pair in 1:5) {
      if (pair %in% excluded) next

      fcol <- FOCAL_BY_PAIR[pair]
      ycol <- YOKED_BY_PAIR[pair]
      if (!(fcol %in% names(focal)) || !(ycol %in% names(yoked))) next

      fvals <- focal[[fcol]]
      yvals <- yoked[[ycol]]
      if (SKIP_ROWS > 0) {
        fvals <- fvals[(SKIP_ROWS + 1):length(fvals)]
        yvals <- yvals[(SKIP_ROWS + 1):length(yvals)]
      }

      f_vals <- sapply(1:6, function(d) get_day(fvals, d))
      y_vals <- sapply(1:6, function(d) get_day(yvals, d))

      cat(sprintf("  %-6s  %-6s  %8.1f  %8.1f  %8.1f  %8.1f  %8.1f  %8.1f\n",
                  fcol, "Focal", f_vals[1], f_vals[2], f_vals[3], f_vals[4], f_vals[5], f_vals[6]))
      cat(sprintf("  %-6s  %-6s  %8.1f  %8.1f  %8.1f  %8.1f  %8.1f  %8.1f\n",
                  ycol, "Yoked", y_vals[1], y_vals[2], y_vals[3], y_vals[4], y_vals[5], y_vals[6]))

      all_results[[length(all_results) + 1]] <- data.table(
        experiment = exp_name, eth = eth, sex = sex,
        type = "Focal", pair = pair,
        base = f_vals[1], sd = f_vals[2],
        rec1 = f_vals[3], rec2 = f_vals[4], rec3 = f_vals[5], rec4 = f_vals[6]
      )
      all_results[[length(all_results) + 1]] <- data.table(
        experiment = exp_name, eth = eth, sex = sex,
        type = "Yoked", pair = pair,
        base = y_vals[1], sd = y_vals[2],
        rec1 = y_vals[3], rec2 = y_vals[4], rec3 = y_vals[5], rec4 = y_vals[6]
      )
    }
  }
}

# ============================================================
# COMBINED SUMMARIES
# ============================================================

results <- rbindlist(all_results)

print_summary(results,                          "ALL EXPERIMENTS — ALL PAIRS")
print_summary(results[sex == "Male"],           "ALL EXPERIMENTS — MALE")
print_summary(results[sex == "Female"],         "ALL EXPERIMENTS — FEMALE")

for (exp_name in names(EXPERIMENTS)) {
  print_summary(results[experiment == exp_name],
                paste0(exp_name, " — ALL"))
  if ("Male" %in% results[experiment == exp_name, sex])
    print_summary(results[experiment == exp_name & sex == "Male"],
                  paste0(exp_name, " — MALE"))
  if ("Female" %in% results[experiment == exp_name, sex])
    print_summary(results[experiment == exp_name & sex == "Female"],
                  paste0(exp_name, " — FEMALE"))
}
