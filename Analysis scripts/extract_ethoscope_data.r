library(scopr)
library(data.table)
library(sleepr)
library(RSQLite)

setwd("/Users/aniketsharma/Documents/Ethoscope/Ethoscope/")

output_file <- "Analysis scripts/analysis_output/ethoscope_011.txt"

metadata <- data.table(
  machine_name = "ETHOSCOPE_011",
  date = "2026-06-17",
  region_id = 1:20
)

metadata <- link_ethoscope_metadata(metadata, result_dir = "ethoscope_data/results/")

db_path <- metadata$file_info[[1]]$path

# Fix is_inferred TEXT→INTEGER and detect available ROIs
con <- dbConnect(SQLite(), db_path)
roi_tables <- grep("^ROI_\\d+$", dbListTables(con), value = TRUE)

for (tbl in roi_tables) {
  col_info <- dbGetQuery(con, paste0("PRAGMA table_info(", tbl, ")"))
  if ("is_inferred" %in% col_info$name && col_info$type[col_info$name == "is_inferred"] == "TEXT") {
    col_defs <- sapply(1:nrow(col_info), function(j) {
      ctype <- ifelse(col_info$name[j] == "is_inferred", "INTEGER", col_info$type[j])
      pk    <- ifelse(col_info$pk[j] == 1, " PRIMARY KEY", "")
      paste0(col_info$name[j], " ", ctype, pk)
    })
    new_tbl <- paste0(tbl, "_fix")
    dbExecute(con, paste0("CREATE TABLE ", new_tbl, " (", paste(col_defs, collapse = ", "), ")"))
    dbExecute(con, paste0("INSERT INTO ", new_tbl, " SELECT * FROM ", tbl))
    dbExecute(con, paste0("DROP TABLE ", tbl))
    dbExecute(con, paste0("ALTER TABLE ", new_tbl, " RENAME TO ", tbl))
  }
}

available_rois <- sort(as.integer(sub("ROI_", "", roi_tables)))
dbDisconnect(con)

metadata <- metadata[region_id %in% available_rois]
print(paste("ROIs with data:", paste(available_rois, collapse = ", ")))

dt <- load_ethoscope(metadata, FUN = sleepr::sleep_annotation, verbose = TRUE)

print(paste("Rows:", nrow(dt), "| Individuals:", length(unique(dt$id))))
print(head(dt, 5))

write.table(dt, file = output_file, sep = "\t", row.names = FALSE, quote = FALSE)
print(paste("✓ Exported to:", output_file))