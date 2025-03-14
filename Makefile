# DOCKER
run-service: down up

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
	docker exec -it spark /opt/spark/bin/spark-submit --master spark://spark:7077 /src/script/insert_logs_2017.py

start-stream:
	cmd.exe /c start /b docker exec spark python /src/script/generate_logs_2018.py
	cmd.exe /c start /b docker exec spark python /src/script/streaming_logs.py

stop-stream:
	docker exec -it spark pkill -9 python


# MAIN
run-all: up restore-db reset-log start-stream

