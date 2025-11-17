#!/usr/bin/env Rscript
# ETL-Synthea Script - Loads Synthea CSV data into OMOP CDM

library(ETLSyntheaBuilder)
library(DatabaseConnector)

cat("=== Synthea → OMOP CDM ETL (Official Functions) ===\n")

# Parse database URI
uri <- Sys.getenv("SYNTHEA_DB_URI")
if (uri == "") stop("Missing SYNTHEA_DB_URI")

# Parse postgresql://user:password@host:port/database
# Example: postgresql://ohdsi_admin:changeme@postgres:5432/ohdsi
uri_pattern <- "postgresql://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+)"
matches <- regmatches(uri, regexec(uri_pattern, uri))[[1]]

if (length(matches) != 6) {
  stop("Invalid SYNTHEA_DB_URI format. Expected: postgresql://user:password@host:port/database")
}

db_user <- matches[2]
db_password <- matches[3]
db_host <- matches[4]
db_port <- matches[5]
db_name <- matches[6]

cat("Database:", db_host, "Port:", db_port, "Database:", db_name, "\n")

# Create connection details without JDBC driver
cd <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = paste0(db_host, "/", db_name),
  port = as.integer(db_port),
  user = db_user,
  password = db_password
)

synthea_schema <- Sys.getenv("SYNTHEA_RAW_SCHEMA", "synthea_native")
cdm_schema     <- Sys.getenv("SYNTHEA_CDM_SCHEMA", "cdm")
csv_folder     <- Sys.getenv("SYNTHEA_FILE", "/data/synthea_csv")
cdm_version    <- "5.4"
synthea_version <- "3.2.0"

cat("\nConfiguration:\n")
cat("  Synthea Schema:", synthea_schema, "\n")
cat("  CDM Schema:", cdm_schema, "\n")
cat("  CSV Folder:", csv_folder, "\n")
cat("  CDM Version:", cdm_version, "\n")
cat("  Synthea Version:", synthea_version, "\n\n")

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

cat("\n=== ETL COMPLETED SUCCESSFULLY! ===\n\n")

con <- DatabaseConnector::connect(cd)
raw_patients <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) FROM", synthea_schema, ".patients"))[[1]]
cdm_patients <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) FROM", cdm_schema, ".person"))[[1]]
cat("Raw patients loaded:", raw_patients, "\n")
cat("CDM patients loaded:", cdm_patients, "\n")
DBI::dbDisconnect(con)