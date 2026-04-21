# Run after extract_ethoscope_data.r
#
# For each individual (id): find first time t with interactions == 1 (real stimulator).
# Keep rows with t >= (that time - 24 hours). Drops everything earlier.
# Flies that never have interactions == 1 are left unchanged (with a message).
#
# Overwrites ethoscope_007.txt in place (copy the raw extract first if you need a backup).

library(data.table)

setwd("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/")

input_file  <- "Analysis scripts/analysis_output/ethoscope_015.txt"
output_file <- input_file

baseline_sec <- 24 * 3600

if (!file.exists(input_file)) {
  stop("Input not found: ", input_file, "\nRun extract_ethoscope_data.r first.")
}

dt <- fread(input_file)
required <- c("id", "t", "interactions")
missing <- setdiff(required, names(dt))
if (length(missing) > 0) {
  stop("Input is missing columns: ", paste(missing, collapse = ", "))
}

dt[, interactions := as.integer(interactions)]

first_stim <- dt[interactions == 1L, .(first_stim_t = min(t)), by = id]
if (nrow(first_stim) == 0L) {
  stop("No rows with interactions == 1; nothing to anchor baseline. Check data or interactor setup.")
}

first_stim[, cutoff_t := first_stim_t - baseline_sec]

dt2 <- first_stim[, .(id, cutoff_t)][dt, on = "id"]
dt2[is.na(cutoff_t), keep := TRUE]
dt2[!is.na(cutoff_t), keep := t >= cutoff_t]

out <- dt2[keep == TRUE][, !c("cutoff_t", "keep")]

no_stim_ids <- setdiff(unique(dt$id), first_stim$id)
if (length(no_stim_ids) > 0L) {
  message(
    length(no_stim_ids), " id(s) had no interactions == 1; left untrimmed: ",
    paste(head(no_stim_ids, 10), collapse = ", "),
    if (length(no_stim_ids) > 10L) ", ..." else ""
  )
}

setorder(out, id, t)

fwrite(out, output_file, sep = "\t", quote = FALSE)

message("Rows before: ", nrow(dt), "  after: ", nrow(out))
message("Overwritten: ", output_file)
