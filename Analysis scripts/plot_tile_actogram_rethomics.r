# ============================================================
# TILE ACTOGRAM — FOCAL vs YOKED  (rethomics / ggetho)
# ============================================================
# Uses behavr + ggetho + stat_bar_tile_etho() for tile-based
# double-plotted actograms.  One panel per animal (ethoscope ×
# pair × condition), arranged in a grid via facet_wrap.
#
# Tile colour encodes sleep fraction (0 = fully awake,
# 1 = fully asleep in that 30-min bin).
#
# Edit only the USER CONFIG section below, then run the whole script.
# ============================================================

library(data.table)
library(behavr)   # install.packages("behavr")
library(ggetho)   # install.packages("ggetho")
library(ggplot2)

# ============================================================
# USER CONFIG — Edit these values before every run
# ============================================================

setwd("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/")
OUTPUT_DIR <- "Analysis scripts/analysis_output/"

# 1. Which ethoscopes to plot — Males first, then Females.
ETHOSCOPES <- c(
  "Eth007", "Eth009", "Eth011", "Eth013",    # Male
  "Eth008", "Eth010", "Eth012", "Eth014"     # Female
)

# 1b. Sex assignment per ethoscope
SEX_GROUPS <- c(
  Eth007 = "Male",   Eth009 = "Male",   Eth011 = "Male",   Eth013 = "Male",
  Eth008 = "Female", Eth010 = "Female", Eth012 = "Female", Eth014 = "Female"
)

# 2. Yoking pairs.
#    focal_tube → red tiles  (focal / sleep-deprived)
#    yoked_tube → blue tiles (yoked / control)
PAIRS <- data.frame(
  pair       = c(1,  2,  3,  4,  5),
  focal_tube = c(1,  3,  5,  7,  9),
  yoked_tube = c(12, 14, 16, 18, 20)
)

# 3. Which pair numbers to include. Use "all" or a numeric vector e.g. c(1, 2).
PLOT_PAIRS <- "all"

# 3b. Ethoscope-specific pairs to EXCLUDE.
EXCLUDE_PAIRS <- list(
  Eth007 = c(), Eth008 = c(), Eth009 = c(), Eth010 = c(),
  Eth011 = c(), Eth012 = c(), Eth013 = c(), Eth014 = c()
)

# 4. Skip first N 30-min bins at the start of the recording.
SKIP_ROWS <- 0

# 5. Maximum days to plot. NULL = auto-detect from data (95th percentile).
MAX_DAYS <- 8

# 6. Number of columns in the facet grid.
#    With 2 conditions (Focal/Yoked) per pair, ncol=8 shows 4 pairs side-by-side.
FACET_NCOL <- 8

# 7. Colour palette for tile fill scale
#    Low = awake (light), High = asleep (dark).
TILE_LOW  <- "#FFFFFF"
TILE_HIGH <- "#1A237E"   # deep navy for sleep

# 8. Output PDF filename (saved inside OUTPUT_DIR)
OUTPUT_FILE <- "Tile_Actogram_Rethomics.pdf"

# 9. PDF dimensions
PDF_WIDTH  <- 20   # inches
PDF_HEIGHT <- 14   # inches

# ============================================================
# LOAD DATA
# ============================================================

cat("Loading data...\n\n")
all_data <- list()

for (eth in ETHOSCOPES) {
  focal_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Focal.txt")
  yoked_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Yoked.txt")

  if (!file.exists(focal_path) || !file.exists(yoked_path)) {
    cat("  \u26a0 Skipping", eth, "\u2014 file(s) not found\n")
    next
  }

  focal <- fread(focal_path)
  yoked <- fread(yoked_path)

  focal_cols <- grep("^T[0-9]+$", names(focal), value = TRUE)
  yoked_cols <- grep("^T[0-9]+$", names(yoked), value = TRUE)

  if (length(focal_cols) == 0 && length(yoked_cols) == 0) {
    cat("  \u26a0 Skipping", eth, "\u2014 no tube columns found\n")
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

  # Add sequential row number per tube×condition (used for time conversion)
  dt_eth[, row_num := seq_len(.N), by = .(tube, condition)]

  # Map tubes → pair numbers
  dt_eth[condition == "Focal", pair := PAIRS$pair[match(tube, PAIRS$focal_tube)]]
  dt_eth[condition == "Yoked", pair := PAIRS$pair[match(tube, PAIRS$yoked_tube)]]
  dt_eth <- dt_eth[!is.na(pair)]

  if (!identical(tolower(as.character(PLOT_PAIRS)), "all")) {
    dt_eth <- dt_eth[pair %in% as.integer(PLOT_PAIRS)]
  }

  if (eth %in% names(EXCLUDE_PAIRS) && length(EXCLUDE_PAIRS[[eth]]) > 0) {
    dt_eth <- dt_eth[!pair %in% EXCLUDE_PAIRS[[eth]]]
  }

  if (nrow(dt_eth) == 0) {
    cat("  \u26a0 Skipping", eth, "\u2014 no matching pairs found\n")
    next
  }

  found_focal <- sort(unique(dt_eth[condition == "Focal", tube]))
  found_yoked <- sort(unique(dt_eth[condition == "Yoked", tube]))
  cat(sprintf("  \u2713 %-10s  focal: %-12s  yoked: %s\n",
              eth,
              paste0("T", found_focal, collapse = ", "),
              paste0("T", found_yoked, collapse = ", ")))

  all_data[[eth]] <- dt_eth
}

if (length(all_data) == 0) stop("No data loaded \u2014 check ETHOSCOPES and OUTPUT_DIR.")

dt <- rbindlist(all_data)

# ============================================================
# APPLY ROW SKIP
# ============================================================

dt <- dt[row_num > SKIP_ROWS]
dt[, row_num := row_num - SKIP_ROWS]

# ============================================================
# DURATION CLIPPING
# ============================================================

individual_max_rows <- dt[, .(max_row = max(row_num)), by = .(ethoscope, tube, condition)]

if (!is.null(MAX_DAYS)) {
  max_row  <- MAX_DAYS * 24L / 0.5
  max_days <- MAX_DAYS
  cat(sprintf("\nUsing fixed duration: %.1f h (%.2f days)\n", max_row * 0.5, max_days))
} else {
  max_row  <- as.numeric(quantile(individual_max_rows$max_row, 0.95))
  max_days <- (max_row - 1) * 0.5 / 24
  cat(sprintf("\nAuto-detected duration: %.1f h (%.2f days)\n", max_row * 0.5, max_days))
}

dt <- dt[row_num <= max_row]

# ============================================================
# CONVERT TO behavr FORMAT
# ============================================================

# t in seconds (behavr convention); row 1 → t = 0
dt[, t := as.integer((row_num - 1L) * 1800L)]

# sleep fraction in [0, 1]  — used as the tile z-variable
dt[, sleep_frac := sleep_min / 30]

# Unique animal identifier: one row in metadata per id
dt[, id := paste0(ethoscope, "_P", pair, "_", condition)]

# Human-readable panel label (shown in facet strips)
dt[, panel_label := paste0(ethoscope, "\nPair ", pair, " | ", condition)]

# ---- Metadata table (one row per animal) ----
meta <- unique(dt[, .(
  id,
  panel_label,
  ethoscope,
  pair,
  condition,
  sex = SEX_GROUPS[ethoscope]
)])
setkey(meta, id)

# ---- Time-series data table (one row per bin per animal) ----
dt_ts <- dt[, .(id, t, sleep_frac)]
setkey(dt_ts, id)   # behavr requires data and metadata to share the same key (id only)

# Build behavr object
dt_behavr <- behavr(dt_ts, meta)

n_animals <- nrow(meta)
cat(sprintf("Total animals in plot: %d  (Focal + Yoked × ethoscopes × pairs)\n\n", n_animals))

# ============================================================
# BUILD PLOT
# ============================================================

# Extract panel_label into the behavr data so facet_wrap can use it
dt_behavr[, panel_label := xmv(panel_label)]

# Order panels: Males before Females, by ethoscope, then pair, then condition
meta[, eth_order   := match(ethoscope, ETHOSCOPES)]
meta[, cond_order  := fifelse(condition == "Focal", 1L, 2L)]
setorder(meta, eth_order, pair, cond_order)
panel_levels <- meta$panel_label
dt_behavr[, panel_label := factor(panel_label, levels = panel_levels)]

p <- ggetho(dt_behavr, aes(z = sleep_frac), multiplot = 2) +
  stat_bar_tile_etho() +
  facet_wrap(~ panel_label, ncol = FACET_NCOL) +
  scale_fill_gradient(
    name   = "Sleep\nfraction",
    low    = TILE_LOW,
    high   = TILE_HIGH,
    limits = c(0, 1),
    breaks = c(0, 0.5, 1),
    labels = c("Awake", "50 %", "Asleep")
  ) +
  labs(
    title    = "Sleep Tile Actogram: Focal vs Yoked Pairs",
    subtitle = paste0(
      "Each panel = one animal  |  Tile darkness = sleep fraction  |  ",
      sprintf("Duration: %.1f h  |  Double-plotted", max_row * 0.5)
    ),
    x = "Time (days)",
    y = NULL
  ) +
  theme_bw(base_size = 10) +
  theme(
    strip.text       = element_text(size = 7, face = "bold", lineheight = 0.9),
    strip.background = element_rect(fill = "gray92", colour = "gray70"),
    axis.text.y      = element_blank(),
    axis.ticks.y     = element_blank(),
    panel.spacing    = unit(0.25, "lines"),
    legend.position  = "right",
    plot.title       = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle    = element_text(hjust = 0.5, size = 9, colour = "gray40"),
    plot.margin      = margin(10, 10, 10, 10)
  )

# ============================================================
# SAVE
# ============================================================

out_path <- paste0(OUTPUT_DIR, OUTPUT_FILE)
ggsave(out_path, p, width = PDF_WIDTH, height = PDF_HEIGHT, limitsize = FALSE)

cat(sprintf("\u2713 Saved: %s  (%d animals, %.0f \u00d7 %.0f inches)\n",
            out_path, n_animals, PDF_WIDTH, PDF_HEIGHT))
