# ============================================================
# MULTI-EXPERIMENT ACTOGRAM — All pairs, no exclusions (review)
# ============================================================
# After reviewing the PDF, update EXCLUDE per experiment and re-run.
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

OUTPUT_FILE <- "Multi_Experiment_Actogram_all_meeting.pdf"

# ============================================================
# EXPERIMENT CONFIG
# To exclude pairs after review, add them to EXCLUDE per experiment:
#   exclude = list(Eth008 = c(2, 5), Eth009 = c(3, 4, 5), ...)
# Leave exclude = list() to show all pairs.
# ============================================================

EXPERIMENTS <- list(

  "9-Feb-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_02_09/analysis_output/"),
    skip_rows  = 0,
    ethoscopes = c(
      "Eth008", "Eth010",    # Male
      "Eth007", "Eth014"     # Female
    ),
    sex_groups = c(
      Eth008 = "Male",   Eth010 = "Male",
      Eth007 = "Female", Eth014 = "Female"
    ),
    exclude = list(

    )
  ),

  "17-Mar-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_03_17/Analysis scripts/analysis_output/"),
    skip_rows  = 0,
    ethoscopes = c(
      "Eth007", "Eth008", "Eth009", "Eth010",
      "Eth011", "Eth012", "Eth013", "Eth015"   # All male
    ),
    sex_groups = c(
      Eth007 = "Male", Eth008 = "Male", Eth009 = "Male", Eth010 = "Male",
      Eth011 = "Male", Eth012 = "Male", Eth013 = "Male", Eth015 = "Male"
    ),
    exclude = list(

    )
  ),

  "27-Mar-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_03_27/Analysis scripts/analysis_output/"),
    skip_rows  = 0,
    ethoscopes = c(
      "Eth007", "Eth008", "Eth011",                          # Male
      "Eth009", "Eth010", "Eth012", "Eth013", "Eth014", "Eth015"  # Female
    ),
    sex_groups = c(
      Eth007 = "Male",   Eth008 = "Male",   Eth011 = "Male",
      Eth009 = "Female", Eth010 = "Female", Eth012 = "Female",
      Eth013 = "Female", Eth014 = "Female", Eth015 = "Female"
    ),
    exclude = list(

    )
  ),

  "6-Apr-2026" = list(
    output_dir = paste0(BASE_DIR, "Summary/EXP_04_06/analysis_output/"),
    skip_rows  = 0,
    ethoscopes = c(
      "Eth008", "Eth009", "Eth011", "Eth014", "Eth015",  # Male
      "Eth007", "Eth010", "Eth012"                       # Female
    ),
    sex_groups = c(
      Eth008 = "Male",   Eth009 = "Male",   Eth011 = "Male",
      Eth014 = "Male",   Eth015 = "Male",
      Eth007 = "Female", Eth010 = "Female", Eth012 = "Female"
    ),
    exclude = list(

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
  ETHOSCOPES <- cfg$ethoscopes
  SEX_GROUPS <- cfg$sex_groups
  SKIP_ROWS  <- cfg$skip_rows
  EXCLUDE    <- cfg$exclude

  cat(sprintf("── %s ──\n", exp_name))

  for (eth in ETHOSCOPES) {
    focal_path <- paste0(cfg$output_dir, "Sleep_", eth, "_Focal.txt")
    yoked_path <- paste0(cfg$output_dir, "Sleep_", eth, "_Yoked.txt")

    if (!file.exists(focal_path) || !file.exists(yoked_path)) {
      cat(sprintf("  ⚠ %-10s file(s) not found\n", eth)); next
    }

    focal <- fread(focal_path)
    yoked <- fread(yoked_path)

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
    dt_eth[, ethoscope   := eth]
    dt_eth[, experiment  := exp_name]
    dt_eth[, sex         := SEX_GROUPS[eth]]
    dt_eth[, row_num     := seq_len(.N), by = .(tube, condition)]
    dt_eth[condition == "Focal", pair := PAIRS$pair[match(tube, PAIRS$focal_tube)]]
    dt_eth[condition == "Yoked", pair := PAIRS$pair[match(tube, PAIRS$yoked_tube)]]
    dt_eth <- dt_eth[!is.na(pair)]

    # Apply exclusions
    if (eth %in% names(EXCLUDE)) {
      dt_eth <- dt_eth[!pair %in% EXCLUDE[[eth]]]
    }

    if (nrow(dt_eth) == 0) next

    # Trim to skip_rows
    dt_eth <- dt_eth[row_num > SKIP_ROWS]
    dt_eth[, row_num := row_num - SKIP_ROWS]

    found_f <- sort(unique(dt_eth[condition == "Focal", tube]))
    found_y <- sort(unique(dt_eth[condition == "Yoked", tube]))
    cat(sprintf("  ✓ %-10s  focal: %-14s  yoked: %s\n",
                eth,
                paste0("T", found_f, collapse = ", "),
                paste0("T", found_y, collapse = ", ")))

    key <- paste0(exp_name, "_", eth)
    all_data[[key]] <- dt_eth
  }
  cat("\n")
}

if (length(all_data) == 0) stop("No data loaded.")
dt <- rbindlist(all_data)

# ============================================================
# DURATION — per experiment (align each experiment independently)
# ============================================================

dt[, exp_row_num := row_num]   # already trimmed per ethoscope above

# Use 75th percentile of max rows per experiment to set duration
dt[, max_row := as.numeric(quantile(
  dt[, .(m = max(row_num)), by = .(experiment, ethoscope, tube, condition)]$m,
  0.75))]

max_row  <- as.numeric(quantile(dt[, .(m = max(row_num)), by = .(experiment, ethoscope, tube, condition)]$m, 0.75))
max_days <- (max_row - 1) * 0.5 / 24
dt <- dt[row_num <= max_row]
dt[, hours      := (row_num - 1) * 0.5]
dt[, days       := hours / 24]
dt[, sleep_norm := sleep_min / 30]
cat(sprintf("Common duration: %.1f h (%.2f days)\n\n", max_row * 0.5, max_days))

# ============================================================
# BUILD ROW ORDER — grouped by experiment, then sex, then ethoscope
# ============================================================

# Order: for each experiment, males first then females
exp_order <- names(EXPERIMENTS)

active <- unique(dt[, .(experiment, ethoscope, pair, sex)])
active[, exp_idx := match(experiment, exp_order)]
active[, sex_idx := ifelse(sex == "Male", 1L, 2L)]

# ethoscope order within each experiment
for (en in exp_order) {
  eth_order <- EXPERIMENTS[[en]]$ethoscopes
  active[experiment == en, eth_idx := match(ethoscope, eth_order)]
}
setorder(active, exp_idx, sex_idx, eth_idx, pair)
active[, row_label := paste0("[", experiment, "] ", ethoscope, " P", pair)]
active[, row_idx   := seq_len(.N)]

row_order <- active$row_label
dt[, row_label := factor(paste0("[", experiment, "] ", ethoscope, " P", pair), levels = row_order)]
dt[, y_pos     := as.numeric(row_label)]
n_rows <- length(row_order)
cat(sprintf("Total pairs to plot: %d\n\n", n_rows))

# ============================================================
# EXPERIMENT SEPARATOR LINES & LABELS
# ============================================================

exp_label_dt <- active[, .(
  mid_y   = mean(row_idx),
  max_y   = max(row_idx)
), by = experiment]
exp_label_dt[, exp_idx := match(experiment, exp_order)]
setorder(exp_label_dt, exp_idx)

# Separator after each experiment (except the last)
sep_y <- exp_label_dt$max_y[-nrow(exp_label_dt)] + 0.5

# Sex separator within each experiment
sex_sep_dt <- active[, .(
  male_max = if ("Male" %in% sex) max(row_idx[sex == "Male"]) else NA_integer_
), by = experiment]
sex_sep_y <- na.omit(sex_sep_dt$male_max) + 0.5

# ============================================================
# ETHOSCOPE LABELS (right side of the pair label, left margin)
# ============================================================

eth_label_dt <- active[, .(mid_y = mean(row_idx)), by = .(experiment, ethoscope)]
eth_label_dt[, sex   := EXPERIMENTS[[experiment]]$sex_groups[ethoscope], by = .(experiment, ethoscope)]
eth_label_dt[, label := paste0(ethoscope, "\n(", sex, ")")]

# ============================================================
# X-AXIS
# ============================================================

x_max       <- ceiling(max_days * 4) / 4
x_break_int <- if (max_days <= 1.5) 0.25 else if (max_days <= 4) 0.5 else 1.0
x_breaks    <- seq(0, x_max, by = x_break_int)
label_x     <- -x_max * 0.12

# ============================================================
# BUILD PLOT
# ============================================================

eth_ann <- lapply(seq_len(nrow(eth_label_dt)), function(i)
  annotate("text", x = label_x, y = eth_label_dt$mid_y[i],
           label = eth_label_dt$label[i], fontface = "bold", size = 2.8, hjust = 1))

exp_ann <- lapply(seq_len(nrow(exp_label_dt)), function(i)
  annotate("text", x = x_max * 1.01, y = exp_label_dt$mid_y[i],
           label = exp_label_dt$experiment[i], fontface = "bold.italic",
           size = 3.5, hjust = 0, color = "gray20"))

p <- ggplot(dt, aes(x = days, y = y_pos + sleep_norm * 0.8,
                    group = interaction(row_label, condition))) +
  geom_line(aes(linetype = condition, color = condition), linewidth = 0.4) +
  geom_hline(yintercept = seq_len(n_rows), color = "gray88", linewidth = 0.25) +
  # experiment separators (thick)
  { if (length(sep_y) > 0)
      geom_hline(yintercept = sep_y, color = "black", linewidth = 1.0)
    else list() } +
  # sex separators within experiment (dashed)
  { if (length(sex_sep_y) > 0)
      geom_hline(yintercept = sex_sep_y, color = "gray40", linewidth = 0.6, linetype = "dashed")
    else list() } +
  eth_ann + exp_ann +
  scale_linetype_manual(
    values = c("Focal" = "solid", "Yoked" = "dashed"), name = NULL,
    labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)) +
  scale_color_manual(
    values = c("Focal" = FOCAL_COLOR, "Yoked" = YOKED_COLOR), name = NULL,
    labels = c("Focal" = FOCAL_LABEL, "Yoked" = YOKED_LABEL)) +
  scale_y_continuous(breaks = seq_len(n_rows), labels = row_order, expand = c(0.01, 0.01)) +
  scale_x_continuous(breaks = x_breaks, labels = x_breaks) +
  labs(
    title    = "Sleep Actogram — All Experiments (no exclusions)",
    subtitle = sprintf("Solid = %s  |  Dashed = %s  |  ━ experiment boundary  |  ╌ sex boundary",
                       FOCAL_LABEL, YOKED_LABEL),
    x = "Days", y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.y        = element_text(size = 7),
    axis.text.x        = element_text(size = 10),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_line(color = "gray85", linewidth = 0.3),
    legend.position    = "top",
    plot.title         = element_text(hjust = 0.5, face = "bold", size = 15),
    plot.subtitle      = element_text(hjust = 0.5, size = 10, color = "gray40"),
    plot.margin        = margin(10, 80, 10, 100)
  ) +
  coord_cartesian(xlim = c(0, x_max), clip = "off")

# ============================================================
# SAVE
# ============================================================

out_path    <- paste0(OUTPUT_DIR, OUTPUT_FILE)
plot_height <- max(10, n_rows * 0.45 + 3)
ggsave(out_path, p, width = 18, height = plot_height, limitsize = FALSE)
cat(sprintf("✓ Saved: %s  (%d pairs × 18 × %.1f in)\n", out_path, n_rows, plot_height))
