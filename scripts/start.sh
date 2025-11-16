#!/bin/bash
# start.sh - Start the OMOP development environment

set -e

echo "========================================="
echo "Starting OMOP Environment"
echo "========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "Run ./scripts/setup.sh first"
    exit 1
fi

# Start services
echo "🚀 Starting services..."
echo ""
docker compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
echo "   This may take 2-3 minutes..."
echo ""

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
timeout=60
elapsed=0
while ! docker compose exec -T postgres pg_isready -U ohdsi_admin -d ohdsi > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "❌ PostgreSQL failed to start within $timeout seconds"
        docker compose logs postgres
        exit 1
    fi
    echo -n "."
    sleep 2
    elapsed=$((elapsed + 2))
done
echo ""
echo "✅ PostgreSQL is ready"

# Wait for WebAPI
echo "Waiting for WebAPI..."
timeout=120
elapsed=0
while ! curl -sf http://localhost:8080/WebAPI/info > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "❌ WebAPI failed to start within $timeout seconds"
        docker compose logs webapi
        exit 1
    fi
    echo -n "."
    sleep 3
    elapsed=$((elapsed + 3))
done
echo ""
echo "✅ WebAPI is ready"

# Wait for Atlas
echo "Waiting for Atlas..."
timeout=60
elapsed=0
while ! curl -sf http://localhost:8081 > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "❌ Atlas failed to start within $timeout seconds"
        docker compose logs atlas
        exit 1
    fi
    echo -n "."
    sleep 2
    elapsed=$((elapsed + 2))
done
echo ""
echo "✅ Atlas is ready"

echo ""
echo "========================================="
echo "✅ All Services Running!"
echo "========================================="
echo ""
echo "Access your environment:"
echo "  📊 Atlas:     http://localhost:8081/atlas"
echo "  🔌 WebAPI:    http://localhost:8080/WebAPI/info"
echo "  🗄️  PostgreSQL: localhost:5432"
echo ""
echo "Useful commands:"
echo "  View logs:    docker compose logs -f"
echo "  Stop:         ./scripts/stop.sh"
echo "  Reset:        ./scripts/reset.sh"
echo "  Load data:    ./scripts/load-synthea-data.sh"
echo ""
echo "For more information: docker-compose ps"
echo ""
