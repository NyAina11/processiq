#!/bin/bash
# =============================================================================
# init-letsencrypt.sh
# Obtient le premier certificat Let's Encrypt pour process1q.duckdns.org
# via le challenge DNS DuckDNS (plugin certbot-dns-duckdns).
#
# USAGE (sur le VPS, une seule fois) :
#   DUCKDNS_TOKEN=<ton_token> CERTBOT_EMAIL=<ton_email> ./scripts/init-letsencrypt.sh
#
# Variables d'environnement requises :
#   DUCKDNS_TOKEN   — token DuckDNS (duckdns.org)
#   CERTBOT_EMAIL   — email pour Let's Encrypt
# Variables optionnelles :
#   DOMAIN          — domaine cible (défaut : process1q.duckdns.org)
# =============================================================================
set -e

# Charger .env si présent
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
fi

DOMAIN="${DOMAIN:-process1q.duckdns.org}"
EMAIL="${CERTBOT_EMAIL:?'CERTBOT_EMAIL est requis (ex: CERTBOT_EMAIL=mon@email.com)'}"
TOKEN="${DUCKDNS_TOKEN:?'DUCKDNS_TOKEN est requis (récupéré sur duckdns.org)'}"

echo "=== ProcessIQ — Initialisation Let's Encrypt ==="
echo "Domaine  : $DOMAIN"
echo "Email    : $EMAIL"
echo ""

# 1. Écrire le fichier de credentials DuckDNS DANS le volume Docker
#    (on passe par le conteneur certbot pour écrire dans /etc/letsencrypt)
echo "▶ Écriture des credentials DuckDNS dans le volume certbot..."
docker compose run --rm --entrypoint /bin/sh certbot -c \
  "mkdir -p /etc/letsencrypt && \
   echo 'dns_duckdns_token = ${TOKEN}' > /etc/letsencrypt/duckdns.ini && \
   chmod 600 /etc/letsencrypt/duckdns.ini && \
   echo '✓ duckdns.ini créé'"

echo ""

# 2. Obtenir le certificat Let's Encrypt via DNS challenge DuckDNS
echo "▶ Émission du certificat Let's Encrypt (DNS challenge DuckDNS)..."
echo "  (environ 60s de propagation DNS — soyez patient)"
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

# 3. Démarrer tous les services (nginx charge automatiquement le cert)
echo "▶ Démarrage de tous les services..."
docker compose up -d

echo ""
echo "🔒 HTTPS actif sur https://${DOMAIN}"
echo "   Le renouvellement automatique est géré par le conteneur certbot."
