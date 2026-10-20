#!/bin/bash
set -euo pipefail

# =============================================================================
# Backup Foto Production — à exécuter sur le VPS actuel (Kamal)
# =============================================================================
# Ce script :
#   1. Arrête proprement le conteneur Foto pour garantir la cohérence SQLite
#   2. Archive le volume Docker 'foto_storage' (DB SQLite + fichiers Active Storage)
#   3. Sauvegarde les métadonnées du conteneur actif
#   4. Relance le conteneur
# =============================================================================

APP_NAME="foto"
VOLUME_NAME="foto_storage"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/${APP_NAME}-backup-${TIMESTAMP}"
BACKUP_ARCHIVE="${BACKUP_DIR}/${VOLUME_NAME}.tar.gz"

echo "═══════════════════════════════════════════════════════════════"
echo "  Backup ${APP_NAME} — ${TIMESTAMP}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── 0. Préparation ──────────────────────────────────────────────────────────
mkdir -p "$BACKUP_DIR"
echo "📁 Répertoire de backup : $BACKUP_DIR"
echo ""

# ─── 1. Identifier le conteneur actif ────────────────────────────────────────
CONTAINER_ID=$(docker ps -q --filter "name=${APP_NAME}" --filter "status=running" | head -n 1 || true)

if [ -n "$CONTAINER_ID" ]; then
  echo "🛑 Arrêt du conteneur ${APP_NAME} (${CONTAINER_ID})..."
  docker stop "$CONTAINER_ID"
  STOPPED_BY_SCRIPT=true
else
  echo "⚠️  Aucun conteneur ${APP_NAME} en cours d'exécution."
  STOPPED_BY_SCRIPT=false
fi
echo ""

# ─── 2. Backup du volume Docker ──────────────────────────────────────────────
echo "📦 Archivage du volume Docker '${VOLUME_NAME}'..."

if ! docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
  echo "❌ ERREUR : Le volume Docker '${VOLUME_NAME}' n'existe pas !"
  exit 1
fi

docker run --rm \
  -v "${VOLUME_NAME}:/data:ro" \
  -v "${BACKUP_DIR}:/backup" \
  alpine:latest \
  tar czf "/backup/${VOLUME_NAME}.tar.gz" -C /data .

if [ ! -f "$BACKUP_ARCHIVE" ]; then
  echo "❌ ERREUR : L'archive n'a pas été créée !"
  exit 1
fi

ARCHIVE_SIZE=$(du -sh "$BACKUP_ARCHIVE" | cut -f1)
echo "✅ Archive créée : ${BACKUP_ARCHIVE} (${ARCHIVE_SIZE})"
echo ""

# ─── 3. Sauvegarde des métadonnées ───────────────────────────────────────────
if [ -n "$CONTAINER_ID" ]; then
  echo "📝 Sauvegarde des métadonnées du conteneur..."
  docker inspect "$CONTAINER_ID" > "${BACKUP_DIR}/container-inspect.json"
  echo "   → container-inspect.json"

  docker inspect "$CONTAINER_ID" --format='{{range .Config.Env}}{{println .}}{{end}}' > "${BACKUP_DIR}/container-env.txt"
  echo "   → container-env.txt"
fi

# Sauvegarder aussi la liste des images
docker images "*${APP_NAME}*" --format '{{.Repository}}:{{.Tag}}' > "${BACKUP_DIR}/docker-images.txt" 2>/dev/null || true
echo "   → docker-images.txt"
echo ""

# ─── 4. Relancer le conteneur ────────────────────────────────────────────────
if [ "$STOPPED_BY_SCRIPT" = true ]; then
  echo "▶️  Redémarrage du conteneur ${APP_NAME}..."
  docker start "$CONTAINER_ID"
  echo "✅ Conteneur relancé."
fi
echo ""

# ─── 5. Résumé ───────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "  Backup terminé avec succès"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📂 Emplacement : $BACKUP_DIR"
echo "   $(ls -lah "$BACKUP_DIR")"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Récupérer le backup en local :"
echo "      rsync -avz --progress $(hostname):${BACKUP_DIR} ~/foto-migration-backups/"
echo "   2. Stocker une copie ailleurs (S3, cloud...)"
echo "   3. Vérifier l'archive : tar tzf ${BACKUP_ARCHIVE} | head -20"
echo ""
