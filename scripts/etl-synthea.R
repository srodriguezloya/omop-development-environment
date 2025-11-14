# ./scripts/etl-synthea.R — Official ETLSyntheaBuilder Functions (Corrected Signatures)
library(ETLSyntheaBuilder)
library(DatabaseConnector)

cat("=== Synthea → OMOP CDM ETL (Official Functions) ===\n")

uri <- Sys.getenv("SYNTHEA_DB_URI")
if (uri == "") stop("Missing SYNTHEA_DB_URI")

cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  connectionString = uri
)

synthea_schema <- Sys.getenv("SYNTHEA_RAW_SCHEMA", "synthea_native")
cdm_schema     <- Sys.getenv("SYNTHEA_CDM_SCHEMA", "cdm")
csv_folder     <- Sys.getenv("SYNTHEA_FILE", "/data/synthea_csv")
cdm_version    <- "5.4"
synthea_version <- "3.2.0"

cat("Step 1/5: Creating Synthea tables in", synthea_schema, "\n")
CreateSyntheaTables(
  connectionDetails = cd,
  syntheaSchema = synthea_schema,
  syntheaVersion = synthea_version
)

cat("Step 2/5: Loading CSVs into", synthea_schema, "\n")
LoadSyntheaTables(
  connectionDetails = cd,
  syntheaSchema = synthea_schema,
  syntheaFileLoc = csv_folder
)

cat("Step 3/5: Creating mapping/rollup tables (using pre-loaded vocab in", cdm_schema, ")\n")
CreateMapAndRollupTables(
  connectionDetails = cd,
  cdmSchema = cdm_schema,
  syntheaSchema = synthea_schema,
  cdmVersion = cdm_version,
  syntheaVersion = synthea_version
)

cat("Step 4/5: Loading events into CDM tables in", cdm_schema, "\n")
LoadEventTables(
  connectionDetails = cd,
  cdmSchema = cdm_schema,
  syntheaSchema = synthea_schema,
  cdmVersion = cdm_version,
  syntheaVersion = synthea_version
)

cat("Step 5/5: Creating extra indices in", cdm_schema, "\n")
CreateExtraIndices(
  connectionDetails = cd,
  cdmSchema = cdm_schema,
  syntheaSchema = synthea_schema,
  syntheaVersion = synthea_version
)

cat("ETL COMPLETED SUCCESSFULLY!\n")

con <- DatabaseConnector::connect(cd)
raw_patients <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) FROM", synthea_schema, ".patients"))[[1]]
cdm_patients <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) FROM", cdm_schema, ".person"))[[1]]
cat("Raw patients loaded:", raw_patients, "\n")
cat("CDM patients loaded:", cdm_patients, "\n")
DBI::dbDisconnect(con)