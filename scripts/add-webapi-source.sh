#!/bin/bash
# Add a new data source to WebAPI
# Examples:
# ./scripts/add-webapi-source.sh 1 "Synthea OMOP CDM" SYNTHEA
# ./scripts/add-webapi-source.sh 2 "My Hospital Data" HOSPITAL cdm_hospital results_hospital

SOURCE_ID=${1}
SOURCE_NAME=${2}
SOURCE_KEY=${3}
CDM_SCHEMA=${4:-cdm}
RESULTS_SCHEMA=${5:-ohdsi_results}

if [ -z "$SOURCE_ID" ] || [ -z "$SOURCE_NAME" ] || [ -z "$SOURCE_KEY" ]; then
    echo "Usage: $0 <source_id> <source_name> <source_key> [cdm_schema] [results_schema]"
    echo "Example: $0 2 'My Hospital' HOSPITAL cdm_hospital results_hospital"
    exit 1
fi

docker exec -i omop-postgres psql -U ohdsi_admin -d ohdsi <<SQL
INSERT INTO webapi.source (source_id, source_name, source_key, source_connection, source_dialect)
VALUES (
${SOURCE_ID},
'${SOURCE_NAME}',
'${SOURCE_KEY}',
'jdbc:postgresql://postgres:5432/ohdsi?user=ohdsi_admin&password=ohdsi',
'postgresql'
)
ON CONFLICT (source_id) DO UPDATE SET
    source_name = EXCLUDED.source_name;

INSERT INTO webapi.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority)
VALUES
    (${SOURCE_ID}1, ${SOURCE_ID}, 0, '${CDM_SCHEMA}', 0),
    (${SOURCE_ID}2, ${SOURCE_ID}, 1, '${CDM_SCHEMA}', 10),
    (${SOURCE_ID}3, ${SOURCE_ID}, 2, '${RESULTS_SCHEMA}', 0)
    ON CONFLICT DO NOTHING;
SQL

echo "✅ Source added: ${SOURCE_NAME}"
docker compose restart webapi