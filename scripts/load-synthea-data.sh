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
    echo "  sudo apt install openjdk-11-jdk"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
echo "✅ Java version: $JAVA_VERSION"
echo ""

# Step 1: Download Synthea if needed
echo "📦 Step 1/5: Setting up Synthea..."
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
echo "📊 Step 2/5: Generating $PATIENT_COUNT synthetic patients..."
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

# Step 3: Check and load vocabularies
echo "📚 Step 3/5: Checking OMOP Vocabularies..."
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
    echo "⚠️  Continuing without vocabularies (clinical data will be empty!)"
else
    echo "✅ Vocabulary files found in $VOCAB_DIR"

    # Check if vocabularies are loaded in database
    VOCAB_COUNT=$(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.concept" 2>/dev/null || echo "0")

    if [ "$VOCAB_COUNT" -eq 0 ]; then
        echo "📥 Loading vocabularies into database (this may take 5-10 minutes)..."

        # Copy vocabulary files to container
        docker cp "$VOCAB_DIR/." omop-postgres:/tmp/vocabulary/

        # Load vocabularies
        docker exec omop-postgres psql -U ohdsi_admin -d ohdsi <<VOCABSQL
\copy cdm.concept FROM '/tmp/vocabulary/CONCEPT.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.vocabulary FROM '/tmp/vocabulary/VOCABULARY.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.domain FROM '/tmp/vocabulary/DOMAIN.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.concept_class FROM '/tmp/vocabulary/CONCEPT_CLASS.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.concept_relationship FROM '/tmp/vocabulary/CONCEPT_RELATIONSHIP.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.relationship FROM '/tmp/vocabulary/RELATIONSHIP.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.concept_synonym FROM '/tmp/vocabulary/CONCEPT_SYNONYM.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.concept_ancestor FROM '/tmp/vocabulary/CONCEPT_ANCESTOR.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
\copy cdm.drug_strength FROM '/tmp/vocabulary/DRUG_STRENGTH.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';
VOCABSQL

        VOCAB_COUNT=$(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.concept")
        echo "✅ Vocabularies loaded: $VOCAB_COUNT concepts"
    else
        echo "✅ Vocabularies already loaded in database: $VOCAB_COUNT concepts"
    fi
fi
echo ""

echo "Step 4/5: Preparing database schema..."
# Create native schema
docker exec -i omop-postgres psql -U ohdsi_admin -d ohdsi <<EOF
DROP SCHEMA IF EXISTS synthea_native CASCADE;
CREATE SCHEMA synthea_native;
GRANT ALL ON SCHEMA synthea_native TO ohdsi_admin;
EOF
echo "✅ Schema ready"
echo ""

echo "Step 5/5: Loading data into OMOP CDM using ETL-Synthea..."
echo "   This may take 5-20 minutes depending on patient count"
echo ""

# Run the full ETL
docker compose --profile tools run --rm etl-synthea

echo ""
echo "========================================="
echo "SUCCESS! Synthea data fully loaded into OMOP CDM"
echo "========================================="
echo "   Patients: $(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.person")"
echo "   Conditions: $(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.condition_occurrence")"
echo "   Drugs: $(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.drug_exposure")"
echo "   Procedures: $(docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -At -c "SELECT COUNT(*) FROM cdm.procedure_occurrence")"
echo ""
echo "Next steps:"
echo "  • Open Atlas: https://atlas.chava.cc"
echo "  • Run Achilles: docker compose --profile tools up achilles"
echo ""