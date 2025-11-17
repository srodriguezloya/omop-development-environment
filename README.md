# OMOP Development Environment

A complete OHDSI/OMOP CDM development stack with Docker. This environment provides Atlas, WebAPI, PostgreSQL, and ETL tools for working with observational health data in the OMOP Common Data Model format.

## Quick Start

### Prerequisites

- **Docker** and **Docker Compose** installed
- **Java 11+** (for Synthea data generation)
- **75GB+ disk space** (50GB for vocabularies, 25GB for Docker volumes)
- Ubuntu/Linux server or Mac with Docker Desktop

### Configure Environment

```shell
# Copy the example environment file
cp .env.exmaple .env

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

### Access the Services

| Service | URL | Description |
|---------|-----|-------------|
| **Atlas** | http://localhost:8081/atlas | OHDSI Atlas - Data exploration UI |
| **WebAPI** | http://localhost:8080/WebAPI | OHDSI WebAPI - REST API |
| **PostgreSQL** | localhost:5432 | Database (credentials in .env) |

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
# Syntax:    [cdm_schema] [results_schema]
./scripts/add-webapi-source.sh 2 "My Hospital" HOSPITAL cdm_hospital results_hospital
```

### Run Achilles (Data Characterization)

Achilles generates statistical reports about your CDM data:

```bash
docker compose --profile tools up achilles
```

This takes 5-30 minutes depending on data size. Results are visible in Atlas after completion.

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f webapi
docker compose logs -f atlas
docker compose logs -f postgres
```
### Connect to Database

```bash
# Using psql script
./scripts/psql.sh

# Or directly
docker exec -it omop-postgres psql -U ohdsi_admin -d ohdsi
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
