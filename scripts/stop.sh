#!/bin/bash
# stop.sh - Stop the OMOP development environment

echo "Stopping OMOP Environment..."
docker compose down
echo "✅ Services stopped"
