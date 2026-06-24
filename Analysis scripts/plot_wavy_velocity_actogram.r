library(data.table)
library(ggplot2)

setwd("/Users/aniketsharma/Documents/Ethoscope/Ethoscope/")
source("Analysis scripts/analysis_config.r")
OUTPUT_DIR <- "Analysis scripts/analysis_output/"
MERGED_FILE <- paste0(OUTPUT_DIR, "all_ethoscopes_merged.txt")

SLEEP_BIN_MIN <- read_applied_bin(OUTPUT_DIR)
BIN_HOURS     <- SLEEP_BIN_MIN / 60
BIN_SEC_ROWS  <- SLEEP_BIN_MIN * 6L
cat("Bin size:", SLEEP_BIN_MIN, "min (10-sec samples per bin:", BIN_SEC_ROWS, ")\n\n")

PAIRS <- data.frame(
  pair       = c(1,  2,  3,  4,  5),
  focal_tube = c(1,  3,  5,  7,  9),
  yoked_tube = c(12, 14, 16, 18, 20)
)

PLOT_PAIRS <- "all"
EXCLUDE_PAIRS <- list()

FOCAL_COLOR <- "#E41A1C"
YOKED_COLOR <- "#377EB8"
FOCAL_LABEL <- "Focal (Deprived)"
YOKED_LABEL <- "Yoked (Control)"

SKIP_ROWS <- 0
MAX_DAYS  <- 6

OUTPUT_FILE <- paste0("Paired_Velocity_Actogram", CROP_TAG, "_", format(Sys.Date(), "%d_%b"), "_",
                      SLEEP_BIN_MIN, "min.pdf")

WAVE_SCALE      <- 0.7
ROW_HEIGHT_IN   <- 0.6
HEIGHT_EXTRA_IN <- 2
PLOT_WIDTH_IN   <- if (SLEEP_BIN_MIN == 5) 48 else 16

detect_ethoscopes <- function(base_dir, merged_ids) {
  results_dirs <- list.dirs(file.path(base_dir, "ethoscope_data/results/"), recursive = FALSE)
  cat_names <- c()
  eth_ids   <- c()
  for (mid in basename(results_dirs)) {
    eth_folder <- list.dirs(file.path(base_dir, "ethoscope_data/results", mid), recursive = FALSE)
    eth_folder <- basename(eth_folder[grepl("^ETHOSCOPE_", basename(eth_folder))])
    if (length(eth_folder) == 0) next
    eth_num <- sub("ETHOSCOPE_0*", "", eth_folder[1])
    eth_id  <- substr(mid, 1, 6)
    if (any(grepl(eth_id, merged_ids, fixed = TRUE))) {
      cat_names <- c(cat_names, paste0("Eth", sprintf("%03d", as.integer(eth_num))))
      eth_ids   <- c(eth_ids, eth_id)
    }
  }
  ord <- order(cat_names)
  list(names = cat_names[ord], ids = eth_ids[ord])
}

if (!file.exists(MERGED_FILE)) {
  stop("Merged file not found: ", MERGED_FILE, ". Run extract_ethoscope_data.r first.")
}

cat("Loading", MERGED_FILE, "...\n")
raw <- fread(MERGED_FILE, select = c("id", "t", "max_velocity"))
raw[, eth_id := sub(".*_", "", sub("\\|.*", "", id))]
raw[, tube   := as.integer(sub(".*\\|", "", id))]

eth_info <- detect_ethoscopes(getwd(), raw$id)
ETHOSCOPES <- eth_info$names
ETH_IDS    <- eth_info$ids
cat("Detected ethoscopes:", paste(ETHOSCOPES, collapse = ", "), "\n\n")

all_data <- list()

for (k in seq_along(ETHOSCOPES)) {
  eth     <- ETHOSCOPES[[k]]
  eth_id_val <- ETH_IDS[[k]]
  eth_raw <- raw[eth_id == eth_id_val]
  if (nrow(eth_raw) == 0) {
    cat("  ⚠ Skipping", eth, "— no rows in merged file\n")
    next
  }

  focal_tubes <- PAIRS$focal_tube
  yoked_tubes <- PAIRS$yoked_tube

  focal_dt <- eth_raw[tube %in% focal_tubes]
  yoked_dt <- eth_raw[tube %in% yoked_tubes]
  focal_dt[, condition := "Focal"]
  yoked_dt[, condition := "Yoked"]
  eth_dt <- rbind(focal_dt, yoked_dt)
  eth_dt[, ethoscope := eth]

  eth_dt[condition == "Focal", pair := PAIRS$pair[match(tube, PAIRS$focal_tube)]]
  eth_dt[condition == "Yoked", pair := PAIRS$pair[match(tube, PAIRS$yoked_tube)]]
  eth_dt <- eth_dt[!is.na(pair)]
  setorder(eth_dt, id, t)

  eth_dt[, bin := (seq_len(.N) - 1L) %/% BIN_SEC_ROWS + 1L, by = id]
  binned <- eth_dt[, .(
    max_velocity = mean(max_velocity, na.rm = TRUE)
  ), by = .(ethoscope, tube, condition, pair, bin)]
  binned <- binned[!is.na(max_velocity)]
  binned[, row_num := bin]

  if (!identical(tolower(as.character(PLOT_PAIRS)), "all")) {
    binned <- binned[pair %in% as.integer(PLOT_PAIRS)]
  }
  if (eth %in% names(EXCLUDE_PAIRS)) {
    binned <- binned[!pair %in% EXCLUDE_PAIRS[[eth]]]
  }
  if (nrow(binned) == 0) {
    cat("  ⚠ Skipping", eth, "— no matching pairs\n")
    next
  }

  # Trim to last bin with any data for this ethoscope
  max_bin <- max(binned$bin, na.rm = TRUE)
  binned <- binned[bin <= max_bin]

  found_focal <- sort(unique(binned[condition == "Focal", tube]))
  found_yoked <- sort(unique(binned[condition == "Yoked", tube]))
  cat(sprintf("  ✓ %-10s  focal: %-12s  yoked: %s\n",
              eth,
              paste0("T", found_focal, collapse = ", "),
              paste0("T", found_yoked, collapse = ", ")))

  all_data[[eth]] <- binned
}

if (length(all_data) == 0) stop("No velocity data loaded.")

dt <- rbindlist(all_data)

dt <- dt[row_num > SKIP_ROWS]
dt[, row_num := row_num - SKIP_ROWS]

if (!is.null(MAX_DAYS)) {
  max_row  <- MAX_DAYS * 24 / BIN_HOURS
  max_days <- MAX_DAYS
  cat(sprintf("\nUsing fixed duration: %.1f h (%.2f days)\n", max_row * BIN_HOURS, max_days))
} else {
  max_row  <- as.numeric(quantile(dt[, max(row_num), by = .(ethoscope, tube, condition)]$V1, 0.95))
  max_days <- (max_row - 1) * BIN_HOURS / 24
  cat(sprintf("\nAuto-detected duration: %.1f h (%.2f days)\n", max_row * BIN_HOURS, max_days))
}

dt <- dt[row_num <= max_row]

# Normalize velocity 0–1 per tube trace for wavy display
dt[, vel_norm := (max_velocity - min(max_velocity, na.rm = TRUE)) /
     pmax(diff(range(max_velocity, na.rm = TRUE)), 1e-9),
   by = .(ethoscope, tube, condition)]

dt[, hours := (row_num - 1) * BIN_HOURS]
dt[, days  := hours / 24]

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

eth_label_dt <- active_combos[, .(mid_y = mean(row_idx)), by = ethoscope]
eth_label_dt[, label := ethoscope]

x_max <- ceiling(max_days * 4) / 4
x_break_interval <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
x_breaks <- seq(0, x_max, by = x_break_interval)
label_x  <- -x_max * 0.15

eth_annotations <- lapply(seq_len(nrow(eth_label_dt)), function(i) {
  annotate("text", x = label_x, y = eth_label_dt$mid_y[i],
           label = eth_label_dt$label[i], fontface = "bold", size = 4, hjust = 1)
})

p <- ggplot(dt, aes(
    x     = days,
    y     = y_pos + vel_norm * WAVE_SCALE,
    group = interaction(row_label, condition)
  )) +
  geom_line(aes(linetype = condition, color = condition), linewidth = 0.5) +
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
  scale_y_continuous(breaks = seq_len(n_rows), labels = row_order, expand = c(0.02, 0.02)) +
  scale_x_continuous(breaks = x_breaks, labels = x_breaks) +
  labs(
    title    = "Velocity Actogram: Focal vs Yoked Pairs",
    subtitle = sprintf(
      "Solid = %s  |  Dashed = %s  |  Upward = Higher activity  |  %d-min bins  |  Duration: %.1f h",
      FOCAL_LABEL, YOKED_LABEL, SLEEP_BIN_MIN, max_row * BIN_HOURS
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

plot_height <- n_rows * ROW_HEIGHT_IN + HEIGHT_EXTRA_IN
out_path    <- paste0(OUTPUT_DIR, OUTPUT_FILE)
ggsave(out_path, p, width = PLOT_WIDTH_IN, height = plot_height, limitsize = FALSE)

cat(sprintf("\n✓ Saved: %s  (%.0f rows × %.0f × %.1f inches)\n",
            out_path, n_rows, PLOT_WIDTH_IN, plot_height))
