#!/bin/bash

TOOL=${1:-achilles}

case $TOOL in
  achilles)
    docker compose --profile tools run --rm \
      hades Rscript /app/run-achilles.R
    ;;
  dqd)
    docker compose --profile tools run --rm \
      hades Rscript /app/run-dqd.R
    ;;
  ares-indexer|indexer)
    docker compose --profile tools run --rm \
      hades Rscript /app/run-ares-indexer.R
    ;;
  all)
    echo "Running complete HADES workflow..."
    docker compose --profile tools run --rm hades Rscript /app/run-achilles.R
    docker compose --profile tools run --rm hades Rscript /app/run-dqd.R
    docker compose --profile tools run --rm hades Rscript /app/run-ares-indexer.R
    ;;
  *)
    echo "Usage: $0 {achilles|dqd|ares-indexer|all}"
    exit 1
    ;;
esac