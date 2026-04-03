.PHONY: up down build logs restart ps clean reload-nginx renew-certs

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

# Recharge la config nginx sans downtime
reload-nginx:
	docker compose exec nginx nginx -s reload

# Déclenche le renouvellement Let's Encrypt manuellement
renew-certs:
	docker compose exec certbot certbot renew --force-renewal \
		--dns-duckdns \
		--dns-duckdns-credentials /etc/letsencrypt/duckdns.ini \
		--dns-duckdns-propagation-seconds 60
