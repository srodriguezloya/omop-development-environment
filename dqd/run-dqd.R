library(DataQualityDashboard)
library(DatabaseConnector)

# Database connection details - these will be set via environment variables
dbms <- Sys.getenv("DBMS", "postgresql")
server <- Sys.getenv("DB_SERVER", "postgres/ohdsi")
port <- as.integer(Sys.getenv("DB_PORT", "5432"))
user <- Sys.getenv("DB_USER", "postgres")
password <- Sys.getenv("DB_PASSWORD", "postgres")
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA", "cdm")
resultsDatabaseSchema <- Sys.getenv("RESULTS_SCHEMA", "results")
cdmSourceName <- Sys.getenv("CDM_SOURCE_NAME", "OMOP CDM")
cdmVersion <- Sys.getenv("CDM_VERSION", "5.4")
outputFolder <- Sys.getenv("OUTPUT_FOLDER", "/dqd/results")
outputFile <- Sys.getenv("OUTPUT_FILE", "dqd_results.json")

# Path to JDBC drivers
pathToDriver <- "/opt/jdbc_drivers"

# Create connection details
connectionDetails <- createConnectionDetails(
  dbms = dbms,
  server = server,
  port = port,
  user = user,
  password = password,
  pathToDriver = pathToDriver
)

# Run Data Quality Dashboard
cat("Starting Data Quality Dashboard execution...\n")
cat(sprintf("CDM Database Schema: %s\n", cdmDatabaseSchema))
cat(sprintf("Results Database Schema: %s\n", resultsDatabaseSchema))
cat(sprintf("CDM Version: %s\n", cdmVersion))

tryCatch({
  DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    cdmSourceName = cdmSourceName,
    cdmVersion = cdmVersion,
    numThreads = 1,
    sqlOnly = FALSE,
    outputFolder = outputFolder,
    outputFile = outputFile,
    verboseMode = TRUE,
    writeToTable = TRUE,
    writeToCsv = FALSE,
    checkLevels = c("TABLE", "FIELD", "CONCEPT"),
    checkNames = c(),  # Empty means run all checks
    tablesToExclude = c(),
    cohortDefinitionId = NULL
  )

  cat("\nData Quality Dashboard execution completed successfully!\n")
  cat(sprintf("Results written to: %s/%s\n", outputFolder, outputFile))

  # Optionally view results
  if (Sys.getenv("VIEW_RESULTS", "false") == "true") {
    cat("\nLaunching Shiny app to view results...\n")
    DataQualityDashboard::viewDqDashboard(
      jsonPath = file.path(outputFolder, outputFile)
    )
  }

}, error = function(e) {
  cat("\nError executing Data Quality Dashboard:\n")
  cat(as.character(e), "\n")
  quit(status = 1)
})

cat("\nDQD process completed.\n")