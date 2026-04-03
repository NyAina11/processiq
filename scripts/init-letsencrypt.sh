#!/bin/bash
# =============================================================================
# init-letsencrypt.sh
# Obtient le premier certificat Let's Encrypt pour process1q.duckdns.org
# via le challenge DNS DuckDNS (plugin certbot-dns-duckdns).
#
# USAGE (sur le VPS, une seule fois) :
#   DUCKDNS_TOKEN=<ton_token> CERTBOT_EMAIL=<ton_email> ./scripts/init-letsencrypt.sh
#
# Variables d'environnement (ou définies dans .env) :
#   DOMAIN          — domaine cible (défaut : process1q.duckdns.org)
#   DUCKDNS_TOKEN   — token DuckDNS (obligatoire)
#   CERTBOT_EMAIL   — email pour Let's Encrypt (obligatoire)
# =============================================================================
set -e

DOMAIN="${DOMAIN:-process1q.duckdns.org}"
EMAIL="${CERTBOT_EMAIL:?'CERTBOT_EMAIL est requis (ex: CERTBOT_EMAIL=mon@email.com)'}"
TOKEN="${DUCKDNS_TOKEN:?'DUCKDNS_TOKEN est requis (récupéré sur duckdns.org)'}"

# Charger .env si présent et variables non définies
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs) 2>/dev/null || true
  DOMAIN="${DOMAIN:-process1q.duckdns.org}"
  EMAIL="${CERTBOT_EMAIL:-$EMAIL}"
  TOKEN="${DUCKDNS_TOKEN:-$TOKEN}"
fi

echo "=== ProcessIQ — Initialisation Let's Encrypt ==="
echo "Domaine  : $DOMAIN"
echo "Email    : $EMAIL"

# 1. Créer le fichier de credentials DuckDNS pour certbot
mkdir -p /etc/letsencrypt
cat > /etc/letsencrypt/duckdns.ini <<EOF
dns_duckdns_token = ${TOKEN}
EOF
chmod 600 /etc/letsencrypt/duckdns.ini

# 2. Démarrer nginx en mode init (HTTP seulement) pendant l'émission
echo ""
echo "▶ Démarrage nginx (mode init HTTP)..."
docker compose -f docker-compose.yml up -d nginx --no-deps \
  -e NGINX_CONF=nginx-init || true

# 3. Obtenir le certificat via certbot DNS DuckDNS
echo ""
echo "▶ Émission du certificat Let's Encrypt (DNS challenge DuckDNS)..."
docker compose run --rm certbot \
  certonly \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  --dns-duckdns \
  --dns-duckdns-credentials /etc/letsencrypt/duckdns.ini \
  --dns-duckdns-propagation-seconds 60 \
  -d "$DOMAIN"

echo ""
echo "✅ Certificat émis avec succès !"
echo ""

# 4. Redémarrer nginx avec la config HTTPS complète
echo "▶ Redémarrage nginx avec config HTTPS..."
docker compose up -d nginx

echo ""
echo "🔒 HTTPS activé sur https://${DOMAIN}"
echo "   Le renouvellement automatique est géré par le conteneur certbot."
