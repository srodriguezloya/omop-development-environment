#!/usr/bin/env Rscript

# run-ares-indexer.R
# Final step to build Ares index after Achilles and DQD complete
# Part of consolidated HADES service
# Based on official OHDSI Ares documentation

library(AresIndexer)
library(DatabaseConnector)

cat("========================================\n")
cat("OHDSI AresIndexer\n")
cat("========================================\n\n")

# Get environment variables (unified from docker-compose)
ares_data_dir <- Sys.getenv("ARES_OUTPUT_DIR", "/ares-data")
uri <- Sys.getenv("HADES_DB_URI", "")
cdm_schema <- Sys.getenv("CDM_SCHEMA", "cdm")

cat("Configuration:\n")
cat(sprintf("  Ares Data Directory: %s\n", ares_data_dir))
cat(sprintf("  CDM Schema: %s\n\n", cdm_schema))

# Verify ares data directory exists
if (!dir.exists(ares_data_dir)) {
  cat("✗ Error: Ares data directory not found\n")
  cat(sprintf("  Expected: %s\n", ares_data_dir))
  cat("\nPlease run Achilles and DQD first.\n")
  quit(status = 1)
}

# Get list of source folders
cat("Scanning for data sources...\n")
list <- list.dirs(ares_data_dir, recursive = FALSE)

if (length(list) == 0) {
  cat("✗ No data sources found\n")
  cat("\nPlease run Achilles and DQD first to generate data.\n")
  quit(status = 1)
}

cat(sprintf("Found %d data source(s):\n", length(list)))
for (source in list) {
  cat(sprintf("  - %s\n", basename(source)))
}
cat("\n")

# Create connection if URI provided (for augmenting concept files)
cd <- NULL
if (nzchar(uri)) {
  cat("Creating database connection for concept augmentation...\n")
  tryCatch({
    cd <- DatabaseConnector::createConnectionDetails(
      dbms = "postgresql",
      connectionString = uri,
      pathToDriver = "/opt/jdbc"
    )
    connection <- DatabaseConnector::connect(cd)
    cat("✓ Database connection successful\n\n")
    DatabaseConnector::disconnect(connection)
  }, error = function(e) {
    cat("⚠ Warning: Could not connect to database\n")
    cat("  Concept augmentation will be skipped\n\n")
    cd <- NULL
  })
}

# Build Ares index following official documentation
cat("========================================\n")
cat("Building Ares Index\n")
cat("========================================\n\n")

# Step 1: Augment concept files with data quality details
cat("Step 1/7: Augmenting concept files...\n")
for (source_folder in list) {
  tryCatch({
    AresIndexer::augmentConceptFiles(releaseFolder = source_folder)
    cat(sprintf("  ✓ Augmented: %s\n", basename(source_folder)))
  }, error = function(e) {
    cat(sprintf("  ⚠ Warning: Could not augment %s\n", basename(source_folder)))
    cat(sprintf("    %s\n", e$message))
  })
}
cat("\n")

# Step 2: Export index of all SQL functions used in data processing
cat("Step 2/7: Building export query index...\n")
tryCatch({
  AresIndexer::buildExportQueryIndex(ares_data_dir)
  cat("  ✓ Export query index built\n\n")
}, error = function(e) {
  cat("  ⚠ Warning: Could not build export query index\n")
  cat(sprintf("    %s\n\n", e$message))
})

# Step 3: Compare data quality issues with previous source releases
cat("Step 3/7: Augmenting data quality files...\n")
tryCatch({
  AresIndexer::augmentDataQualityFiles(sourceFolders = list)
  cat("  ✓ Data quality files augmented\n\n")
}, error = function(e) {
  cat("  ⚠ Warning: Could not augment data quality files\n")
  cat(sprintf("    %s\n\n", e$message))
})

# Step 4: Create index of quality issues across releases
cat("Step 4/7: Building source data quality delta...\n")
tryCatch({
  AresIndexer::buildSourceDataQualityDelta(sourceFolders = list)
  cat("  ✓ Data quality delta built\n\n")
}, error = function(e) {
  cat("  ⚠ Warning: Could not build data quality delta\n")
  cat(sprintf("    %s\n\n", e$message))
})

# Step 5: Create index of all available sources and releases
cat("Step 5/7: Building network index...\n")
tryCatch({
  AresIndexer::buildNetworkIndex(list, outputFolder = ares_data_dir)
  cat("  ✓ Network index built\n\n")
}, error = function(e) {
  cat("  ✗ Error: Could not build network index\n")
  cat(sprintf("    %s\n\n", e$message))
  quit(status = 1)
})

# Step 6: Create quality index across network
cat("Step 6/7: Building data quality index...\n")
tryCatch({
  AresIndexer::buildDataQualityIndex(list, outputFolder = ares_data_dir)
  cat("  ✓ Data quality index built\n\n")
}, error = function(e) {
  cat("  ⚠ Warning: Could not build data quality index\n")
  cat(sprintf("    %s\n\n", e$message))
})

# Step 7: Create index of unmapped source codes across the network
cat("Step 7/7: Building unmapped source code index...\n")
tryCatch({
  AresIndexer::buildNetworkUnmappedSourceCodeIndex(list, outputFolder = ares_data_dir)
  cat("  ✓ Unmapped source code index built\n\n")
}, error = function(e) {
  cat("  ⚠ Warning: Could not build unmapped source code index\n")
  cat(sprintf("    %s\n\n", e$message))
})

# List generated files
cat("========================================\n")
cat("Index Files Generated\n")
cat("========================================\n\n")

index_files <- list.files(ares_data_dir, pattern = "*.json", full.names = FALSE)
if (length(index_files) > 0) {
  cat("Network-level index files:\n")
  for (f in index_files) {
    cat(sprintf("  - %s\n", f))
  }
} else {
  cat("⚠ No index files found\n")
}

cat("\n========================================\n")
cat("Ares Indexing Complete!\n")
cat("========================================\n\n")
cat("Ares is now ready to view your data.\n")
cat("Access Ares at: http://localhost:8082\n\n")
cat("The following data sources are available:\n")
for (source in list) {
  cat(sprintf("  - %s\n", basename(source)))
}
cat("\n")