# DOCKER
up-mini:
	docker compose up -d minio postgres-catalog rest trino cube metabase

up:
	docker compose up -d spark rest postgres-catalog trino minio metabase

down: 
	docker compose down -v

# POSTGRESQL
restore-db:
	docker exec -it supply-chain chmod +x /backup/restore_db.sh 
	docker exec -it supply-chain /backup/restore_db.sh 

# LOGS STREAMING
reset-log:
	docker exec -it spark /opt/spark/bin/spark-submit --master spark://spark:7077 /src/script/insert_logs_2017.py

start-stream:
	cmd.exe /c start docker exec spark python /src/script/generate_logs_2018.py
	cmd.exe /c start docker exec spark python /src/script/streaming_logs.py

stop-stream:
	docker exec -it spark pkill -9 python


# DBT
dbt-run-all: 
	dbt run --project-dir ./src/pipeline 

dbt-stream-log: 
	dbt run --project-dir ./src/pipeline --select processed_clickstream

dbt-clean:
	dbt clean --project-dir ./src/pipeline

# MAIN
run-all: up restore-db reset-log start-stream

