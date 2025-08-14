# DOCKER
up-mini:
	docker compose up -d   trino postgres iceberg-rest minio metabase cloudflared

up:
	docker compose up -d 

down: 
	docker compose down -v

# POSTGRESQL
restore-db:
	docker exec -it supply-chain chmod +x /backup/restore_db.sh 
	docker exec -it supply-chain /backup/restore_db.sh 

# LOGS STREAMING
reset-log:
	docker exec -it spark /opt/spark/bin/spark-submit --master spark://spark:7077 /src/script/insert_logs.py

start-stream:
	cmd.exe /c start docker exec spark python /src/script/generate_logs.py
	cmd.exe /c start docker exec spark python /src/script/streaming_logs.py

stop-stream:
	docker exec spark pkill -f generate_logs.py
	docker exec spark pkill -f streaming_logs.py



# DBT
dbt-run-all: 
	dbt run --project-dir ./src/pipeline 

dbt-stream-log: 
	dbt run --project-dir ./src/pipeline --select processed_clickstream

dbt-clean:
	dbt clean --project-dir ./src/pipeline

# MAIN
run-all: up restore-db reset-log start-stream

