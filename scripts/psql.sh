#!/bin/bash
# psql.sh - Connect to PostgreSQL database

echo "Connecting to OMOP database..."
echo "Type '\q' to exit"
echo ""

docker compose exec postgres psql -U ohdsi_admin -d ohdsi
