#!/usr/bin/env Rscript

# manual-export-achilles-fixed.R
# Manual export of Achilles results to Ares format
# Fixed version that creates its own source release key

library(DatabaseConnector)
library(jsonlite)

cat("========================================\n")
cat("Manual Achilles Export to Ares\n")
cat("========================================\n\n")

# Get environment variables
uri <- Sys.getenv("HADES_DB_URI")
cdm_schema <- Sys.getenv("CDM_SCHEMA", "cdm")
results_schema <- Sys.getenv("RESULTS_SCHEMA", "ohdsi_results")
vocab_schema <- Sys.getenv("VOCAB_SCHEMA", "cdm")
ares_output_dir <- Sys.getenv("ARES_OUTPUT_DIR", "/ares-data")
cdm_source_name <- Sys.getenv("CDM_SOURCE_NAME", "OMOP Development")

cat("Configuration:\n")
cat(sprintf("  Output: %s\n", ares_output_dir))
cat(sprintf("  CDM Schema: %s\n", cdm_schema))
cat(sprintf("  Results Schema: %s\n\n", results_schema))

# Create connection
cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  connectionString = uri,
  pathToDriver = "/opt/jdbc"
)

cat("Step 1/5: Creating source release key...\n")
connection <- DatabaseConnector::connect(cd)

# Get CDM source information to build release key
cdmSourceSql <- "SELECT * FROM @cdm_schema.cdm_source LIMIT 1"
cdmSourceData <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  cdmSourceSql,
  cdm_schema = cdm_schema,
  snakeCaseToCamelCase = TRUE
)

# Get vocabulary version
vocabSql <- "SELECT vocabulary_version FROM @vocab_schema.vocabulary WHERE vocabulary_id = 'None' LIMIT 1"
vocabData <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  vocabSql,
  vocab_schema = vocab_schema,
  snakeCaseToCamelCase = TRUE
)

# Build source release key manually
cdmVersion <- "5.4"
vocabVersion <- if(nrow(vocabData) > 0 && !is.na(vocabData$vocabularyVersion[1])) {
  gsub(" ", "_", vocabData$vocabularyVersion[1])
} else {
  "unknown"
}

cdmReleaseDate <- if(nrow(cdmSourceData) > 0 && !is.na(cdmSourceData$cdmReleaseDate[1])) {
  format(as.Date(cdmSourceData$cdmReleaseDate[1]), "%Y%m%d")
} else {
  format(Sys.Date(), "%Y%m%d")
}

# Create source release key in format: SourceName-vCDMVersion-VOCABVersion-ReleaseDate
sourceNameClean <- gsub("[^A-Za-z0-9]", "_", cdm_source_name)
sourceReleaseKey <- sprintf("%s-v%s-VOCAB_%s-%s",
                            sourceNameClean,
                            cdmVersion,
                            vocabVersion,
                            cdmReleaseDate)

cat(sprintf("  Source release key: %s\n\n", sourceReleaseKey))

# Create output folder
outputFolder <- file.path(ares_output_dir, sourceReleaseKey)
cat(sprintf("  Creating folder: %s\n", outputFolder))

if (!dir.exists(outputFolder)) {
  dir.create(outputFolder, recursive = TRUE)
  cat("  ✓ Folder created\n\n")
} else {
  cat("  ✓ Folder already exists\n\n")
}

cat("Step 2/5: Creating datasource.json...\n")

datasource <- list(
  name = cdm_source_name,
  releaseKey = sourceReleaseKey,
  cdmReleaseDate = if(nrow(cdmSourceData) > 0 && !is.na(cdmSourceData$cdmReleaseDate[1]))
    as.character(cdmSourceData$cdmReleaseDate[1]) else as.character(Sys.Date()),
  cdmVersion = cdmVersion,
  vocabularyVersion = vocabVersion,
  cdmSourceName = if(nrow(cdmSourceData) > 0 && !is.na(cdmSourceData$cdmSourceName[1]))
    cdmSourceData$cdmSourceName[1] else cdm_source_name
)

jsonlite::write_json(
  datasource,
  file.path(outputFolder, "datasource.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)
cat("  ✓ datasource.json created\n\n")

cat("Step 3/5: Exporting Achilles results...\n")
cat("  This exports all results, may take 2-3 minutes...\n\n")

domainFolder <- file.path(outputFolder, "domain")
if (!dir.exists(domainFolder)) {
  dir.create(domainFolder, recursive = TRUE)
}

# Get all unique analysis IDs
analysesSql <- "SELECT DISTINCT analysis_id FROM @results_schema.achilles_results ORDER BY analysis_id"
analyses <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  analysesSql,
  results_schema = results_schema,
  snakeCaseToCamelCase = TRUE
)

cat(sprintf("  Found %d unique analyses to export\n", nrow(analyses)))

# Export each analysis
exportCount <- 0
for(i in 1:nrow(analyses)) {
  aid <- analyses$analysisId[i]

  resultSql <- "SELECT * FROM @results_schema.achilles_results WHERE analysis_id = @aid"
  results <- DatabaseConnector::renderTranslateQuerySql(
    connection,
    resultSql,
    results_schema = results_schema,
    aid = aid,
    snakeCaseToCamelCase = TRUE
  )

  if(nrow(results) > 0) {
    outputFile <- file.path(domainFolder, sprintf("analysis_%d.json", aid))
    jsonlite::write_json(results, outputFile, auto_unbox = TRUE)
    exportCount <- exportCount + 1
  }

  if(i %% 50 == 0) {
    cat(sprintf("    Progress: %d/%d analyses (%d%%)\n", i, nrow(analyses), round(100*i/nrow(analyses))))
  }
}

cat(sprintf("  ✓ Exported %d analyses\n\n", exportCount))

cat("Step 4/5: Exporting Achilles analysis metadata...\n")

# Export achilles_analysis table
analysisMetaSql <- "SELECT * FROM @results_schema.achilles_analysis"
analysisMeta <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  analysisMetaSql,
  results_schema = results_schema,
  snakeCaseToCamelCase = TRUE
)

if(nrow(analysisMeta) > 0) {
  jsonlite::write_json(
    analysisMeta,
    file.path(outputFolder, "achilles_analysis.json"),
    auto_unbox = TRUE
  )
  cat(sprintf("  ✓ Exported %d analysis definitions\n\n", nrow(analysisMeta)))
}

cat("Step 5/5: Running temporal characterization...\n")
tempCharFile <- file.path(outputFolder, "temporal-characterization.csv")

# Query temporal data - using a simpler approach
tempSql <- "
SELECT analysis_id, stratum_1, stratum_2, count_value
FROM @results_schema.achilles_results
WHERE analysis_id BETWEEN 1800 AND 1899
ORDER BY analysis_id, stratum_1, stratum_2
"

tempResults <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  tempSql,
  results_schema = results_schema,
  snakeCaseToCamelCase = TRUE
)

if(nrow(tempResults) > 0) {
  write.csv(tempResults, tempCharFile, row.names = FALSE)
  cat(sprintf("  ✓ Temporal characterization saved (%d rows)\n\n", nrow(tempResults)))
} else {
  cat("  ⚠ No temporal characterization data found\n\n")
}

DatabaseConnector::disconnect(connection)

cat("========================================\n")
cat("Export Complete!\n")
cat("========================================\n\n")

cat("Summary:\n")
cat(sprintf("  Source release key: %s\n", sourceReleaseKey))
cat(sprintf("  Output folder: %s\n", outputFolder))
cat(sprintf("  Analyses exported: %d\n", exportCount))

cat("\nFiles created:\n")
system(paste("ls -lh", outputFolder))

cat("\nDirectory structure:\n")
system(paste("find", outputFolder, "-type f | head -20"))

cat("\n\nNext step: Run AresIndexer\n")
cat("Command: docker compose --profile tools run --rm hades Rscript /app/run-ares-indexer.R\n\n")