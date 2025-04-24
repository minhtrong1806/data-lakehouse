# Use the official PostgreSQL image as a base image
FROM postgres:latest

# Set environment variables for Postgres user and database
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=admin123
ENV POSTGRES_DB=supply_chain_db

COPY init-db /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh
