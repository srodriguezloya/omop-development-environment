# scripts/etl-synthea.R
library(ETLSyntheaBuilder)
library(DatabaseConnector)

cat("Connecting to database...\n")
connDetails <- createConnectionDetails(
  dbms = "postgresql",
  server = paste0(Sys.getenv("POSTGRES_HOST"), "/", Sys.getenv("POSTGRES_DB")),
  user = Sys.getenv("POSTGRES_USER"),
  password = Sys.getenv("POSTGRES_PASSWORD"),
  port = 5432
)

cdmSchema       <- Sys.getenv("CDM_SCHEMA")
syntheaSchema   <- Sys.getenv("SYNTHEA_SCHEMA")
vocabDir        <- Sys.getenv("VOCAB_DIR")
syntheaCsvDir   <- Sys.getenv("SYNTHEA_CSV_DIR")
cdmVersion      <- "5.4"
syntheaVersion  <- "3.3.0"  # Change if you upgrade Synthea

cat("Creating native Synthea tables...\n")
CreateSyntheaTables(connDetails, syntheaSchema, syntheaVersion)

cat("Loading Synthea CSV files...\n")
LoadSyntheaTables(connDetails, syntheaSchema, syntheaCsvDir)

cat("Creating mapping and rollup tables...\n")
CreateMapAndRollupTables(connDetails, cdmSchema, syntheaSchema, cdmVersion, syntheaVersion)

cat("Loading event tables into CDM (this may take a while)...\n")
LoadEventTables(connDetails, cdmSchema, syntheaSchema, cdmVersion, syntheaVersion)

cat("Adding useful indices...\n")
CreateExtraIndices(connDetails, cdmSchema, syntheaSchema, syntheaVersion)

cat("ETL-Synthea completed successfully!\n")
cat("You can now open Atlas: http://localhost:8081\n")
cat("Total patients loaded:\n")
con <- connect(connDetails)
print(dbGetQuery(con, "SELECT COUNT(*) FROM cdm.person"))
disconnect(con)