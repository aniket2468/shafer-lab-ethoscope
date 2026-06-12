library(scopr)
library(data.table)
library(sleepr)

setwd("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/")

output_file <- "Analysis scripts/analysis_output/ethoscope_013.txt"

metadata <- data.table(
  machine_name = "ETHOSCOPE_013",
  date = "2026-05-19",
  region_id = 1:20
)

print("Metadata created:")
print(metadata)

print("Linking metadata to database files...")

metadata <- link_ethoscope_metadata(
  metadata, 
  result_dir = "ethoscope_data/results/"
)

print("Metadata linked successfully!")
print(metadata)

print("Loading data and applying sleep annotation...")
print("This may take several minutes...")

dt <- load_ethoscope(
  metadata,
  FUN = sleepr::sleep_annotation,
  verbose = TRUE
)

print("✓ Data loaded successfully!")
print("Summary:")
print(dt)

print("\nColumn names:")
print(names(dt))

print("\nFirst few rows:")
print(head(dt, 20))

write.table(
  dt, 
  file = output_file,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)

print(paste("\n✓ Data exported to:", output_file))
print(paste("✓ Total rows:", nrow(dt)))
print(paste("✓ Unique individuals:", length(unique(dt$id))))