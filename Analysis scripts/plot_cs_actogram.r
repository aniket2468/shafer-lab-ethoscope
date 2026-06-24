library(data.table)
library(ggplot2)

setwd("/Users/aniketsharma/Documents/Ethoscope/Ethoscope/")
OUTPUT_DIR <- "Analysis scripts/analysis_output/"

FOCAL_FILE <- "CS_FOCAL_SleepData_5minDef_220secTrigger.txt"
YOKED_FILE <- "CS_YOKED_SleepData_5minDef_220secTrigger.txt"

PLOT_PAIRS <- "all"

EXCLUDE_PAIRS <- c()

FOCAL_COLOR <- "#E41A1C"            # red
YOKED_COLOR <- "#377EB8"            # blue
FOCAL_LABEL <- "Focal (Deprived)"
YOKED_LABEL <- "Yoked (Control)"

SKIP_ROWS <- 0

MAX_DAYS <- NULL

OUTPUT_FILE <- "CS_Sleep_Actogram_220secTrigger.pdf"

WAVE_SCALE <- 0.7

ROW_HEIGHT_IN  <- 0.6
HEIGHT_EXTRA_IN <- 2   # title, legend, margins

focal_path <- paste0(OUTPUT_DIR, FOCAL_FILE)
yoked_path <- paste0(OUTPUT_DIR, YOKED_FILE)

if (!file.exists(focal_path)) stop("Focal file not found: ", focal_path)
if (!file.exists(yoked_path)) stop("Yoked file not found: ", yoked_path)

cat("Loading data...\n\n")

focal <- fread(focal_path)
yoked <- fread(yoked_path)

focal_cols <- grep("^I[0-9]+$", names(focal), value = TRUE)
yoked_cols <- grep("^I[0-9]+$", names(yoked), value = TRUE)

common_cols <- intersect(focal_cols, yoked_cols)
if (length(common_cols) == 0) {
  stop("No matching individual columns (I[0-9]+) found in both files.")
}

focal <- focal[, c("ZT", common_cols), with = FALSE]
yoked <- yoked[, c("ZT", common_cols), with = FALSE]

# Melt to long format
focal_long <- melt(focal, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min")
focal_long[, `:=`(condition = "Focal", tube = as.integer(gsub("I", "", tube_col)))]

yoked_long <- melt(yoked, id.vars = "ZT", variable.name = "tube_col", value.name = "sleep_min")
yoked_long[, `:=`(condition = "Yoked", tube = as.integer(gsub("I", "", tube_col)))]

dt <- rbindlist(list(focal_long, yoked_long))
dt <- dt[!is.na(sleep_min)]
dt[, ethoscope := "CS"]

# Row index per tube × condition (preserves time order)
dt[, row_num := seq_len(.N), by = .(tube, condition)]

# Assign sequential pair numbers (1, 2, 3 ...) in column order
# so plot labels read "CS Pair 1", "CS Pair 2" instead of the raw I-column IDs
pair_map <- data.table(
  tube = as.integer(gsub("I", "", common_cols)),
  pair = seq_along(common_cols)
)
dt[pair_map, pair := i.pair, on = "tube"]

# Filter pairs (PLOT_PAIRS and EXCLUDE_PAIRS now refer to sequential pair numbers)
if (!identical(tolower(as.character(PLOT_PAIRS)), "all")) {
  dt <- dt[pair %in% as.integer(PLOT_PAIRS)]
}
if (length(EXCLUDE_PAIRS) > 0) {
  dt <- dt[!pair %in% EXCLUDE_PAIRS]
}

found_pairs <- sort(unique(dt$pair))
cat(sprintf("  ✓ Canton-S loaded: %d pairs found (Pair 1 … %d, from columns %s … %s)\n",
            length(found_pairs),
            max(found_pairs),
            common_cols[1],
            common_cols[length(common_cols)]))

dt <- dt[row_num > SKIP_ROWS]
dt[, row_num := row_num - SKIP_ROWS]

# CS files use 60-min bins
bin_hours <- 1.0
bin_mins  <- bin_hours * 60

individual_max_rows <- dt[, .(max_row = max(row_num)), by = .(tube, condition)]

if (!is.null(MAX_DAYS)) {
  max_row  <- MAX_DAYS * 24 / bin_hours
  max_days <- MAX_DAYS
  cat(sprintf("\nUsing fixed duration: %.1f h (%.2f days)\n", max_row * bin_hours, max_days))
} else {
  max_row  <- as.numeric(quantile(individual_max_rows$max_row, 0.95))
  max_days <- (max_row - 1) * bin_hours / 24
  cat(sprintf("\nAuto-detected recording duration: %.1f h (%.2f days)\n",
              max_row * bin_hours, max_days))
}

dt <- dt[row_num <= max_row]

dt[, hours      := (row_num - 1) * bin_hours]
dt[, days       := hours / 24]
dt[, sleep_norm := sleep_min / bin_mins]

active_combos <- unique(dt[, .(ethoscope, pair)])
setorder(active_combos, -pair)
active_combos[, row_label := paste0("CS Pair ", pair)]
active_combos[, row_idx   := seq_len(.N)]

row_order <- active_combos$row_label
dt[, row_label := factor(paste0("CS Pair ", pair), levels = row_order)]
dt[, y_pos     := as.numeric(row_label)]

n_rows <- length(row_order)
cat("Total pairs plotted:", n_rows, "\n")

eth_label_dt <- data.table(
  ethoscope = "CS",
  mid_y     = mean(active_combos$row_idx),
  label     = "Canton-S"
)

x_max <- ceiling(max_days * 4) / 4   # round up to nearest 0.25 day

x_break_interval <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
x_breaks <- seq(0, x_max, by = x_break_interval)

label_x <- -x_max * 0.15   # ethoscope label x position

eth_annotations <- lapply(seq_len(nrow(eth_label_dt)), function(i) {
  annotate("text",
           x        = label_x,
           y        = eth_label_dt$mid_y[i],
           label    = eth_label_dt$label[i],
           fontface = "bold",
           size     = 4,
           hjust    = 1)
})

p <- ggplot(dt, aes(
    x     = days,
    y     = y_pos + sleep_norm * WAVE_SCALE,
    group = interaction(row_label, condition)
  )) +

  geom_line(aes(linetype = condition, color = condition), linewidth = 1.0) +
  geom_hline(yintercept = seq_len(n_rows), color = "gray85", linewidth = 0.3) +

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
    title    = "Canton-S Sleep Actogram: Focal vs Yoked Pairs",
    subtitle = sprintf(
      "Solid = %s  |  Dashed = %s  |  Upward = Sleeping  |  Duration: %.1f h",
      FOCAL_LABEL, YOKED_LABEL, max_row * bin_hours
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
    plot.margin        = margin(10, 10, 10, 80)
  ) +
  coord_cartesian(xlim = c(0, x_max), clip = "off")

plot_height <- n_rows * ROW_HEIGHT_IN + HEIGHT_EXTRA_IN
out_path    <- paste0(OUTPUT_DIR, OUTPUT_FILE)
ggsave(out_path, p, width = 16, height = plot_height, limitsize = FALSE)

cat(sprintf("\n✓ Saved: %s  (%.0f rows × 16 × %.1f inches)\n", out_path, n_rows, plot_height))
