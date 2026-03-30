# Process IQ — Monorepo VPS Deployment

Déploiement co-localisé du backend (Node.js/Express + Airtable) et du frontend (React/Vite) sur un VPS unique via Docker Compose.

## Architecture

```
VPS (port 80)
└── nginx (frontend container)
    ├── / → Sert les fichiers statiques React
    └── /api/* → Proxy vers backend:8001
```

## Premier déploiement

### 1. Prérequis sur le VPS
```bash
sudo apt update && sudo apt install -y docker.io docker-compose-plugin git
```

### 2. Cloner le repo
```bash
git clone <URL_DU_REPO> /opt/processiq
cd /opt/processiq
git submodule update --init --recursive
```

### 3. Configurer les variables d'environnement
```bash
cp .env.example .env
nano .env   # Remplir AIRTABLE_API_TOKEN, AIRTABLE_BASE_ID, JWT_SECRET, VPS_IP
```

### 4. Lancer les services
```bash
make build
make up
```

Le site est accessible sur `http://<VPS_IP>`.

## Commandes utiles

| Commande | Description |
|----------|-------------|
| `make up` | Démarrer tous les services |
| `make down` | Arrêter tous les services |
| `make build` | Rebuild les images (sans cache) |
| `make logs` | Voir les logs en temps réel |
| `make restart` | Redémarrer tous les services |
| `make ps` | Statut des conteneurs |
| `make clean` | Arrêter et supprimer volumes |

## Mise à jour du code

```bash
git pull
git submodule update --remote
make build
make up
```

## Structure des projets

```
/
├── ProcessIQFileGenerator/   ← Backend API (Express + Airtable)
│   ├── Dockerfile
│   └── src/
├── process-IQ-rush-school/   ← Frontend (React + Vite)
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
├── docker-compose.yml        ← Orchestration
├── .env.example              ← Template des variables
└── Makefile                  ← Commandes pratiques
```

## Variables d'environnement

Voir `.env.example` pour la liste complète.

| Variable | Description |
|----------|-------------|
| `AIRTABLE_API_TOKEN` | Token API Airtable |
| `AIRTABLE_BASE_ID` | ID de la base Airtable |
| `JWT_SECRET` | Clé secrète JWT |
| `CORS_ORIGIN` | Origins CORS autorisées |
| `VPS_IP` | IP publique du VPS (documentation) |

## Notes

- **Pas de domaine** : Le site tourne en HTTP sur l'IP publique. Quand un domaine sera disponible, ajouter Certbot pour HTTPS.
- **Uploads** : Les fichiers uploadés sont persistés dans un volume Docker `processiq_uploads`.
