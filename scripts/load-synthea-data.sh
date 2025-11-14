#!/bin/bash
# scripts/load-synthea-data.sh - Load Synthea data using native Java (works on ARM)

set -e

echo "========================================="
echo "OMOP CDM - Synthea Data Loader (Full ETL)"
echo "========================================="
echo ""

# Configuration
PATIENT_COUNT=${1:-1000}
STATE=${2:-Massachusetts}
SYNTHEA_VERSION="3.2.0"
SYNTHEA_DIR="./sample-data/synthea"
OUTPUT_DIR="./sample-data/synthea-output"
VOCAB_DIR="./sample-data/vocabulary"

# Check prerequisites
if ! docker ps | grep -q omop-postgres; then
    echo "❌ Error: PostgreSQL container not running"
    echo "Start it with: docker compose up -d postgres"
    exit 1
fi

# Check Java
if ! command -v java &> /dev/null; then
    echo "❌ Error: Java not found"
    echo "Please install Java 11 or higher:"
    echo "  brew install openjdk@11"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
echo "✅ Java version: $JAVA_VERSION"
echo ""

# Step 1: Download Synthea if needed
echo "📦 Step 1/4: Setting up Synthea..."
mkdir -p "$SYNTHEA_DIR"

SYNTHEA_JAR="$SYNTHEA_DIR/synthea-with-dependencies.jar"
if [ ! -f "$SYNTHEA_JAR" ]; then
    echo "Downloading Synthea $SYNTHEA_VERSION..."
    curl -L -o "$SYNTHEA_JAR" \
        "https://github.com/synthetichealth/synthea/releases/download/v${SYNTHEA_VERSION}/synthea-with-dependencies.jar"
    echo "✅ Synthea downloaded"
else
    echo "✅ Synthea already downloaded"
fi
echo ""

# Step 2: Generate Synthea data
echo "📊 Step 2/4: Generating $PATIENT_COUNT synthetic patients..."
echo "   State: $STATE"
echo "   Output: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# Run Synthea
cd "$SYNTHEA_DIR"
java -jar synthea-with-dependencies.jar \
    -p $PATIENT_COUNT \
    -s $(date +%s) \
    --exporter.baseDirectory="../../$OUTPUT_DIR" \
    --exporter.csv.export=true \
    --exporter.fhir.export=false \
    --exporter.ccda.export=false \
    --exporter.text.export=false \
    "$STATE"
cd ../..

echo ""
echo "✅ Synthea data generated"
ls -lh "$OUTPUT_DIR/csv/" 2>/dev/null | head -10 || echo "   CSV files created in $OUTPUT_DIR/csv/"
echo ""

# Step 3: Check vocabularies
echo "📚 Step 3/4: Checking OMOP Vocabularies..."
if [ ! -d "$VOCAB_DIR" ] || [ -z "$(ls -A $VOCAB_DIR 2>/dev/null)" ]; then
    echo ""
    echo "⚠️  OMOP Vocabularies not found!"
    echo ""
    echo "Download from: https://athena.ohdsi.org/"
    echo "Extract to: $VOCAB_DIR/"
    echo ""
    read -p "Continue without vocabularies? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting."
        exit 1
    fi
    echo "⚠️  Continuing without vocabularies"
else
    echo "✅ Vocabularies found"
fi
echo ""

#echo "🔄 Step 4/4: Loading data into OMOP CDM..."
#echo "   Database: omop-postgres, Schema: cdm"
#echo ""
#echo "⚠️  ETL process not yet implemented"
#echo ""
#echo "Your Synthea CSV files are ready at: $OUTPUT_DIR/csv/"
#echo ""
#echo "To load into OMOP CDM, you can:"
#echo "1. Use ETL-Synthea: https://github.com/OHDSI/ETL-Synthea"
#echo "2. Write custom loading scripts"
#echo ""

echo "Step 4/4: Loading data into OMOP CDM using ETL-Synthea..."
echo "   This may take 2–10 minutes depending on patient count"

# Create native schema
docker exec -i omop-postgres psql -U ohdsi_admin -d ohdsi <<EOF
DROP SCHEMA IF EXISTS synthea_native CASCADE;
CREATE SCHEMA synthea_native;
GRANT ALL ON SCHEMA synthea_native TO ohdsi_admin;
EOF

# Run the full ETL
docker compose --profile tools run --rm etl-synthea

echo ""
echo "SUCCESS! Synthea data fully loaded into OMOP CDM"
echo "   Patients: $(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.person")"
echo "   Conditions: $(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.condition_occurrence")"
echo ""
echo "Open Atlas → http://localhost:8081"
echo "Run Achilles: docker compose --profile tools up achilles"