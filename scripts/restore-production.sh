#!/bin/bash
set -euo pipefail

# =============================================================================
# Restore Foto Production — à exécuter sur le NOUVEAU VPS (Coolify)
# =============================================================================
# Ce script restaure un backup créé par backup-production.sh dans le volume
# Docker utilisé par Coolify.
#
# Usage :
#   ./restore-production.sh /tmp/foto_storage.tar.gz
# =============================================================================

if [ $# -lt 1 ]; then
  echo "Usage: $0 <chemin/vers/foto_storage.tar.gz>"
  echo ""
  echo "Exemple :"
  echo "  $0 /tmp/foto_storage.tar.gz"
  exit 1
fi

BACKUP_FILE="$1"
VOLUME_NAME="foto-storage"
TEMP_CONTAINER_NAME="foto-restore-$(date +%s)"

echo "═══════════════════════════════════════════════════════════════"
echo "  Restauration ${VOLUME_NAME}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── 0. Vérifications ────────────────────────────────────────────────────────
if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ ERREUR : Le fichier '${BACKUP_FILE}' n'existe pas."
  exit 1
fi

if ! docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
  echo "❌ ERREUR : Le volume Docker '${VOLUME_NAME}' n'existe pas."
  echo ""
  echo "Assure-toi d'avoir :"
  echo "  1. Déployé au moins une fois l'app 'foto' dans Coolify"
  echo "  2. Configuré un volume nommé '${VOLUME_NAME}' → /rails/storage"
  echo ""
  echo "Volumes existants :"
  docker volume ls
  exit 1
fi

echo "📦 Archive source : $BACKUP_FILE ($(du -sh "$BACKUP_FILE" | cut -f1))"
echo "🎯 Volume cible   : $VOLUME_NAME"
echo ""

# ─── 1. Avertissement et confirmation ────────────────────────────────────────
echo "⚠️  ATTENTION : Cette opération VA ÉCRASER les données actuelles"
echo "    du volume '${VOLUME_NAME}'."
echo ""
read -p "Continuer ? [o/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Oo]$ ]]; then
  echo "❌ Annulé."
  exit 0
fi
echo ""

# ─── 2. Vider le volume existant ─────────────────────────────────────────────
echo "🧹 Nettoyage du volume cible..."
docker run --rm -v "${VOLUME_NAME}:/data" alpine:latest rm -rf /data/* /data/.* 2>/dev/null || true
echo "✅ Volume nettoyé."
echo ""

# ─── 3. Extraire l'archive ───────────────────────────────────────────────────
echo "📥 Extraction de l'archive dans le volume..."
docker run --rm \
  --name "$TEMP_CONTAINER_NAME" \
  -v "${VOLUME_NAME}:/data" \
  -v "$(dirname "$BACKUP_FILE"):/backup:ro" \
  alpine:latest \
  tar xzf "/backup/$(basename "$BACKUP_FILE")" -C /data

echo "✅ Extraction terminée."
echo ""

# ─── 4. Fixer les permissions ────────────────────────────────────────────────
echo "🔧 Application des permissions (uid:gid = 1000:1000)..."
docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  alpine:latest \
  chown -R 1000:1000 /data

echo "✅ Permissions fixées."
echo ""

# ─── 5. Vérification rapide ──────────────────────────────────────────────────
echo "🔍 Vérification du contenu restauré :"
docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  alpine:latest \
  sh -c '
    echo "--- Tailles ---"
    du -sh /data
    echo ""
    echo "--- Décompte fichiers ---"
    find /data -type f | wc -l | xargs echo "Fichiers :"
    echo ""
    echo "--- Présence DB ---"
    ls -lh /data/*.sqlite3 2>/dev/null || echo "(pas de .sqlite3 à la racine)"
    echo ""
    echo "--- Permissions racine ---"
    ls -la /data | head -15
  '
echo ""

# ─── 6. Résumé ───────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "  Restauration terminée avec succès"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Redémarrer le conteneur foto depuis l'interface Coolify"
echo "   2. Vérifier que https://foto.tondomaine.dev fonctionne"
echo "   3. Tester l'affichage des anciennes photos"
echo "   4. Uploader une nouvelle photo et vérifier la persistance"
echo ""
