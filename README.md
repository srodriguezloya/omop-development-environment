# OMOP Development Environment

> **Quickly deploy a single-instance implementation of OHDSI tools with sample data for personal learning and training 
> environments.**
> 
> ⚠️ **This is NOT intended for enterprise or production deployments.** For production use, please follow
> [OHDSI security and deployment best practices](https://ohdsi.github.io/TheBookOfOhdsi/).

A complete OHDSI/OMOP CDM development stack with Docker. This environment provides Atlas, Achilles, DQD, WebAPI, PostgreSQL, 
and ETL tools for working with observational health data in the OMOP Common Data Model format.

## Quick Start

### Prerequisites

- **Docker** and **Docker Compose** installed
- **Java 11+** (for Synthea data generation)

### Configure Environment

```shell
# Copy the example environment file
cp .env.example .env

# Edit .env and change at least the PostgreSQL password
```

**Important:** Change `POSTGRES_PASSWORD` from the default!

### Initial Setup 

```shell
# Make scripts executable
chmod +x scripts/*.sh

# Run setup (first time only)
./scripts/setup.sh
```
This will:
- Create necessary directories
- Pull Docker images
- Download OMOP CDM DDL
- Create `.env` if it doesn't exist

### Download OMOP Vocabularies

**CRITICAL:** OMOP vocabularies are required for the ETL to work properly.

1. Go to **https://athena.ohdsi.org/**
2. Create a free account
3. Select vocabularies (minimum required):
    - ✅ **SNOMED** (required)
    - ✅ **RxNorm** (required for medications)
    - ✅ **LOINC** (required for labs)
    - ⚠️ **Optional but recommended:** ICD10CM, CPT4
4. Click "Download Vocabularies"
5. Wait for email notification (takes a few minutes)
6. Download the ZIP file (~1-3GB for minimal set, ~5GB for full)
7. Extract to `./sample-data/vocabulary/`

**Note:** For smaller deployments with limited disk space, select only SNOMED, RxNorm, and LOINC to save space.

### Start Services

```bash
./scripts/start.sh
```
Wait 2-3 minutes for all services to become healthy. The script will show you when they're ready.

### Configure Data Source

WebAPI needs to be told which CDM database to use. Run this to configure your first data source:

```bash
./scripts/add-webapi-source.sh 1 "Synthea OMOP CDM" SYNTHEA
```

This registers your CDM database with WebAPI so Atlas can access it.

### Load Sample Data

```bash
# Load Synthea synthetic data (50-100 patients for testing)
./scripts/load-synthea-data.sh 50

# Or more patients (takes longer)
./scripts/load-synthea-data.sh 100
```
The script will:
1. Download Synthea JAR (first time only)
2. Generate synthetic patient data
3. Check/load OMOP vocabularies (if not already loaded)
4. Run ETL to transform data into OMOP CDM format

**First run with vocabularies takes 10-15 minutes.** Subsequent runs are faster.

### Run Achilles

Achilles generates statistical characterizations of your CDM data:

```shell
docker compose --profile tools up achilles
```

**Note:** This takes 5-30 minutes depending on data size. Results are visible in Atlas after completion.

### Run Data Quality Dashboard (DQD)

DQD validates your CDM data against OMOP specifications:

```shell
docker compose --profile tools up dqd
```

**What it does:**
- Runs comprehensive quality checks on your CDM data
- Validates table structures, field types, and relationships
- Checks for data quality issues
- Stores results in the database and JSON file
- Launches interactive Shiny dashboard for viewing results

**Access the dashboard at:** http://localhost:3838

**First run takes:** 10-20 minutes depending on data size

**Results location:** `./sample-data/dqd-results/dqd_results.json`

**To view results from a previous run without re-running checks:**
```bash
docker exec -it omop-dqd R -e "library(DataQualityDashboard); viewDqDashboard(jsonPath='/app/results/dqd_results.json', launch.browser=FALSE, port=3838, host='0.0.0.0')"
```

### Access the Services

| Service                  | URL                          | Description                       |
|--------------------------|------------------------------|-----------------------------------|
| **Atlas**                | http://localhost:8081/atlas  | OHDSI Atlas - Data exploration UI |
| **WebAPI**               | http://localhost:8080/WebAPI | OHDSI WebAPI - REST API           |
| **DataQualityDashboard** | http://localhost:3838        | Data Quality Dashboard UI         |
| **PostgreSQL**           | localhost:5432               | Database (credentials in .env)    |

## 🔧 Common Tasks

### Load More Sample Data

```bash
# Load additional patients
./scripts/load-synthea-data.sh 200

# Different state (changes demographics)
./scripts/load-synthea-data.sh 100 California
```
### Add Another Data Source

```bash
# Syntax: ./scripts/add-webapi-source.sh [id] [name] [key] [cdm_schema] [results_schema]
./scripts/add-webapi-source.sh 2 "My Hospital" HOSPITAL cdm_hospital results_hospital
```

### Run Achilles (Data Characterization)

Achilles generates statistical reports about your CDM data:

```bash
docker compose --profile tools up achilles
```

This takes 5-30 minutes depending on data size. Results are visible in Atlas after completion.

### Re-run Data Quality Dashboard

```bash
# Stop the current DQD container
docker compose --profile tools down dqd

# Run again (will use existing data and re-check)
docker compose --profile tools up dqd
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f webapi
docker compose logs -f atlas
docker compose logs -f postgres
docker compose logs -f dqd
```
### Connect to Database

```bash
# Using psql script
./scripts/psql.sh

# Or directly
docker exec -it omop-postgres psql -U ohdsi_admin -d ohdsi
```

### Inspect CDM Tables

```sql
-- Connect to database first (see above)

-- List all tables in CDM schema
\dt cdm.*

-- Count patients
SELECT COUNT(*) FROM cdm.person;

-- Count observations
SELECT COUNT(*) FROM cdm.observation;

-- Check vocabulary version
SELECT * FROM cdm.vocabulary WHERE vocabulary_id = 'None';

-- View DQD results in database
SELECT * FROM ohdsi_results.dqdashboard_results LIMIT 10;
```

### Stop Services

```bash
./scripts/stop.sh

# Or with Docker Compose
docker compose down
```
### Reset Everything (Clean Start)

```bash
docker compose down -v  # Removes volumes (deletes all data!)
./scripts/setup.sh      # Re-initialize
./scripts/start.sh      # Start fresh
```

## 🐛 Troubleshooting

### Atlas shows "No sources defined"

This means WebAPI doesn't have any CDM data sources configured.

**Solution:**
```bash
./scripts/add-webapi-source.sh 1 "Synthea OMOP CDM" SYNTHEA
docker compose restart webapi atlas
```

## 📚 Additional Resources

- [OHDSI Documentation](https://ohdsi.github.io/TheBookOfOhdsi/)
- [OMOP CDM Documentation](https://ohdsi.github.io/CommonDataModel/)
- [Atlas Wiki](https://github.com/OHDSI/Atlas/wiki)
- [Achilles Documentation](https://github.com/OHDSI/Achilles)
- [DataQualityDashboard Documentation](https://github.com/OHDSI/DataQualityDashboard)
- [Athena Vocabulary Browser](https://athena.ohdsi.org/)

## 🤝 Contributing

Issues and pull requests welcome! 

**Note:** This is a development and learning environment designed for single-instance deployments. Production 
deployments should follow OHDSI security and deployment best practices, including:
- Proper authentication and authorization
- SSL/TLS encryption
- Network security and firewalls
- Regular backups and disaster recovery
- Compliance with healthcare data regulations (HIPAA, GDPR, etc.)

For production guidance, see the [OHDSI community forums](https://forums.ohdsi.org/) and [The Book of OHDSI](https://ohdsi.github.io/TheBookOfOhdsi/).

## 📄 License

This configuration is provided as-is for development purposes. Individual OHDSI components have their own licenses - 
please refer to their respective repositories.