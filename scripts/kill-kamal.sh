#!/bin/bash
# =============================================================================
# kill-kamal.sh — Arrêt propre de Kamal sur le VPS actuel
# =============================================================================
# À exécuter SUR le VPS (planifier sudo) :
#   sudo /tmp/kill-kamal.sh            # DRY-RUN : affiche ce qui serait fait
#   sudo /tmp/kill-kamal.sh --yes      # exécute réellement
#
# Ce script :
#   1. Liste et supprime les conteneurs de l'app 'foto'
#   2. Supprime le proxy 'kamal-proxy' (qui occupait les ports 80/443)
#   3. PRÉSERVE TOUJOURS le volume 'foto_storage' (SQLite + images)
#   4. Vérifie que 80/443/8000 sont bien libérés pour Coolify (Traefik)
#
# SECURITÉ :
#   - DRY-RUN par défaut (rien n'est supprimé sans --yes)
#   - AUCUNE commande `docker volume rm` dans ce script
#   - Idempotent : re-lançable sans danger
# =============================================================================

set -euo pipefail

APP_NAME="foto"
PROXY_NAME="kamal-proxy"
VOLUME_NAME="foto_storage"

dry_run=true
[[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && dry_run=false

say()  { echo -e "$*"; }
info() { echo -e "ℹ️  $*"; }
ok()   { echo -e "✅ $*"; }
warn() { echo -e "⚠️  $*"; }
fail() { echo -e "❌ $*"; }

app_containers()  { docker ps -aq --filter "name=${APP_NAME}"; }
proxy_container() { docker ps -aq --filter "name=${PROXY_NAME}"; }

volume_exists() { docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; }

volume_size() {
  docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:latest du -sh /data 2>/dev/null | cut -f1
}

volume_file_count() {
  docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:latest \
    sh -c 'find /data -type f | wc -l' 2>/dev/null | tr -d ' '
}

say "═══════════════════════════════════════════════════════════════"
say "  Arrêt de Kamal — VPS actuel"
say "═══════════════════════════════════════════════════════════════"
if [ "$dry_run" = true ]; then
  warn "MODE DRY-RUN — aucune action ne sera effectuée."
else
  warn "MODE EXÉCUTION — les conteneurs Kamal vont être supprimés."
fi
say ""

# ─── 0. État actuel ──────────────────────────────────────────────────────────
info "Conteneurs présents sur la machine :"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
say ""

if volume_exists; then
  ok "Le volume '${VOLUME_NAME}' existe — taille : $(volume_size) — fichiers : $(volume_file_count)"
else
  fail "Le volume '${VOLUME_NAME}' est INTROUVABLE ! STOP — ne lance pas --yes."
  exit 1
fi
say ""

# ─── 1. Identification des conteneurs à supprimer ────────────────────────────
APP_IDS=$(app_containers || true)
PROXY_ID=$(proxy_container || true)

if [ -n "$APP_IDS" ]; then
  info "Conteneurs '${APP_NAME}' à supprimer :"
  echo "$APP_IDS" | while read -r id; do
    name=$(docker inspect --format '{{.Name}}' "$id" 2>/dev/null | sed 's|^/||')
    echo "   - $name ($id)"
  done
else
  info "Aucun conteneur '${APP_NAME}' restant. Rien à supprimer de ce côté."
fi

if [ -n "$PROXY_ID" ]; then
  info "Proxy Kamal à supprimer :"
  docker inspect --format '   - {{.Name}} ({{.Id}})' "$PROXY_ID"
else
  info "Aucun conteneur '${PROXY_NAME}' trouvé."
fi
say ""

# ─── 2. Exécution (ou dry-run) ───────────────────────────────────────────────
if [ "$dry_run" = true ]; then
  warn "DRY-RUN : utilise --yes pour exécuter réellement les suppressions ci-dessous."
  say ""
  say "🐳 Commandes qui seraient exécutées :"
  if [ -n "$APP_IDS" ]; then
    echo "$APP_IDS" | while read -r id; do echo "   docker rm -f $id"; done
  fi
  [ -n "$PROXY_ID" ] && echo "   docker rm -f $PROXY_ID"
  say ""
  exit 0
fi

if [ -n "$APP_IDS" ]; then
  info "Suppression des conteneurs '${APP_NAME}'..."
  docker rm -f $APP_IDS
fi

if [ -n "$PROXY_ID" ]; then
  info "Suppression du proxy '${PROXY_NAME}'..."
  docker rm -f "$PROXY_ID"
fi
say ""

# ─── 3. Vérifications post-kill ──────────────────────────────────────────────
ok "Conteneurs restants :"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
say ""

if volume_exists; then
  ok "Le volume '${VOLUME_NAME}' est INTACT — taille : $(volume_size) — fichiers : $(volume_file_count)"
else
  fail "ALERTE : le volume '${VOLUME_NAME}' a disparu !!"
fi
say ""

info "Vérification des ports 80 / 443 / 8000 (doivent être libres) :"
for port in 80 443 8000; do
  if ss -ltn 2>/dev/null | grep -q ":${port} "; then
    fail "Le port ${port} est ENCORE occupé."
  else
    ok "Port ${port} libre."
  fi
done
say ""

ok "Terminé. Lance maintenant la vérification complète :"
say "   sudo /tmp/verify-migration.sh post-kill"