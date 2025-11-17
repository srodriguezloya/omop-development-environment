library(Achilles)
library(DatabaseConnector)

cat("=== Running Achilles ===\n")

uri <- Sys.getenv("ACHILLES_DB_URI")
cdm_schema <- Sys.getenv("ACHILLES_CDM_SCHEMA", "cdm")
results_schema <- Sys.getenv("ACHILLES_RESULTS_SCHEMA", "ohdsi_results")
cdm_version <- Sys.getenv("ACHILLES_CDM_VERSION", "5.4")

cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  connectionString = uri,
  pathToDriver = "/opt/jdbc"
)

cat("Running Achilles on", cdm_schema, "...\n")

achilles(
  connectionDetails = cd,
  cdmDatabaseSchema = cdm_schema,
  resultsDatabaseSchema = results_schema,
  vocabDatabaseSchema = cdm_schema,
  cdmVersion = cdm_version,
  sourceName = "Synthea OMOP CDM"
)

cat("✅ Achilles completed!\n")