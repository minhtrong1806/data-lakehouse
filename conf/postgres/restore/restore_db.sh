#!/bin/bash
set -e

echo "Waiting for PostgreSQL to start..."
until pg_isready -h localhost -p 5432 -U admin; do
  sleep 2
done

echo "Restoring database from dump..."
pg_restore --verbose --no-owner --clean --if-exists -U admin -d supply_chain /backup/dump-supply_chain.sql

echo "Restore completed!"
