#!/bin/bash
# =============================================================================
# init-letsencrypt.sh
# Obtient le premier certificat Let's Encrypt pour process1q.duckdns.org
# via le challenge DNS DuckDNS.
#
# USAGE (sur le VPS, une seule fois) :
#   DUCKDNS_TOKEN=<ton_token> CERTBOT_EMAIL=<ton_email> ./scripts/init-letsencrypt.sh
# =============================================================================
set -e

# Charger .env si présent
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
fi

DOMAIN="${DOMAIN:-process1q.duckdns.org}"
EMAIL="${CERTBOT_EMAIL:?'CERTBOT_EMAIL est requis'}"
TOKEN="${DUCKDNS_TOKEN:?'DUCKDNS_TOKEN est requis'}"

echo "=== ProcessIQ — Initialisation Let's Encrypt ==="
echo "Domaine  : $DOMAIN"
echo "Email    : $EMAIL"
echo ""

# 1. Écrire le fichier de credentials DuckDNS dans le volume Docker
echo "▶ Écriture des credentials DuckDNS dans le volume certbot..."
docker compose run --rm --entrypoint /bin/sh certbot -c \
  "mkdir -p /etc/letsencrypt && \
   echo 'dns_duckdns_token = ${TOKEN}' > /etc/letsencrypt/duckdns.ini && \
   chmod 600 /etc/letsencrypt/duckdns.ini && \
   echo '✓ duckdns.ini créé'"

echo ""

# 2. Obtenir le certificat — on override l'entrypoint pour appeler certbot directement
#    (le service docker-compose a entrypoint=/bin/sh pour la boucle de renouvellement,
#     ici on le court-circuite avec --entrypoint certbot)
echo "▶ Émission du certificat Let's Encrypt (DNS challenge DuckDNS)..."
echo "  (environ 60s de propagation DNS — soyez patient)"
docker compose run --rm --entrypoint certbot certbot \
  certonly \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  --authenticator dns-duckdns \
  --dns-duckdns-credentials /etc/letsencrypt/duckdns.ini \
  --dns-duckdns-propagation-seconds 60 \
  -d "$DOMAIN"

echo ""
echo "✅ Certificat émis avec succès !"
echo ""

# 3. Démarrer tous les services (nginx charge automatiquement le cert)
echo "▶ Démarrage de tous les services..."
docker compose up -d

echo ""
echo "🔒 HTTPS actif sur https://${DOMAIN}"
echo "   Le renouvellement automatique est géré par le conteneur certbot."
