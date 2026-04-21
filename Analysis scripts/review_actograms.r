# ============================================================
# REVIEW ACTOGRAMS — Show ALL pairs, no exclusions
# ============================================================
# Run this to generate one Paired_Actogram_REVIEW.pdf per experiment.
# Open each PDF, decide which pairs to exclude, then update
# plot_wavy_actogram.r and daily_sleep_summary.r accordingly.
# ============================================================

library(data.table)
library(ggplot2)

BASE_DIR <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/"

FOCAL_COLOR <- "#E41A1C"
YOKED_COLOR <- "#377EB8"
FOCAL_LABEL <- "Focal (Deprived)"
YOKED_LABEL <- "Yoked (Control)"

PAIRS <- data.frame(
  pair       = c(1,  2,  3,  4,  5),
  focal_tube = c(1,  3,  5,  7,  9),
  yoked_tube = c(12, 14, 16, 18, 20)
)

# ============================================================
# EXPERIMENT CONFIG
# Males listed first, then Females.
# skip_rows: 30-min bins to skip from the start (= recording lead-in).
#   Verify with check_timing.r if plots look phase-shifted.
# ⚠ 27-Mar: Eth007,010,012,013,015 sex not in notebook — marked Male.
#   Correct after reviewing the actogram.
# ============================================================

EXPERIMENTS <- list(

  "9-Feb-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_02_09/analysis_output/"),
    skip_rows  = 34,
    ethoscopes = c(
      "Eth008", "Eth010",    # Male
      "Eth007", "Eth014"     # Female
    ),
    sex_groups = c(
      Eth008 = "Male",   Eth010 = "Male",
      Eth007 = "Female", Eth014 = "Female"
    )
  ),

  "17-Mar-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_03_17/Analysis scripts/analysis_output/"),
    skip_rows  = 34,
    ethoscopes = c(
      "Eth007", "Eth008", "Eth009", "Eth010",
      "Eth011", "Eth012", "Eth013", "Eth015"   # All male
    ),
    sex_groups = c(
      Eth007 = "Male", Eth008 = "Male", Eth009 = "Male", Eth010 = "Male",
      Eth011 = "Male", Eth012 = "Male", Eth013 = "Male", Eth015 = "Male"
    )
  ),

  "27-Mar-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_03_27/Analysis scripts/analysis_output/"),
    skip_rows  = 34,
    ethoscopes = c(
      "Eth007", "Eth008", "Eth011",                          # Male
      "Eth009", "Eth010", "Eth012", "Eth013", "Eth014", "Eth015"  # Female
    ),
    sex_groups = c(
      Eth007 = "Male",   Eth008 = "Male",   Eth011 = "Male",
      Eth009 = "Female", Eth010 = "Female", Eth012 = "Female",
      Eth013 = "Female", Eth014 = "Female", Eth015 = "Female"
    )
  ),

  "6-Apr-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_04_06/analysis_output/"),
    skip_rows  = 34,
    ethoscopes = c(
      "Eth008", "Eth009", "Eth011", "Eth014", "Eth015",  # Male
      "Eth007", "Eth010", "Eth012"                       # Female
    ),
    sex_groups = c(
      Eth008 = "Male",   Eth009 = "Male",   Eth011 = "Male",
      Eth014 = "Male",   Eth015 = "Male",
      Eth007 = "Female", Eth010 = "Female", Eth012 = "Female"
    )
  )

)

# ============================================================
# GENERATE ONE PDF PER EXPERIMENT
# ============================================================

for (exp_name in names(EXPERIMENTS)) {
  cfg        <- EXPERIMENTS[[exp_name]]
  OUTPUT_DIR <- cfg$output_dir
  ETHOSCOPES <- cfg$ethoscopes
  SEX_GROUPS <- cfg$sex_groups
  SKIP_ROWS  <- cfg$skip_rows

  cat(sprintf("\n══════════════════════════════════════\n"))
  cat(sprintf("  %s\n", exp_name))
  cat(sprintf("══════════════════════════════════════\n"))

  # ── Load data ────────────────────────────────────────────
  all_data <- list()

  for (eth in ETHOSCOPES) {
    focal_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Focal.txt")
    yoked_path <- paste0(OUTPUT_DIR, "Sleep_", eth, "_Yoked.txt")

    if (!file.exists(focal_path) || !file.exists(yoked_path)) {
      cat(sprintf("  ⚠ %-10s — file(s) not found, skipping\n", eth))
      next
    }

    focal <- fread(focal_path)
    yoked <- fread(yoked_path)

    focal_cols <- grep("^T[0-9]+$", names(focal), value = TRUE)
    yoked_cols <- grep("^T[0-9]+$", names(yoked), value = TRUE)
    if (length(focal_cols) == 0 && length(yoked_cols) == 0) {
      cat(sprintf("  ⚠ %-10s — no tube columns, skipping\n", eth))
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

    if (nrow(dt_eth) == 0) {
      cat(sprintf("  ⚠ %-10s — no matching pairs, skipping\n", eth))
      next
    }

    found_f <- sort(unique(dt_eth[condition == "Focal", tube]))
    found_y <- sort(unique(dt_eth[condition == "Yoked", tube]))
    cat(sprintf("  ✓ %-10s  focal: %-14s  yoked: %s\n",
                eth,
                paste0("T", found_f, collapse = ", "),
                paste0("T", found_y, collapse = ", ")))

    all_data[[eth]] <- dt_eth
  }

  if (length(all_data) == 0) {
    cat("  ✗ No data loaded for this experiment — skipping PDF.\n")
    next
  }

  dt <- rbindlist(all_data)
  dt <- dt[row_num > SKIP_ROWS]
  dt[, row_num := row_num - SKIP_ROWS]

  # ── Duration ─────────────────────────────────────────────
  ind_max  <- dt[, .(max_row = max(row_num)), by = .(ethoscope, tube, condition)]
  max_row  <- as.numeric(quantile(ind_max$max_row, 0.75))
  max_days <- (max_row - 1) * 0.5 / 24
  dt <- dt[row_num <= max_row]
  dt[, hours     := (row_num - 1) * 0.5]
  dt[, days      := hours / 24]
  dt[, sleep_norm := sleep_min / 30]

  cat(sprintf("  Duration: %.1f h (%.2f days)\n", max_row * 0.5, max_days))

  # ── Build row order ───────────────────────────────────────
  active <- unique(dt[, .(ethoscope, pair)])
  active[, eth_order := match(ethoscope, ETHOSCOPES)]
  setorder(active, eth_order, pair)
  active[, eth_order := NULL]
  active[, row_label := paste0(ethoscope, " Pair ", pair)]
  active[, sex := SEX_GROUPS[ethoscope]]
  active[, row_idx := seq_len(.N)]

  row_order <- active$row_label
  dt[, row_label := factor(paste0(ethoscope, " Pair ", pair), levels = row_order)]
  dt[, y_pos     := as.numeric(row_label)]
  n_rows <- length(row_order)
  cat(sprintf("  Total pairs shown: %d\n", n_rows))

  # ── Ethoscope + sex labels ────────────────────────────────
  eth_label_dt <- data.table(ethoscope = unique(active$ethoscope))
  eth_label_dt[, mid_y := sapply(ethoscope, function(e) mean(which(active$ethoscope == e)))]
  eth_label_dt[, sex   := SEX_GROUPS[ethoscope]]
  eth_label_dt[, label := paste0(ethoscope, "\n(", sex, ")")]

  sex_group_dt <- active[, .(mid_y = mean(row_idx), max_y = max(row_idx)), by = sex]
  sex_separator_y <- if ("Male" %in% sex_group_dt$sex && "Female" %in% sex_group_dt$sex)
    sex_group_dt[sex == "Male", max_y] + 0.5 else NULL

  # ── X-axis ────────────────────────────────────────────────
  x_max         <- ceiling(max_days * 4) / 4
  x_break_int   <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
  x_breaks      <- seq(0, x_max, by = x_break_int)
  label_x       <- -x_max * 0.15
  sex_label_x   <- -x_max * 0.30

  # ── Build plot ────────────────────────────────────────────
  eth_ann <- lapply(seq_len(nrow(eth_label_dt)), function(i)
    annotate("text", x = label_x, y = eth_label_dt$mid_y[i],
             label = eth_label_dt$label[i], fontface = "bold", size = 3.5, hjust = 1))

  sex_ann <- lapply(seq_len(nrow(sex_group_dt)), function(i)
    annotate("text", x = sex_label_x, y = sex_group_dt$mid_y[i],
             label = sex_group_dt$sex[i], fontface = "bold.italic",
             size = 5, hjust = 1, color = "gray20"))

  p <- ggplot(dt, aes(x = days, y = y_pos + sleep_norm * 0.8,
                      group = interaction(row_label, condition))) +
    geom_line(aes(linetype = condition, color = condition), linewidth = 0.5) +
    geom_hline(yintercept = seq_len(n_rows), color = "gray85", linewidth = 0.3) +
    eth_ann + sex_ann +
    { if (!is.null(sex_separator_y))
        geom_hline(yintercept = sex_separator_y, color = "gray50",
                   linewidth = 0.8, linetype = "dashed")
      else list() } +
    scale_linetype_manual(
      values = c("Focal" = "solid", "Yoked" = "dashed"), name = NULL,
      labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)) +
    scale_color_manual(
      values = c("Focal" = FOCAL_COLOR, "Yoked" = YOKED_COLOR), name = NULL,
      labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)) +
    scale_y_continuous(breaks = seq_len(n_rows), labels = row_order, expand = c(0.02, 0.02)) +
    scale_x_continuous(breaks = x_breaks, labels = x_breaks) +
    labs(
      title    = paste("Sleep Actogram — ALL PAIRS (no exclusions):", exp_name),
      subtitle = sprintf("Solid = %s  |  Dashed = %s  |  Duration: %.1f h  |  skip_rows = %d",
                         FOCAL_LABEL, YOKED_LABEL, max_row * 0.5, SKIP_ROWS),
      x = "Days", y = NULL
    ) +
    theme_minimal(base_size = 13) +
    theme(
      axis.text.y        = element_text(size = 9, face = "bold"),
      axis.text.x        = element_text(size = 11),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_line(color = "gray85", linewidth = 0.4),
      legend.position    = "top",
      plot.title         = element_text(hjust = 0.5, face = "bold", size = 15),
      plot.subtitle      = element_text(hjust = 0.5, size = 10, color = "gray40"),
      plot.margin        = margin(10, 10, 10, 120)
    ) +
    coord_cartesian(xlim = c(0, x_max), clip = "off")

  # ── Save ─────────────────────────────────────────────────
  out_path   <- paste0(OUTPUT_DIR, "Paired_Actogram_REVIEW.pdf")
  plot_height <- max(8, n_rows * 0.6 + 2)
  ggsave(out_path, p, width = 16, height = plot_height)
  cat(sprintf("  ✓ Saved: %s\n", out_path))
}

cat("\n\nDone! Open each Paired_Actogram_REVIEW.pdf and note which pairs to exclude.\n")
