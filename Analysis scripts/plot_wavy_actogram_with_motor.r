library(data.table)
library(ggplot2)

setwd("/Users/aniketsharma/Documents/Ethoscope/Ethoscope/")
source("Analysis scripts/analysis_config.r")
OUTPUT_DIR <- "Analysis scripts/analysis_output/"

SLEEP_BIN_MIN <- read_applied_bin(OUTPUT_DIR)
BIN_HOURS     <- SLEEP_BIN_MIN / 60
BIN_SEC_ROWS  <- SLEEP_BIN_MIN * 6L   # 10-sec samples per sleep bin
BINS_PER_DAY  <- (24 * 60) / SLEEP_BIN_MIN
cat("Sleep bin size:", SLEEP_BIN_MIN, "min\n\n")

detect_ethoscopes <- function(output_dir) {
  focal_files <- list.files(output_dir, pattern = "^Sleep_(Eth\\d+)_Focal\\.txt$")
  if (length(focal_files) == 0) {
    stop("No Sleep_*_Focal.txt files in ", output_dir,
         ". Run 03_CreateSleepDataFilesFromRawEthoscopeOutput.r first.")
  }
  eth <- sub("^Sleep_(Eth\\d+)_Focal\\.txt$", "\\1", focal_files)
  eth[order(as.integer(sub("Eth", "", eth)))]
}

ethoscope_raw_path <- function(output_dir, eth) {
  eth_num <- as.integer(sub("^Eth0*", "", eth))
  path <- paste0(output_dir, "ethoscope_", eth_num, ".txt")
  if (file.exists(path)) path else NA_character_
}

load_motor_events <- function(output_dir, ethoscopes, pairs, bin_sec_rows, bin_hours,
                              skip_rows, max_row, plot_pairs, exclude_pairs) {
  motor_list <- list()
  bin_sec <- bin_sec_rows * 10L   # seconds per sleep bin

  for (eth in ethoscopes) {
    raw_path <- ethoscope_raw_path(output_dir, eth)
    if (is.na(raw_path)) {
      cat("  ⚠ No raw file for motor markers:", eth, "\n")
      next
    }

    full <- fread(raw_path, select = c("id", "t", "interactions"))
    t_origin <- full[, .(t_min = min(t)), by = id]

    raw <- full[interactions > 0L]
    if (nrow(raw) == 0L) next

    raw <- t_origin[raw, on = "id"]
    raw[, tube := as.integer(sub(".*\\|", "", id))]
    raw[, ethoscope := eth]

    # Bin from elapsed time (t), not row index among interaction rows only
    raw[, bin := floor((t - t_min) / bin_sec) + 1L]
    raw <- raw[bin > skip_rows & bin <= max_row + skip_rows]
    raw[, bin := bin - skip_rows]
    if (nrow(raw) == 0L) next

    raw[tube %in% pairs$focal_tube, condition := "Focal"]
    raw[tube %in% pairs$yoked_tube, condition := "Yoked"]
    raw <- raw[!is.na(condition)]
    raw[condition == "Focal", pair := pairs$pair[match(tube, pairs$focal_tube)]]
    raw[condition == "Yoked", pair := pairs$pair[match(tube, pairs$yoked_tube)]]
    raw <- raw[!is.na(pair)]

    if (!identical(tolower(as.character(plot_pairs)), "all")) {
      raw <- raw[pair %in% as.integer(plot_pairs)]
    }
    if (eth %in% names(exclude_pairs)) {
      raw <- raw[!pair %in% exclude_pairs[[eth]]]
    }
    if (nrow(raw) == 0L) next

    # One marker per sleep bin per tube (interactions can span multiple 10-sec rows)
    raw <- raw[, .(days = (bin[1L] - 1L) * bin_hours / 24),
               by = .(ethoscope, pair, condition, tube, bin)]

    motor_list[[eth]] <- raw
  }

  if (length(motor_list) == 0L) return(NULL)
  rbindlist(motor_list)
}

ETHOSCOPES <- detect_ethoscopes(OUTPUT_DIR)
cat("Detected ethoscopes:", paste(ETHOSCOPES, collapse = ", "), "\n\n")

PAIRS <- data.frame(
  pair       = c(1,  2,  3,  4,  5),
  focal_tube = c(1,  3,  5,  7,  9),
  yoked_tube = c(12, 14, 16, 18, 20)
)

PLOT_PAIRS <- "all"

EXCLUDE_PAIRS <- list(
  Eth007 = c()
)

FOCAL_COLOR <- "#E41A1C"
YOKED_COLOR <- "#377EB8"
FOCAL_LABEL <- "Focal (Deprived)"
YOKED_LABEL <- "Yoked (Control)"

# Motor engagement markers (interactions > 0 in raw ethoscope data)
FOCAL_MOTOR_COLOR <- "#2CA02C"   # green
YOKED_MOTOR_COLOR <- "#9467BD"   # purple
MOTOR_ALPHA       <- 0.45
MOTOR_LINEWIDTH   <- if (SLEEP_BIN_MIN <= 5) 1.2 else 0.9
FOCAL_MOTOR_LABEL <- "Focal motor"
YOKED_MOTOR_LABEL <- "Yoked motor"

SKIP_ROWS <- 0
MAX_DAYS  <- 6

OUTPUT_FILE <- paste0(
  "Paired_Actogram_with_Motor", CROP_TAG, "_",
  format(Sys.Date(), "%d_%b"), "_", SLEEP_BIN_MIN, "min.pdf"
)

WAVE_SCALE      <- 0.7
ROW_HEIGHT_IN   <- 0.6
HEIGHT_EXTRA_IN <- 2
PLOT_WIDTH_IN   <- if (SLEEP_BIN_MIN == 5) 48 else 16

# ============================================================
# LOAD SLEEP DATA
# ============================================================

cat("Loading sleep data...\n\n")
all_data <- list()

for (eth in ETHOSCOPES) {
  focal_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Focal.txt")
  yoked_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Yoked.txt")

  if (!file.exists(focal_path) || !file.exists(yoked_path)) {
    cat("  ⚠ Skipping", eth, "— file(s) not found\n")
    next
  }

  focal <- fread(focal_path)
  yoked <- fread(yoked_path)

  focal_cols <- grep("^T[0-9]+$", names(focal), value = TRUE)
  yoked_cols <- grep("^T[0-9]+$", names(yoked), value = TRUE)

  if (length(focal_cols) == 0 && length(yoked_cols) == 0) {
    cat("  ⚠ Skipping", eth, "— no tube columns found\n")
    next
  }

  focal <- focal[, c("ZT", focal_cols), with = FALSE]
  yoked <- yoked[, c("ZT", yoked_cols), with = FALSE]

  focal_long <- melt(focal, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min")
  focal_long[, `:=`(condition = "Focal", tube = as.integer(gsub("T", "", tube_col)))]

  yoked_long <- melt(yoked, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min")
  yoked_long[, `:=`(condition = "Yoked", tube = as.integer(gsub("T", "", tube_col)))]

  dt_eth <- rbindlist(list(focal_long, yoked_long))
  dt_eth <- dt_eth[!is.na(sleep_min)]
  dt_eth[, ethoscope := eth]

  dt_eth[, row_num := seq_len(.N), by = .(tube, condition)]
  dt_eth[condition == "Focal", pair := PAIRS$pair[match(tube, PAIRS$focal_tube)]]
  dt_eth[condition == "Yoked", pair := PAIRS$pair[match(tube, PAIRS$yoked_tube)]]
  dt_eth <- dt_eth[!is.na(pair)]

  if (!identical(tolower(as.character(PLOT_PAIRS)), "all")) {
    dt_eth <- dt_eth[pair %in% as.integer(PLOT_PAIRS)]
  }

  if (eth %in% names(EXCLUDE_PAIRS)) {
    dt_eth <- dt_eth[!pair %in% EXCLUDE_PAIRS[[eth]]]
  }

  if (nrow(dt_eth) == 0) {
    cat("  ⚠ Skipping", eth, "— no matching pairs found\n")
    next
  }

  found_focal <- sort(unique(dt_eth[condition == "Focal", tube]))
  found_yoked <- sort(unique(dt_eth[condition == "Yoked", tube]))
  cat(sprintf("  ✓ %-10s  focal: %-12s  yoked: %s\n",
              eth,
              paste0("T", found_focal, collapse = ", "),
              paste0("T", found_yoked, collapse = ", ")))

  all_data[[eth]] <- dt_eth
}

if (length(all_data) == 0) stop("No data loaded — check ETHOSCOPES and OUTPUT_DIR.")

dt <- rbindlist(all_data)

dt <- dt[row_num > SKIP_ROWS]
dt[, row_num := row_num - SKIP_ROWS]

bin_hours <- BIN_HOURS
bin_mins  <- SLEEP_BIN_MIN

individual_max_rows <- dt[, .(max_row = max(row_num)), by = .(ethoscope, tube, condition)]

if (!is.null(MAX_DAYS)) {
  max_row  <- MAX_DAYS * 24 / bin_hours
  max_days <- MAX_DAYS
  cat(sprintf("\nUsing fixed duration: %.1f h (%.2f days)\n", max_row * bin_hours, max_days))
} else {
  max_row  <- as.numeric(quantile(individual_max_rows$max_row, 0.95))
  max_days <- (max_row - 1) * bin_hours / 24
  cat(sprintf("\nAuto-detected recording duration: %.1f h (%.2f days)\n", max_row * bin_hours, max_days))
}

dt <- dt[row_num <= max_row]

dt[, hours     := (row_num - 1) * bin_hours]
dt[, days      := hours / 24]
dt[, sleep_norm := sleep_min / bin_mins]

# ============================================================
# BUILD PLOT ROW ORDER
# ============================================================

active_combos <- unique(dt[, .(ethoscope, pair)])
active_combos[, eth_order := match(ethoscope, ETHOSCOPES)]
setorder(active_combos, eth_order, -pair)
active_combos[, eth_order := NULL]
active_combos[, row_label := paste0(ethoscope, " Pair ", pair)]
active_combos[, row_idx := seq_len(.N)]

row_order <- active_combos$row_label
dt[, row_label := factor(paste0(ethoscope, " Pair ", pair), levels = row_order)]
dt[, y_pos     := as.numeric(row_label)]

n_rows <- length(row_order)
cat("Total pairs plotted:", n_rows, "\n")

# ============================================================
# LOAD MOTOR EVENTS
# ============================================================

cat("\nLoading motor engagement markers...\n")
motor_dt <- load_motor_events(
  OUTPUT_DIR, ETHOSCOPES, PAIRS, BIN_SEC_ROWS, BIN_HOURS,
  SKIP_ROWS, max_row, PLOT_PAIRS, EXCLUDE_PAIRS
)

if (!is.null(motor_dt)) {
  motor_dt <- active_combos[motor_dt, on = c("ethoscope", "pair")]
  motor_dt <- motor_dt[!is.na(row_idx)]
  motor_dt[, y_pos := row_idx]
  motor_dt[, y_bot := y_pos - 0.02]
  motor_dt[, y_top := y_pos + WAVE_SCALE + 0.02]

  n_focal <- nrow(motor_dt[condition == "Focal"])
  n_yoked <- nrow(motor_dt[condition == "Yoked"])
  cat(sprintf("  ✓ Motor events: %d focal, %d yoked\n", n_focal, n_yoked))
  cat(sprintf("  ✓ Motor x-range: %.2f – %.2f days\n",
              min(motor_dt$days), max(motor_dt$days)))
} else {
  cat("  ⚠ No motor events found — plot will show sleep traces only\n")
}

# ============================================================
# ETHOSCOPE GROUP LABELS
# ============================================================

eth_label_dt <- active_combos[, .(mid_y = mean(row_idx)), by = ethoscope]
eth_label_dt[, label := ethoscope]

x_max <- ceiling(max_days * 4) / 4
x_break_interval <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
x_breaks <- seq(0, x_max, by = x_break_interval)
label_x  <- -x_max * 0.15

eth_annotations <- lapply(seq_len(nrow(eth_label_dt)), function(i) {
  annotate("text",
           x = label_x, y = eth_label_dt$mid_y[i],
           label = eth_label_dt$label[i],
           fontface = "bold", size = 4, hjust = 1)
})

# ============================================================
# BUILD PLOT
# ============================================================

p <- ggplot(dt, aes(
    x     = days,
    y     = y_pos + sleep_norm * WAVE_SCALE,
    group = interaction(row_label, condition)
  ))

p <- p +
  geom_hline(yintercept = seq_len(n_rows), color = "gray85", linewidth = 0.3) +
  geom_line(aes(linetype = condition, color = condition), linewidth = 0.5)

# Motor markers on top of sleep traces — semi-transparent so overlap blends
if (!is.null(motor_dt) && nrow(motor_dt) > 0) {
  motor_focal <- motor_dt[condition == "Focal"]
  motor_yoked <- motor_dt[condition == "Yoked"]

  if (nrow(motor_focal) > 0) {
    p <- p + geom_segment(
      data = motor_focal,
      aes(x = days, xend = days, y = y_bot, yend = y_top),
      inherit.aes = FALSE,
      color = FOCAL_MOTOR_COLOR,
      alpha = MOTOR_ALPHA,
      linewidth = MOTOR_LINEWIDTH
    )
  }
  if (nrow(motor_yoked) > 0) {
    p <- p + geom_segment(
      data = motor_yoked,
      aes(x = days, xend = days, y = y_bot, yend = y_top),
      inherit.aes = FALSE,
      color = YOKED_MOTOR_COLOR,
      alpha = MOTOR_ALPHA,
      linewidth = MOTOR_LINEWIDTH
    )
  }
}

p <- p +
  eth_annotations +

  scale_linetype_manual(
    values = c("Focal" = "solid", "Yoked" = "dashed"),
    name   = NULL,
    labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)
  ) +
  scale_color_manual(
    values = c("Focal" = FOCAL_COLOR, "Yoked" = YOKED_COLOR),
    name   = NULL,
    labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)
  ) +
  scale_y_continuous(
    breaks = seq_len(n_rows),
    labels = row_order,
    expand = c(0.02, 0.02)
  ) +
  scale_x_continuous(
    breaks = x_breaks,
    labels = x_breaks
  ) +
  labs(
    title    = "Sleep Actogram: Focal vs Yoked Pairs (with Motor Events)",
    subtitle = sprintf(
      "Solid = %s  |  Dashed = %s  |  Green = %s  |  Purple = %s  |  %d-min bins",
      FOCAL_LABEL, YOKED_LABEL, FOCAL_MOTOR_LABEL, YOKED_MOTOR_LABEL, SLEEP_BIN_MIN
    ),
    x = "Days",
    y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.y        = element_text(size = 10, face = "bold"),
    axis.text.x        = element_text(size = 11),
    axis.title         = element_text(size = 13, face = "bold"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_line(color = "gray85", linewidth = 0.4),
    legend.position    = "top",
    plot.title         = element_text(hjust = 0.5, face = "bold", size = 17),
    plot.subtitle      = element_text(hjust = 0.5, size = 11, color = "gray40"),
    plot.margin        = margin(10, 10, 10, 120)
  ) +
  coord_cartesian(xlim = c(0, x_max), clip = "off")

# ============================================================
# SAVE
# ============================================================

plot_height <- n_rows * ROW_HEIGHT_IN + HEIGHT_EXTRA_IN
out_path    <- paste0(OUTPUT_DIR, OUTPUT_FILE)
ggsave(out_path, p, width = PLOT_WIDTH_IN, height = plot_height, limitsize = FALSE)

cat(sprintf("\n✓ Saved: %s  (%.0f rows × %.0f × %.1f inches)\n",
            out_path, n_rows, PLOT_WIDTH_IN, plot_height))
