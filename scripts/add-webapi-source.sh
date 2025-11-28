#!/bin/bash
# Add a new data source to WebAPI
# Examples:
#   ./scripts/add-webapi-source.sh 1 "Synthea OMOP CDM" SYNTHEA
#   ./scripts/add-webapi-source.sh 2 "My Hospital Data" HOSPITAL cdm_hospital results_hospital

set -e

SOURCE_ID=${1}
SOURCE_NAME=${2}
SOURCE_KEY=${3}
CDM_SCHEMA=${4:-cdm}
RESULTS_SCHEMA=${5:-ohdsi_results}
DB_NAME=${6:-ohdsi}
DB_USER=${7:-ohdsi_admin}
DB_PASSWORD=${8:-ohdsi}

if [ -z "$SOURCE_ID" ] || [ -z "$SOURCE_NAME" ] || [ -z "$SOURCE_KEY" ]; then
    echo "Usage: $0 <source_id> <source_name> <source_key> [cdm_schema] [results_schema] [db_name] [db_user] [db_password]"
    echo ""
    echo "Examples:"
    echo "  $0 1 'Synthea OMOP CDM' SYNTHEA"
    echo "  $0 2 'Hospital XYZ' HOSPITAL_XYZ cdm_xyz results_xyz"
    echo ""
    exit 1
fi

echo "========================================="
echo "Adding WebAPI Data Source"
echo "========================================="
echo "  Source ID:      ${SOURCE_ID}"
echo "  Source Name:    ${SOURCE_NAME}"
echo "  Source Key:     ${SOURCE_KEY}"
echo "  CDM Schema:     ${CDM_SCHEMA}"
echo "  Results Schema: ${RESULTS_SCHEMA}"
echo ""

# Insert source configuration
docker exec -i omop-postgres psql -U ohdsi_admin -d ohdsi <<SQL
-- Insert the source
INSERT INTO ohdsi.source (source_id, source_name, source_key, source_connection, source_dialect, is_cache_enabled)
VALUES (
  ${SOURCE_ID},
  '${SOURCE_NAME}',
  '${SOURCE_KEY}',
  'jdbc:postgresql://postgres:5432/${DB_NAME}?user=${DB_USER}&password=${DB_PASSWORD}',
  'postgresql',
  false
)
ON CONFLICT (source_id) DO UPDATE SET
  source_name = EXCLUDED.source_name,
  source_connection = EXCLUDED.source_connection;

-- Insert daimons (data access points)
-- daimon_type: 0=CDM, 1=Vocabulary, 2=Results
INSERT INTO ohdsi.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority)
VALUES
  (${SOURCE_ID}1, ${SOURCE_ID}, 0, '${CDM_SCHEMA}', 0),
  (${SOURCE_ID}2, ${SOURCE_ID}, 1, '${CDM_SCHEMA}', 10),
  (${SOURCE_ID}3, ${SOURCE_ID}, 2, '${RESULTS_SCHEMA}', 0)
ON CONFLICT (source_daimon_id) DO UPDATE SET
  table_qualifier = EXCLUDED.table_qualifier;
SQL

if [ $? -eq 0 ]; then
    echo "✅ Source added successfully!"
    echo ""
    echo "Verifying..."
    docker exec omop-postgres psql -U ohdsi_admin -d ohdsi -c "SELECT source_id, source_name, source_key FROM ohdsi.source WHERE source_id = ${SOURCE_ID};"
    echo ""
    echo "Restarting WebAPI to pick up changes..."
    docker compose restart webapi
    echo ""
    echo "✅ Done! Refresh Atlas in your browser."
else
    echo "❌ Failed to add source"
    exit 1
fi