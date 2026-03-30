.PHONY: up down build logs restart ps clean

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build --no-cache

logs:
	docker compose logs -f

restart:
	docker compose restart

ps:
	docker compose ps

clean:
	docker compose down -v --remove-orphans

# Build uniquement le backend
build-backend:
	docker compose build --no-cache backend

# Build uniquement le frontend
build-frontend:
	docker compose build --no-cache frontend
