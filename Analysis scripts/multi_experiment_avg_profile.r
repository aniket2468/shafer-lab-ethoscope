# ============================================================
# MULTI-EXPERIMENT AVERAGE SLEEP PROFILE — Focal vs Yoked
# ============================================================
# Pools all good pairs from all experiments, plots mean ± SEM.
# After reviewing actogram, update EXCLUDE per experiment and re-run.
# ============================================================

library(data.table)
library(ggplot2)

BASE_DIR   <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/"
OUTPUT_DIR <- paste0(BASE_DIR, "Analysis scripts/analysis_output/")

FOCAL_COLOR <- "#E41A1C"
YOKED_COLOR <- "#377EB8"
FOCAL_LABEL <- "Focal (Deprived)"
YOKED_LABEL <- "Yoked (Control)"

PAIRS <- data.frame(
  pair       = c(1,  2,  3,  4,  5),
  focal_tube = c(1,  3,  5,  7,  9),
  yoked_tube = c(12, 14, 16, 18, 20)
)

OUTPUT_FILE <- "Multi_Experiment_Avg_Profile.pdf"

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
      Eth009 = c(3, 5),
      Eth010 = c(1, 2, 5),
      Eth011 = c(3),
      Eth012 = c(1, 3),
      Eth014 = c(1, 2, 5),
      Eth015 = c(1, 3)
    )
  )

)

# ============================================================
# LOAD ALL EXPERIMENTS
# ============================================================

cat("Loading data...\n\n")
all_data <- list()

for (exp_name in names(EXPERIMENTS)) {
  cfg        <- EXPERIMENTS[[exp_name]]
  SKIP_ROWS  <- cfg$skip_rows
  EXCLUDE    <- cfg$exclude

  cat(sprintf("── %s ──\n", exp_name))

  for (eth in cfg$ethoscopes) {
    focal_path <- paste0(cfg$output_dir, "Sleep_", eth, "_Focal.txt")
    yoked_path <- paste0(cfg$output_dir, "Sleep_", eth, "_Yoked.txt")
    if (!file.exists(focal_path) || !file.exists(yoked_path)) {
      cat(sprintf("  ⚠ %-10s file(s) not found\n", eth)); next
    }

    focal <- suppressWarnings(fread(focal_path))
    yoked <- suppressWarnings(fread(yoked_path))

    focal_cols <- grep("^T[0-9]+$", names(focal), value = TRUE)
    yoked_cols <- grep("^T[0-9]+$", names(yoked), value = TRUE)
    if (length(focal_cols) == 0 && length(yoked_cols) == 0) next

    focal <- focal[, c("ZT", focal_cols), with = FALSE]
    yoked <- yoked[, c("ZT", yoked_cols), with = FALSE]

    focal_long <- suppressWarnings(melt(focal, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min"))
    focal_long[, `:=`(condition = "Focal", tube = as.integer(gsub("T", "", tube_col)))]

    yoked_long <- suppressWarnings(melt(yoked, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min"))
    yoked_long[, `:=`(condition = "Yoked", tube = as.integer(gsub("T", "", tube_col)))]

    dt_eth <- rbindlist(list(focal_long, yoked_long))
    dt_eth <- dt_eth[!is.na(sleep_min)]
    dt_eth[, ethoscope  := eth]
    dt_eth[, experiment := exp_name]
    dt_eth[, sex        := cfg$sex_groups[eth]]
    dt_eth[, row_num    := seq_len(.N), by = .(tube, condition)]
    dt_eth[condition == "Focal", pair := PAIRS$pair[match(tube, PAIRS$focal_tube)]]
    dt_eth[condition == "Yoked", pair := PAIRS$pair[match(tube, PAIRS$yoked_tube)]]
    dt_eth <- dt_eth[!is.na(pair)]

    if (eth %in% names(EXCLUDE)) dt_eth <- dt_eth[!pair %in% EXCLUDE[[eth]]]
    if (nrow(dt_eth) == 0) next

    dt_eth <- dt_eth[row_num > SKIP_ROWS]
    dt_eth[, row_num := row_num - SKIP_ROWS]

    cat(sprintf("  ✓ %-10s  pairs: %s\n", eth,
                paste(sort(unique(dt_eth$pair)), collapse = ", ")))
    all_data[[paste0(exp_name, "_", eth)]] <- dt_eth
  }
  cat("\n")
}

if (length(all_data) == 0) stop("No data loaded.")
dt <- rbindlist(all_data)

# ============================================================
# DURATION
# ============================================================

max_row  <- as.numeric(quantile(
  dt[, .(m = max(row_num)), by = .(experiment, ethoscope, tube, condition)]$m, 0.75))
max_days <- (max_row - 1) * 0.5 / 24
dt <- dt[row_num <= max_row]
dt[, hours := (row_num - 1) * 0.5]
dt[, days  := hours / 24]

included <- unique(dt[, .(experiment, ethoscope, pair)])
cat(sprintf("Duration: %.1f h (%.2f days)\n", max_row * 0.5, max_days))
cat(sprintf("Total pairs pooled: %d\n\n", nrow(included)))

# ============================================================
# COMPUTE MEAN ± SEM — overall and by sex
# ============================================================

dt[, pair_id := paste0(experiment, "_", ethoscope, "_P", pair)]

compute_avg <- function(data, label) {
  avg <- data[, .(
    mean_sleep = mean(sleep_min, na.rm = TRUE),
    sem_sleep  = sd(sleep_min,   na.rm = TRUE) / sqrt(sum(!is.na(sleep_min))),
    n          = sum(!is.na(sleep_min))
  ), by = .(row_num, days, hours, condition)]
  avg[, ymin  := pmax(0, mean_sleep - sem_sleep)]
  avg[, ymax  := pmin(30, mean_sleep + sem_sleep)]
  avg[, group := label]
  avg
}

avg_all    <- compute_avg(dt,                   "All pairs")
avg_male   <- compute_avg(dt[sex == "Male"],    "Male")
avg_female <- compute_avg(dt[sex == "Female"],  "Female")

n_all    <- nrow(unique(dt[, .(pair_id)]))
n_male   <- nrow(unique(dt[sex == "Male",   .(pair_id)]))
n_female <- nrow(unique(dt[sex == "Female", .(pair_id)]))

cat(sprintf("Pairs — All: %d  |  Male: %d  |  Female: %d\n\n", n_all, n_male, n_female))

# ============================================================
# DAY/NIGHT SHADING
# ============================================================

n_full_days <- ceiling(max_days)
x_max       <- ceiling(max_days * 4) / 4
x_break_int <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
x_breaks    <- seq(0, x_max, by = x_break_int)

night_bands <- data.frame(xmin = seq(0, n_full_days - 0.5, 1), xmax = seq(0.5, n_full_days, 1))
day_bands   <- data.frame(xmin = seq(0.5, n_full_days, 1),     xmax = seq(1,   n_full_days + 0.5, 1))
night_bands <- night_bands[night_bands$xmin < x_max, ]; night_bands$xmax <- pmin(night_bands$xmax, x_max)
day_bands   <- day_bands[day_bands$xmin < x_max, ];     day_bands$xmax   <- pmin(day_bands$xmax,   x_max)

shade_layers <- list(
  geom_rect(data = day_bands,   aes(xmin=xmin,xmax=xmax,ymin=-Inf,ymax=Inf), inherit.aes=FALSE, fill="white",  alpha=1),
  geom_rect(data = night_bands, aes(xmin=xmin,xmax=xmax,ymin=-Inf,ymax=Inf), inherit.aes=FALSE, fill="grey90", alpha=1)
)

make_plot <- function(avg_dt, title_str, n_pairs) {
  ggplot(avg_dt, aes(x=days, y=mean_sleep, color=condition, fill=condition)) +
    shade_layers +
    geom_ribbon(aes(ymin=ymin, ymax=ymax), alpha=0.2, color=NA) +
    geom_line(aes(linetype=condition), linewidth=0.9) +
    scale_color_manual(values=c(Focal=FOCAL_COLOR, Yoked=YOKED_COLOR), name=NULL,
                       labels=c(Focal=FOCAL_LABEL, Yoked=YOKED_LABEL)) +
    scale_fill_manual(values=c(Focal=FOCAL_COLOR, Yoked=YOKED_COLOR), name=NULL,
                      labels=c(Focal=FOCAL_LABEL, Yoked=YOKED_LABEL)) +
    scale_linetype_manual(values=c(Focal="solid", Yoked="dashed"), name=NULL,
                          labels=c(Focal=FOCAL_LABEL, Yoked=YOKED_LABEL)) +
    scale_x_continuous(breaks=x_breaks, expand=c(0,0)) +
    scale_y_continuous(limits=c(0,30), expand=c(0,0), breaks=seq(0,30,5)) +
    labs(
      title    = title_str,
      subtitle = sprintf("Mean ± SEM across %d pairs  |  White = Day (ZT 0–12)  |  Grey = Night (ZT 12–24)  |  All experiments pooled",
                         n_pairs),
      x = "Days", y = "Sleep (min per 30-min bin)"
    ) +
    theme_classic(base_size=13) +
    theme(
      legend.position = "top",
      plot.title      = element_text(hjust=0.5, face="bold", size=15),
      plot.subtitle   = element_text(hjust=0.5, size=10, color="gray40"),
      panel.border    = element_rect(color="black", fill=NA, linewidth=0.8)
    )
}

p_all    <- make_plot(avg_all,    "Average Sleep Profile — All Pairs",     n_all)
p_male   <- make_plot(avg_male,   "Average Sleep Profile — Male Only",     n_male)
p_female <- make_plot(avg_female, "Average Sleep Profile — Female Only",   n_female)

# ============================================================
# SAVE — 3-panel PDF
# ============================================================

out_path <- paste0(OUTPUT_DIR, OUTPUT_FILE)
pdf(out_path, width=14, height=6)
  print(p_all)
  print(p_male)
  print(p_female)
dev.off()
cat(sprintf("✓ Saved: %s  (3 panels: All / Male / Female)\n", out_path))
