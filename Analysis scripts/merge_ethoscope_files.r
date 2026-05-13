# ===================================================================
# Merge All Ethoscope Processed Files
# ===================================================================

# Set folder path where your processed .txt files are located
folder <- "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output"

# List of files to merge (add or remove as needed)
files <- c(
  "ethoscope_007.txt",
  "ethoscope_008.txt",
  "ethoscope_009.txt",
  "ethoscope_010.txt",
  "ethoscope_011.txt",
  "ethoscope_012.txt",
  "ethoscope_013.txt",
  "ethoscope_014.txt",
  "ethoscope_015.txt"
)

# ===================================================================
# MERGE ALL FILES
# ===================================================================

cat("Merging ethoscope files...\n\n")

all_data <- data.frame()

for (f in files) {
  file_path <- file.path(folder, f)
  
  if (file.exists(file_path)) {
    temp <- read.delim(file_path, header = TRUE)
    all_data <- rbind(all_data, temp)
    cat("✓ Added:", f, "-", nrow(temp), "rows\n")
  } else {
    cat("✗ NOT FOUND:", f, "\n")
  }
}

cat("\n================================\n")
cat("Total rows:", nrow(all_data), "\n")
cat("================================\n")

# ===================================================================
# SAVE MERGED FILE
# ===================================================================

output_file <- file.path(folder, "all_ethoscopes_merged_04MAY.txt")

write.table(
  all_data, 
  file = output_file,
  sep = "\t", 
  row.names = FALSE, 
  quote = FALSE
)

cat("\n✓ Saved:", output_file, "\n")