#!/usr/bin/env Rscript

# manual-export-achilles-fixed.R
# Enhanced manual export that creates files in format AresIndexer expects

library(DatabaseConnector)
library(jsonlite)

cat("========================================\n")
cat("Enhanced Manual Achilles Export\n")
cat("Compatible with AresIndexer\n")
cat("========================================\n\n")

# Get environment variables
uri <- Sys.getenv("HADES_DB_URI")
cdm_schema <- Sys.getenv("CDM_SCHEMA", "cdm")
results_schema <- Sys.getenv("RESULTS_SCHEMA", "ohdsi_results")
vocab_schema <- Sys.getenv("VOCAB_SCHEMA", "cdm")
ares_output_dir <- Sys.getenv("ARES_OUTPUT_DIR", "/ares-data")
cdm_source_name <- Sys.getenv("CDM_SOURCE_NAME", "OMOP_Dev")

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

connection <- DatabaseConnector::connect(cd)

cat("Step 1: Creating source release key...\n")

# Get CDM source information
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

# Build release key
cdmVersion <- "5.4"
vocabVersion <- if(nrow(vocabData) > 0) gsub(" ", "_", vocabData$vocabularyVersion[1]) else "unknown"
cdmReleaseDate <- if(nrow(cdmSourceData) > 0) format(as.Date(cdmSourceData$cdmReleaseDate[1]), "%Y%m%d") else format(Sys.Date(), "%Y%m%d")

# Simple folder name format that AresIndexer can parse
outputFolder <- file.path(ares_output_dir, cdm_source_name)

cat(sprintf("  Output folder: %s\n", outputFolder))

if (!dir.exists(outputFolder)) {
  dir.create(outputFolder, recursive = TRUE)
  cat("  ✓ Folder created\n\n")
} else {
  cat("  ✓ Folder exists\n\n")
}

cat("Step 2: Creating metadata files...\n")

# Create datasource.json
datasource <- list(
  name = cdm_source_name,
  cdmVersion = cdmVersion,
  vocabularyVersion = vocabVersion,
  cdmReleaseDate = if(nrow(cdmSourceData) > 0) as.character(cdmSourceData$cdmReleaseDate[1]) else as.character(Sys.Date())
)

jsonlite::write_json(
  datasource,
  file.path(outputFolder, "datasource.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

# Create metadata.csv
metadataDF <- data.frame(
  CDM_SOURCE_NAME = if(nrow(cdmSourceData) > 0) cdmSourceData$cdmSourceName[1] else cdm_source_name,
  CDM_VERSION = cdmVersion,
  VOCABULARY_VERSION = vocabVersion,
  CDM_RELEASE_DATE = if(nrow(cdmSourceData) > 0) as.character(cdmSourceData$cdmReleaseDate[1]) else as.character(Sys.Date()),
  stringsAsFactors = FALSE
)
write.csv(metadataDF, file.path(outputFolder, "metadata.csv"), row.names = FALSE)

# Create cdmsource.csv
if(nrow(cdmSourceData) > 0) {
  write.csv(cdmSourceData, file.path(outputFolder, "cdmsource.csv"), row.names = FALSE)
}

cat("  ✓ Metadata files created\n\n")

cat("Step 3: Exporting temporal characterization...\n")

tempSql <- "
SELECT
  analysis_id,
  stratum_1,
  stratum_2,
  stratum_3,
  stratum_4,
  stratum_5,
  count_value
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
  write.csv(tempResults, file.path(outputFolder, "temporal-characterization.csv"), row.names = FALSE)
  cat(sprintf("  ✓ Temporal data exported (%d rows)\n\n", nrow(tempResults)))
} else {
  cat("  ⚠ No temporal data found\n\n")
}

cat("Step 4: Creating person summary...\n")

# Simple person stats
personSql <- "
SELECT
  COUNT(*) as total_persons,
  COUNT(DISTINCT gender_concept_id) as gender_count,
  COUNT(DISTINCT race_concept_id) as race_count,
  MIN(year_of_birth) as min_year,
  MAX(year_of_birth) as max_year
FROM @cdm_schema.person
"

personStats <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  personSql,
  cdm_schema = cdm_schema,
  snakeCaseToCamelCase = TRUE
)

personSummary <- list(
  totalPersons = personStats$totalPersons[1],
  genderCount = personStats$genderCount[1],
  raceCount = personStats$raceCount[1],
  yearRange = c(personStats$minYear[1], personStats$maxYear[1])
)

jsonlite::write_json(
  personSummary,
  file.path(outputFolder, "person.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

cat("  ✓ Person summary created\n\n")

cat("Step 5: Exporting analysis results...\n")

# Get all unique analysis IDs
analysesSql <- "SELECT DISTINCT analysis_id FROM @results_schema.achilles_results ORDER BY analysis_id"
analyses <- DatabaseConnector::renderTranslateQuerySql(
  connection,
  analysesSql,
  results_schema = results_schema,
  snakeCaseToCamelCase = TRUE
)

cat(sprintf("  Found %d unique analyses\n", nrow(analyses)))

# Create export query file (this is what AresIndexer needs!)
exportQueries <- data.frame(
  analysis_id = analyses$analysisId,
  stringsAsFactors = FALSE
)

write.csv(exportQueries, file.path(outputFolder, "export-query.csv"), row.names = FALSE)
cat("  ✓ Export query index created\n\n")

DatabaseConnector::disconnect(connection)

cat("========================================\n")
cat("✓ Export Complete!\n")
cat("========================================\n\n")

cat("Created files:\n")
system(paste0("ls -lh '", outputFolder, "'"))

cat("\n\nThis export is compatible with AresIndexer!\n")
cat("Next step:\n")
cat("  docker compose --profile tools run --rm hades Rscript /app/run-ares-indexer.R\n\n")