run: down up

build:
	docker compose build

up:
	docker compose up -d

down: 
	docker compose down -v

restore-db:
	docker exec -it postgres chmod +x /backup/restore_db.sh 
	docker exec -it postgres /backup/restore_db.sh 


