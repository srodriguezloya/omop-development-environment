#!/usr/bin/env Rscript

# run-achilles.R
# Runs Achilles characterization and exports for Ares
# Part of consolidated HADES service

library(Achilles)
library(DatabaseConnector)

cat("========================================\n")
cat("OHDSI Achilles Data Characterization\n")
cat("========================================\n\n")

# Get environment variables (unified from docker-compose)
uri <- Sys.getenv("HADES_DB_URI")
cdm_schema <- Sys.getenv("CDM_SCHEMA", "cdm")
vocab_schema <- Sys.getenv("VOCAB_SCHEMA", "cdm")
results_schema <- Sys.getenv("RESULTS_SCHEMA", "ohdsi_results")
cdm_version <- Sys.getenv("CDM_VERSION", "5.4")
ares_output_dir <- Sys.getenv("ARES_OUTPUT_DIR", "/ares-data")
cdm_source_name <- Sys.getenv("CDM_SOURCE_NAME", "OMOP Development")

cat("Configuration:\n")
cat(sprintf("  CDM Schema: %s\n", cdm_schema))
cat(sprintf("  Vocabulary Schema: %s\n", vocab_schema))
cat(sprintf("  Results Schema: %s\n", results_schema))
cat(sprintf("  CDM Version: %s\n", cdm_version))
cat(sprintf("  Source Name: %s\n", cdm_source_name))
cat(sprintf("  Ares Output: %s\n\n", ares_output_dir))

# Create connection details
cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  connectionString = uri,
  pathToDriver = "/opt/jdbc"
)

# Test connection
cat("Testing database connection...\n")
tryCatch({
  connection <- DatabaseConnector::connect(cd)
  cat("✓ Database connection successful\n\n")
  DatabaseConnector::disconnect(connection)
}, error = function(e) {
  cat("✗ Database connection failed:\n")
  cat(sprintf("  %s\n", e$message))
  quit(status = 1)
})

# Run Achilles
cat("========================================\n")
cat("Step 1: Running Achilles Analysis\n")
cat("========================================\n")
cat("This may take several minutes...\n\n")

tryCatch({
  Achilles::achilles(
    connectionDetails = cd,
    cdmDatabaseSchema = cdm_schema,
    vocabDatabaseSchema = vocab_schema,
    resultsDatabaseSchema = results_schema,
    cdmVersion = cdm_version,
    sourceName = cdm_source_name,
    numThreads = 1,
    createIndices = FALSE,
    createTable = TRUE,
    smallCellCount = 0
  )

  cat("\n✓ Achilles analysis completed successfully\n\n")
}, error = function(e) {
  cat("\n✗ Achilles analysis failed:\n")
  cat(sprintf("  %s\n", e$message))
  quit(status = 1)
})

# Export results for Ares (following official documentation)
cat("========================================\n")
cat("Step 2: Exporting for Ares\n")
cat("========================================\n\n")

# Create output directory if it doesn't exist
if (!dir.exists(ares_output_dir)) {
  dir.create(ares_output_dir, recursive = TRUE)
  cat(sprintf("Created directory: %s\n", ares_output_dir))
}

# Add this line to normalize the path right before the problematic function call
normalized_ares_path <- normalizePath(ares_output_dir, mustWork = FALSE)
cat(sprintf("Using normalized path: %s\n", normalized_ares_path))

tryCatch({
  # Export Achilles results to Ares format (official method)
  cat("Exporting Achilles results to Ares format...\n")

  Achilles::exportToAres(
    connectionDetails = cd,
    cdmDatabaseSchema = cdm_schema,
    resultsDatabaseSchema = results_schema,
    vocabDatabaseSchema = vocab_schema,
    outputPath = normalized_ares_path # <-- Use the normalized path
  )

  cat("✓ Achilles results exported\n\n")

  # Get source release key
  cat("Getting source release key...\n")
  if (requireNamespace("AresIndexer", quietly = TRUE)) {
    sourceReleaseKey <- AresIndexer::getSourceReleaseKey(cd, cdm_schema)
    datasourceReleaseOutputFolder <- file.path(ares_output_dir, sourceReleaseKey)

    cat(sprintf("Source release key: %s\n", sourceReleaseKey))
    cat(sprintf("Output folder: %s\n\n", datasourceReleaseOutputFolder))

    # Run temporal characterization (official recommendation)
    cat("Running temporal characterization...\n")
    outputFile <- file.path(datasourceReleaseOutputFolder, "temporal-characterization.csv")

    Achilles::performTemporalCharacterization(
      connectionDetails = cd,
      cdmDatabaseSchema = cdm_schema,
      resultsDatabaseSchema = results_schema,
      outputFile = outputFile
    )

    cat("✓ Temporal characterization complete\n\n")
  } else {
    cat("⚠ AresIndexer not available, skipping temporal characterization\n\n")
  }

}, error = function(e) {
  cat("\n✗ Export to Ares failed:\n")
  cat(sprintf("  %s\n", e$message))
  cat("\nNote: Results are still available in the database\n")
  cat(sprintf("Schema: %s\n", results_schema))
})

cat("\n========================================\n")
cat("Achilles Process Complete!\n")
cat("========================================\n\n")
cat(sprintf("Results stored in schema: %s\n", results_schema))
cat(sprintf("Ares data exported to: %s\n\n", ares_output_dir))
cat("Next steps:\n")
cat("  1. Run Data Quality Dashboard\n")
cat("  2. Run AresIndexer to build complete index\n")
cat("  3. View results in Atlas at http://localhost:8081\n")
cat("  4. View visualizations in Ares at http://localhost:8082\n\n")