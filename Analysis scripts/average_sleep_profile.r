# ============================================================
# AVERAGED SLEEP PROFILE — Focal vs Yoked
# ============================================================
# Uses the same data + swaps as dummy_actogram_17pairs.r.
# Excludes specified pairs, then plots mean ± SEM across
# the remaining pairs for Focal (red) and Yoked (blue).
# ============================================================

library(data.table)
library(ggplot2)

setwd("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/")
OUTPUT_DIR <- "Analysis scripts/analysis_output/"

# ============================================================
# CONFIG  — mirrors plot_wavy_actogram.r exactly
# ============================================================
ETHOSCOPES <- c("Eth007", "Eth008", "Eth009", "Eth010", "Eth011",
                "Eth012", "Eth013", "Eth014", "Eth015")

PAIRS <- data.frame(
  pair       = c(1,  2,  3,  4,  5),
  focal_tube = c(1,  3,  5,  7,  9),
  yoked_tube = c(12, 14, 16, 18, 20)
)

# Ethoscope-specific pairs to exclude (same as actogram)
EXCLUDE_PAIRS <- list(
  Eth007 = c(5),
  Eth008 = c(3),
  Eth009 = c(4, 5),
  Eth010 = c(1, 3, 5),
  Eth011 = c(3),
  Eth012 = c(1, 2, 5),
  Eth013 = c(1, 2, 3, 4, 5),
  Eth015 = c(2, 5)
)

FOCAL_COLOR <- "#E41A1C"
YOKED_COLOR <- "#377EB8"
FOCAL_LABEL <- "Focal (Deprived)"
YOKED_LABEL <- "Yoked (Control)"
SKIP_ROWS   <- 37
OUTPUT_FILE <- "Average_Sleep_Profile.pdf"

# ============================================================
# LOAD DATA
# ============================================================
cat("Loading data...\n\n")
all_data <- list()

for (eth in ETHOSCOPES) {
  focal_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Focal.txt")
  yoked_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Yoked.txt")
  if (!file.exists(focal_path) || !file.exists(yoked_path)) { next }

  focal <- suppressWarnings(fread(focal_path))
  yoked <- suppressWarnings(fread(yoked_path))

  focal_cols <- grep("^T[0-9]+$", names(focal), value = TRUE)
  yoked_cols <- grep("^T[0-9]+$", names(yoked), value = TRUE)
  if (length(focal_cols) == 0 && length(yoked_cols) == 0) { next }

  focal <- focal[, c("ZT", focal_cols), with = FALSE]
  yoked <- yoked[, c("ZT", yoked_cols), with = FALSE]

  focal_long <- suppressWarnings(
    melt(focal, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min"))
  focal_long[, `:=`(condition = "Focal", tube = as.integer(gsub("T", "", tube_col)))]

  yoked_long <- suppressWarnings(
    melt(yoked, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min"))
  yoked_long[, `:=`(condition = "Yoked", tube = as.integer(gsub("T", "", tube_col)))]

  dt_eth <- rbindlist(list(focal_long, yoked_long))
  dt_eth <- dt_eth[!is.na(sleep_min)]
  dt_eth[, ethoscope := eth]
  dt_eth[, row_num := seq_len(.N), by = .(tube, condition)]
  dt_eth[condition == "Focal", pair := PAIRS$pair[match(tube, PAIRS$focal_tube)]]
  dt_eth[condition == "Yoked", pair := PAIRS$pair[match(tube, PAIRS$yoked_tube)]]
  dt_eth <- dt_eth[!is.na(pair)]

  if (eth %in% names(EXCLUDE_PAIRS)) {
    dt_eth <- dt_eth[!pair %in% EXCLUDE_PAIRS[[eth]]]
  }

  if (nrow(dt_eth) == 0) { next }

  all_data[[eth]] <- dt_eth
}

dt <- rbindlist(all_data)
dt <- dt[row_num > SKIP_ROWS]
dt[, row_num := row_num - SKIP_ROWS]

# Duration
individual_max_rows <- dt[, .(max_row = max(row_num)), by = .(ethoscope, tube, condition)]
max_row  <- as.numeric(quantile(individual_max_rows$max_row, 0.75))
max_days <- (max_row - 1) * 0.5 / 24
dt <- dt[row_num <= max_row]
dt[, hours := (row_num - 1) * 0.5]
dt[, days  := hours / 24]

cat(sprintf("Detected duration: %.1f h (%.2f days)\n\n", max_row * 0.5, max_days))

included <- unique(dt[, .(ethoscope, pair)])
cat(sprintf("Included pairs (%d total):\n", nrow(included)))
for (i in seq_len(nrow(included)))
  cat(sprintf("  %s Pair %d\n", included$ethoscope[i], included$pair[i]))

# ============================================================
# COMPUTE MEAN ± SEM PER TIME BIN
# ============================================================
# Each (ethoscope, pair) is one replicate; average across them.
dt[, pair_id := paste0(ethoscope, "_P", pair)]   # unique pair identifier

avg <- dt[, .(
  mean_sleep = mean(sleep_min, na.rm = TRUE),
  sem_sleep  = sd(sleep_min,   na.rm = TRUE) / sqrt(sum(!is.na(sleep_min))),
  n          = sum(!is.na(sleep_min))
), by = .(row_num, days, hours, condition)]

avg[, ymin := pmax(0, mean_sleep - sem_sleep)]
avg[, ymax := pmin(30, mean_sleep + sem_sleep)]

cat(sprintf("\nAveraging %d pairs across %d time bins per condition.\n",
            nrow(included), max_row))

# ============================================================
# PLOT
# ============================================================
x_max         <- ceiling(max_days * 4) / 4
x_break_int   <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
x_breaks      <- seq(0, x_max, by = x_break_int)

# ZT day/night shading (day = ZT 0-12 = light grey, night = ZT 12-24 = dark grey)
# Build shading bands across the full duration
n_full_days <- ceiling(max_days)
# Starts with dark (ZT 0-12 = night), then light (ZT 12-24 = day)
night_bands <- data.frame(
  xmin  = seq(0,            n_full_days - 0.5, by = 1),
  xmax  = seq(0.5,          n_full_days,        by = 1),
  label = "Night (ZT 0-12)"
)
day_bands <- data.frame(
  xmin  = seq(0.5,          n_full_days,        by = 1),
  xmax  = seq(1,            n_full_days + 0.5,  by = 1),
  label = "Day (ZT 12-24)"
)
# Clip to actual data range
day_bands   <- day_bands[day_bands$xmin < x_max, ]
night_bands <- night_bands[night_bands$xmin < x_max, ]
day_bands$xmax   <- pmin(day_bands$xmax,   x_max)
night_bands$xmax <- pmin(night_bands$xmax, x_max)

p <- ggplot(avg, aes(x = days, y = mean_sleep, color = condition, fill = condition)) +


  # Day/night background
  geom_rect(data = day_bands,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "white",  alpha = 1) +
  geom_rect(data = night_bands,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "grey90", alpha = 1) +

  # SEM ribbon
  geom_ribbon(aes(ymin = ymin, ymax = ymax), alpha = 0.25, color = NA) +

  # Mean line
  geom_line(aes(linetype = condition), linewidth = 0.9) +

  scale_color_manual(
    values = c("Focal" = FOCAL_COLOR, "Yoked" = YOKED_COLOR),
    name = NULL, labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)
  ) +
  scale_fill_manual(
    values = c("Focal" = FOCAL_COLOR, "Yoked" = YOKED_COLOR),
    name = NULL, labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)
  ) +
  scale_linetype_manual(
    values = c("Focal" = "solid", "Yoked" = "dashed"),
    name = NULL, labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)
  ) +
  scale_x_continuous(breaks = x_breaks, expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 30), expand = c(0, 0),
                     breaks = seq(0, 30, 5)) +

  labs(
    title    = "Average Sleep Profile — Focal vs Yoked",
    subtitle = sprintf("Mean ± SEM across %d pairs  |  White = Day (ZT 0–12)  |  Grey = Night (ZT 12–24)",
                       nrow(included)),
    x = "Days",
    y = "Sleep (min per 30-min bin)"
  ) +

  theme_classic(base_size = 14) +
  theme(
    axis.title       = element_text(size = 14, face = "bold"),
    axis.text        = element_text(size = 12),
    legend.position  = "top",
    legend.text      = element_text(size = 12),
    plot.title       = element_text(hjust = 0.5, face = "bold", size = 17),
    plot.subtitle    = element_text(hjust = 0.5, size = 11, color = "gray40"),
    plot.margin      = margin(10, 20, 10, 10),
    panel.border     = element_rect(color = "black", fill = NA, linewidth = 0.8)
  )

# ============================================================
# SAVE
# ============================================================
out_path <- paste0(OUTPUT_DIR, OUTPUT_FILE)
ggsave(out_path, p, width = 14, height = 6)
cat(sprintf("\n✓ Saved: %s\n", out_path))
