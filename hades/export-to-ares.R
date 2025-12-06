#!/usr/bin/env Rscript

# export-to-ares.R
# Exports Achilles results to Ares format using PostgreSQL-compatible function
#
# Run this AFTER Achilles has already completed.
#
# Usage:
#   docker compose --profile tools run --rm hades Rscript /app/export-to-ares.R

library(DatabaseConnector)

cat("========================================\n")
cat("Export Achilles Results to Ares\n")
cat("PostgreSQL-Compatible Version\n")
cat("========================================\n\n")

# Get environment variables
uri <- Sys.getenv("HADES_DB_URI")
cdm_schema <- Sys.getenv("CDM_SCHEMA", "cdm")
vocab_schema <- Sys.getenv("VOCAB_SCHEMA", "cdm")
results_schema <- Sys.getenv("RESULTS_SCHEMA", "ohdsi_results")
ares_output_dir <- Sys.getenv("ARES_OUTPUT_DIR", "/ares-data")

cat("Configuration:\n")
cat(sprintf("  CDM Schema: %s\n", cdm_schema))
cat(sprintf("  Vocabulary Schema: %s\n", vocab_schema))
cat(sprintf("  Results Schema: %s\n", results_schema))
cat(sprintf("  Ares Output: %s\n\n", ares_output_dir))

# Check if Achilles results exist
cat("Checking for Achilles results...\n")
cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  connectionString = uri,
  pathToDriver = "/opt/jdbc"
)

connection <- DatabaseConnector::connect(cd)
resultCount <- DatabaseConnector::querySql(
  connection,
  sprintf("SELECT COUNT(*) as count FROM %s.achilles_results", results_schema)
)
DatabaseConnector::disconnect(connection)

if (resultCount$COUNT[1] == 0) {
  cat("✗ No Achilles results found!\n")
  cat("  Please run Achilles first:\n")
  cat("  docker compose --profile tools run --rm hades Rscript /app/run-achilles.R\n\n")
  quit(status = 1)
}

cat(sprintf("✓ Found %s Achilles results\n\n", format(resultCount$COUNT[1], big.mark=",")))

# Load the patched exportToAres function
cat("Loading PostgreSQL-compatible exportToAres function...\n")
if (!file.exists("/app/exportToAres-patched.R")) {
  cat("✗ Patched function not found!\n")
  cat("  Expected: /app/exportToAres-patched.R\n")
  cat("  Please ensure the file is copied to the hades/ directory\n\n")
  quit(status = 1)
}

source("/app/exportToAres-patched.R")
cat("✓ Patched function loaded\n\n")

# Create output directory
if (!dir.exists(ares_output_dir)) {
  dir.create(ares_output_dir, recursive = TRUE)
  cat(sprintf("Created directory: %s\n\n", ares_output_dir))
}

# Run the export
cat("========================================\n")
cat("Exporting to Ares Format\n")
cat("========================================\n")
cat("This may take 10-30 minutes...\n\n")

tryCatch({
  # Call the PATCHED exportToAres function
  exportToAres(
    connectionDetails = cd,
    cdmDatabaseSchema = cdm_schema,
    resultsDatabaseSchema = results_schema,
    vocabDatabaseSchema = vocab_schema,
    outputPath = ares_output_dir
  )

  cat("\n========================================\n")
  cat("✓ Export Complete!\n")
  cat("========================================\n\n")

  # Show results
  cat("Checking exported files...\n")
  system(paste("find", ares_output_dir, "-type d -maxdepth 1 ! -path", ares_output_dir))

  fileCount <- system(paste("find", ares_output_dir, "-type f | wc -l"), intern = TRUE)
  cat(sprintf("\nTotal files created: %s\n\n", fileCount))

  cat("Next steps:\n")
  cat("  1. (Optional) Run AresIndexer:\n")
  cat("     docker compose --profile tools run --rm hades Rscript /app/run-ares-indexer.R\n\n")
  cat("  2. View in Ares:\n")
  cat("     http://localhost:8082\n\n")
  cat("  3. Or view in Atlas (no indexing needed):\n")
  cat("     http://localhost:8081\n\n")

}, error = function(e) {
  cat("\n========================================\n")
  cat("✗ Export Failed\n")
  cat("========================================\n\n")
  cat(sprintf("Error: %s\n\n", e$message))
  cat("Troubleshooting:\n")
  cat("  1. Verify Achilles results exist in database\n")
  cat("  2. Check database connection settings\n")
  cat("  3. Ensure exportToAres-patched.R is in hades/ directory\n")
  cat("  4. Check /ares-data directory permissions\n\n")
  quit(status = 1)
})