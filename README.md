# OMOP Development Environment

Local OHDSI/OMOP CDM development stack. This Docker-based environment provides a complete OMOP Common Data Model setup with Atlas, WebAPI, and Achilles for local development and testing.

## Quick Start

### Configure Environment

```shell
# Copy the example environment file
cp .env.exmaple .env

# Edit .env and change at least the PostgreSQL password
```

### Start the Stack
```shell
# Make scripts executable
chmod +x scripts/*.sh

# Run setup (first time only)
./scripts/setup.sh

# Start all services
./scripts/start.sh
```

### Access the Services
Once all containers are healthy (takes about 2-3 minutes)
- Atlas UI: http://localhost:8081
- WebAPI: http://localhost:8080/WebAPI
- PostgreSQL: localhost:5432 (use database client)

### Load Sample Data
```shell
# Load Synthea sample data (100K patients)
./scripts/load-synthea-data.sh

# OR load CMS SynPUF data
./scripts/load-cms-synpuf-data.sh
```

## Sample Data Options
Synthea (Recommended for Development)
- Size: ~100K synthetic patients
- Source: MITRE Synthea Generator
- Format: Already in OMOP CDM 5.4
- Download: Automatic via script

CMS SynPUF
- Size: 100K-1M Medicare beneficiaries
- Source: CMS synthetic data
- Format: Converted to OMOP
- Use case: More realistic clinical data



