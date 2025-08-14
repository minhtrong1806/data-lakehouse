#!/bin/bash
set -e

# Kết nối vào database "postgres" để tạo các DB còn lại
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname=postgres <<-EOSQL
    CREATE DATABASE metabase_db;
    CREATE DATABASE rest_db;
    CREATE DATABASE analytics;
    CREATE DATABASE datahub_db;
EOSQL

# Kiểm tra nếu supply_chain_db chưa có bảng nào thì mới restore
echo "Checking if supply_chain_db is empty..."

EXISTING_TABLES=$(psql -U "$POSTGRES_USER" -d supply_chain_db -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

if [ "$EXISTING_TABLES" = "0" ]; then
  echo "No tables found in supply_chain_db. Restoring from dump..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname=supply_chain_db < /docker-entrypoint-initdb.d/dump-supply_chain.sql
else
  echo "supply_chain_db already contains data. Skipping restore."
fi
