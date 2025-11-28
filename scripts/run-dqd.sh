#!/bin/bash

# Script to run Data Quality Dashboard checks
# Usage: scripts/run-dqd.sh [options]

set -e

# Default values
VIEW_RESULTS=false
COPY_RESULTS=false
OUTPUT_PATH="sample-data/dqd-results/dqd_results.json"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --view)
            VIEW_RESULTS=true
            shift
            ;;
        --copy)
            COPY_RESULTS=true
            shift
            ;;
        --output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --view          Launch Shiny app to view results interactively"
            echo "  --copy          Copy results JSON to host after execution"
            echo "  --output PATH   Specify output path for copied results (default: sample-data/dqd/dqd_results.json)"
            echo "  --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run DQD checks"
            echo "  $0 --copy             # Run checks and copy results to sample-data/dqd/dqd_results.json"
            echo "  $0 --copy --output /path/to/results.json"
            echo "  $0 --view             # Run checks and launch Shiny viewer"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if docker compose is available
if ! command -v docker compose &> /dev/null; then
    echo "Error: docker compose is not installed"
    exit 1
fi

# Check if dqd service exists
if ! docker compose config --services | grep -q "^dqd$"; then
    echo "Error: dqd service not found in docker compose.yml"
    exit 1
fi

echo "=========================================="
echo "OHDSI Data Quality Dashboard"
echo "=========================================="
echo ""

# Run DQD
if [ "$VIEW_RESULTS" = true ]; then
    echo "Running DQD with interactive viewer..."
    echo "Once complete, the Shiny app will be available at http://localhost:3838"
    echo "Press Ctrl+C to stop the viewer"
    echo ""
    docker compose run --rm -e VIEW_RESULTS=true -p 3838:3838 dqd
else
    echo "Running DQD checks..."
    echo ""
    docker compose run --rm dqd
fi

# Check if execution was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "DQD execution completed successfully!"
    echo "=========================================="

    # Copy results if requested
    if [ "$COPY_RESULTS" = true ]; then
        echo ""
        echo "Copying results to host..."

        # Get container ID of the most recent dqd container
        CONTAINER_ID=$(docker compose ps -q dqd 2>/dev/null || echo "")

        if [ -z "$CONTAINER_ID" ]; then
            # If container is not running, create a temporary one to copy files
            echo "Creating temporary container to copy results..."
            docker compose run --rm -d --name omop-dqd-temp dqd tail -f /dev/null
            sleep 2
            docker cp omop-dqd-temp:/dqd/results/dqd_results.json "$OUTPUT_PATH"
            docker stop omop-dqd-temp
            docker rm omop-dqd-temp
        else
            docker cp omop-dqd:/dqd/results/dqd_results.json "$OUTPUT_PATH"
        fi

        if [ -f "$OUTPUT_PATH" ]; then
            echo "Results copied to: $OUTPUT_PATH"
            echo ""
            echo "You can view the results by:"
            echo "  1. Opening the JSON file: cat $OUTPUT_PATH | jq ."
            echo "  2. Querying the database: docker-compose exec postgres psql -U postgres -d ohdsi -c 'SELECT * FROM results.dqdashboard_results LIMIT 10;'"
        else
            echo "Warning: Failed to copy results file"
        fi
    fi

    echo ""
    echo "Next steps:"
    echo "  - View results in database: docker-compose exec postgres psql -U postgres -d ohdsi"
    echo "  - Query results: SELECT * FROM results.dqdashboard_results;"
    if [ "$COPY_RESULTS" = false ]; then
        echo "  - Copy results: $0 --copy"
    fi
    if [ "$VIEW_RESULTS" = false ]; then
        echo "  - Launch viewer: $0 --view"
    fi
else
    echo ""
    echo "=========================================="
    echo "DQD execution failed!"
    echo "=========================================="
    echo ""
    echo "Check the logs for details:"
    echo "  docker compose logs dqd"
    exit 1
fi