#!/usr/bin/env Rscript

# run-dqd.R
# Runs Data Quality Dashboard and exports results for Ares
# Part of consolidated HADES service

library(DataQualityDashboard)
library(DatabaseConnector)

cat("========================================\n")
cat("OHDSI Data Quality Dashboard\n")
cat("========================================\n\n")

# Get environment variables (unified from docker-compose)
uri <- Sys.getenv("HADES_DB_URI")
cdm_schema <- Sys.getenv("CDM_SCHEMA", "cdm")
vocab_schema <- Sys.getenv("VOCAB_SCHEMA", "cdm")
results_schema <- Sys.getenv("RESULTS_SCHEMA", "ohdsi_results")
cdm_version <- Sys.getenv("CDM_VERSION", "5.4")
cdm_source_name <- Sys.getenv("CDM_SOURCE_NAME", "OMOP Development")
ares_output_dir <- Sys.getenv("ARES_OUTPUT_DIR", "/ares-data")
view_results <- Sys.getenv("VIEW_RESULTS", "false")

cat("Configuration:\n")
cat(sprintf("  CDM Schema: %s\n", cdm_schema))
cat(sprintf("  Vocabulary Schema: %s\n", vocab_schema))
cat(sprintf("  Results Schema: %s\n", results_schema))
cat(sprintf("  CDM Version: %s\n", cdm_version))
cat(sprintf("  Source Name: %s\n", cdm_source_name))
cat(sprintf("  Ares Output: %s\n\n", ares_output_dir))

# Create connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  connectionString = uri,
  pathToDriver = "/opt/jdbc"
)

# Test connection
cat("Testing database connection...\n")
tryCatch({
  connection <- DatabaseConnector::connect(connectionDetails)
  cat("✓ Database connection successful\n\n")
  DatabaseConnector::disconnect(connection)
}, error = function(e) {
  cat("✗ Database connection failed:\n")
  cat(sprintf("  %s\n", e$message))
  quit(status = 1)
})

# Get source release key and determine output folder
cat("Getting source release key...\n")
sourceReleaseKey <- ""
datasourceReleaseOutputFolder <- ares_output_dir

if (requireNamespace("AresIndexer", quietly = TRUE)) {
  tryCatch({
    sourceReleaseKey <- AresIndexer::getSourceReleaseKey(connectionDetails, cdm_schema)
    datasourceReleaseOutputFolder <- file.path(ares_output_dir, sourceReleaseKey)
    cat(sprintf("Source release key: %s\n", sourceReleaseKey))
  }, error = function(e) {
    cat("⚠ Could not get source release key, using base directory\n")
  })
} else {
  cat("⚠ AresIndexer not available, using base directory\n")
}

cat(sprintf("Output folder: %s\n\n", datasourceReleaseOutputFolder))

# Create output directory
if (!dir.exists(datasourceReleaseOutputFolder)) {
  dir.create(datasourceReleaseOutputFolder, recursive = TRUE)
  cat(sprintf("Created output directory: %s\n\n", datasourceReleaseOutputFolder))
}

# Run Data Quality Dashboard
cat("========================================\n")
cat("Running Data Quality Checks\n")
cat("========================================\n")
cat("This may take 10-30 minutes depending on data size...\n\n")

tryCatch({
  # Following official documentation parameters
  dqd_results <- DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdm_schema,
    resultsDatabaseSchema = results_schema,
    vocabDatabaseSchema = vocab_schema,
    cdmSourceName = cdm_source_name,
    numThreads = 1,
    outputFolder = datasourceReleaseOutputFolder,
    outputFile = "dq-result.json",  # Official filename
    verboseMode = TRUE,
    writeToTable = FALSE,  # Don't write to table (as per official docs)
    cdmVersion = cdm_version
  )

  cat("\n✓ Data Quality Dashboard completed successfully\n\n")

  # Print summary
  cat("Results Summary:\n")
  cat(sprintf("  Total Checks: %d\n", nrow(dqd_results)))
  if ("PASSED" %in% names(dqd_results)) {
    cat(sprintf("  Passed: %d\n", sum(dqd_results$PASSED == 1, na.rm = TRUE)))
    cat(sprintf("  Failed: %d\n", sum(dqd_results$FAILED == 1, na.rm = TRUE)))
  }
  cat("\n")

}, error = function(e) {
  cat("\n✗ Data Quality Dashboard failed:\n")
  cat(sprintf("  %s\n", e$message))
  quit(status = 1)
})

# Verify output file exists
dq_result_path <- file.path(datasourceReleaseOutputFolder, "dq-result.json")
if (file.exists(dq_result_path)) {
  cat(sprintf("✓ DQD results saved to: %s\n\n", dq_result_path))
} else {
  cat(sprintf("⚠ Warning: DQD results file not found at: %s\n\n", dq_result_path))
}

# Optionally view results in Shiny app
if (tolower(view_results) == "true") {
  cat("========================================\n")
  cat("Launching DQD Shiny Viewer\n")
  cat("========================================\n")
  cat("Access at: http://localhost:3838\n")
  cat("Press Ctrl+C to stop the viewer\n\n")

  tryCatch({
    DataQualityDashboard::viewDqDashboard(
      jsonPath = dq_result_path,
      port = 3838,
      host = "0.0.0.0",
      launch.browser = FALSE
    )
  }, error = function(e) {
    cat("Failed to launch Shiny viewer:\n")
    cat(sprintf("  %s\n", e$message))
  })
}

cat("\n========================================\n")
cat("Data Quality Dashboard Complete!\n")
cat("========================================\n\n")
cat(sprintf("Results saved to: %s\n", dq_result_path))
cat("\nNext steps:\n")
cat("  1. Run AresIndexer to build complete index\n")
cat("  2. View results in Ares at http://localhost:8082\n\n")