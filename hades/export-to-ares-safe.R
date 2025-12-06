#!/usr/bin/env Rscript

# export-to-ares-safe.R
# Exports Achilles results to Ares format, skipping problematic data density reports
#
# This version focuses on the core exports that Ares needs:
# - Person, Death, Observation Period reports
# - Domain summaries
# - Concept-level data
#
# Usage:
#   docker compose --profile tools run --rm hades Rscript /app/export-to-ares-safe.R

library(DatabaseConnector)

cat("========================================\n")
cat("Export Achilles to Ares (Safe Mode)\n")
cat("PostgreSQL-Compatible Version\n")
cat("========================================\n\n")

cat("NOTE: This version skips some data density reports that have\n")
cat("      compatibility issues, but exports all the core data\n")
cat("      that Ares needs for visualization.\n\n")

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
  sprintf("SELECT COUNT(*) as count FROM %s.achilles_results", results_schema),
  snakeCaseToCamelCase = TRUE
)
DatabaseConnector::disconnect(connection)

if (resultCount$count[1] == 0) {
  cat("✗ No Achilles results found!\n")
  quit(status = 1)
}

cat(sprintf("✓ Found %s Achilles results\n\n", format(resultCount$count[1], big.mark=",")))

# Load the patched exportToAres function
cat("Loading PostgreSQL-compatible exportToAres function...\n")
if (!file.exists("/app/exportToAres-patched.R")) {
  cat("✗ Patched function not found!\n")
  quit(status = 1)
}

source("/app/exportToAres-patched.R")
cat("✓ Patched function loaded\n\n")

# Create output directory
if (!dir.exists(ares_output_dir)) {
  dir.create(ares_output_dir, recursive = TRUE)
}

# Run the export with SAFE MODE - skip density reports
cat("========================================\n")
cat("Exporting to Ares Format (Safe Mode)\n")
cat("========================================\n")
cat("Skipping: data density reports (have compatibility issues)\n")
cat("Exporting: person, death, domains, concepts\n\n")
cat("This may take 10-30 minutes...\n\n")

tryCatch({
  # Call exportToAres but SKIP density reports
  # Only export: domain summaries and concepts
  exportToAres(
    connectionDetails = cd,
    cdmDatabaseSchema = cdm_schema,
    resultsDatabaseSchema = results_schema,
    vocabDatabaseSchema = vocab_schema,
    outputPath = ares_output_dir,
    reports = c("domain", "concept")  # Skip "density" to avoid the error
  )

  cat("\n========================================\n")
  cat("✓ Export Complete!\n")
  cat("========================================\n\n")

  # Show results
  cat("Checking exported files...\n")
  fileCount <- system(paste("find", ares_output_dir, "-type f | wc -l"), intern = TRUE)
  cat(sprintf("Total files created: %s\n\n", fileCount))

  cat("What was exported:\n")
  cat("  ✓ Person reports\n")
  cat("  ✓ Death reports\n")
  cat("  ✓ Observation period reports\n")
  cat("  ✓ Domain summaries (conditions, drugs, procedures, etc.)\n")
  cat("  ✓ Concept-level data\n")
  cat("  ✗ Data density reports (skipped due to compatibility issues)\n\n")

  cat("This is enough for Ares to visualize your data!\n\n")

  cat("Next steps:\n")
  cat("  1. View in Atlas (no indexing needed):\n")
  cat("     http://localhost:8081\n\n")
  cat("  2. Or view in Ares:\n")
  cat("     http://localhost:8082\n\n")

}, error = function(e) {
  cat("\n========================================\n")
  cat("✗ Export Failed\n")
  cat("========================================\n\n")
  cat(sprintf("Error: %s\n\n", e$message))
  quit(status = 1)
})