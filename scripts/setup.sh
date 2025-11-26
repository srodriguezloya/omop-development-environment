#!/bin/bash
# setup.sh - First-time setup for OMOP development environment

set -e  # Exit on error

echo "========================================="
echo "OMOP Development Environment"
echo "Initial Setup"
echo "========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env and change the default passwords!"
    echo "   Run: vim .env"
    echo ""
else
    echo "✅ .env file already exists"
    echo ""
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p postgres/init-scripts
mkdir -p sample-data/synthea-omop
mkdir -p sample-data/cms-synpuf
mkdir -p scripts
mkdir -p docs
mkdir -p notebooks
echo "✅ Directories created"
echo ""

# Pull Docker images
echo "📦 Pulling Docker images (this may take a few minutes)..."
docker compose pull
echo "✅ Docker images pulled"
echo ""

# Download OMOP CDM DDL if not exists
if [ ! -f postgres/init-scripts/02-omop-cdm-ddl.sql ]; then
    echo "📥 Downloading OMOP CDM DDL..."
    curl -L -o postgres/init-scripts/02-omop-cdm-ddl.sql \
        "https://raw.githubusercontent.com/OHDSI/CommonDataModel/v5.4.0/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_ddl.sql"
    echo "✅ OMOP CDM DDL downloaded"
    echo ""
fi

echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env and change passwords: vim .env"
echo "2. Download vocabularies from https://athena.ohdis.org and extract to ./sample-data/vocabulary/"
echo "3. Start services: ./scripts/start.sh"
echo "4. Load sample data: ./scripts/load-synthea-data.sh"
echo "5. Access Atlas: http://localhost:8081"
echo ""
echo "For more information, see README.md"
echo ""
