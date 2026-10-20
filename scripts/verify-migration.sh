#!/bin/bash
# =============================================================================
# verify-migration.sh — Vérifications de la migration in-place (Coolify)
# =============================================================================
# À exécuter SUR le VPS (planifier sudo) :
#   sudo /tmp/verify-migration.sh preflight     # AVANT de tuer Kamal
#   sudo /tmp/verify-migration.sh post-kill     # APRÈS kill-kamal.sh
#   sudo /tmp/verify-migration.sh coolify       # APRÈS l'install Coolify
#   sudo /tmp/verify-migration.sh app           # APRÈS le déploiement de foto
#   sudo /tmp/verify-migration.sh data          # INTÉGRITÉ données (fichiers + SQLite)
#
# Chaque étape affiche un rapport PASS / FAIL / INFO et sort avec un code
# d'erreur non nul si au moins un FAIL est détecté.
# =============================================================================

set -uo pipefail

APP_NAME="foto"
VOLUME_NAME="foto_storage"
PROXY_NAME="kamal-proxy"
BASELINE="/tmp/foto-migration-baseline"

MIN_RAM_MB="${MIN_RAM_MB:-2048}"   # RAM libre minimum recommandée (Mo)
MIN_DISK_GB="${MIN_DISK_GB:-10}"   # Disque libre minimum recommandé (Go)

PASS=0; FAILED=0; INFO=0

ok()   { echo -e "  ✅ PASS  $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ❌ FAIL  $1"; FAILED=$((FAILED+1)); }
info() { echo -e "  ℹ️  INFO  $1"; INFO=$((INFO+1)); }
hdr()  { echo -e ""; echo -e "── $1 ───────────────────────────────────────────"; }

summary() {
  echo -e ""
  echo -e "═════════════════════════════════════════════════"
  echo -e "  RÉSULTAT : ${PASS} PASS / ${FAILED} FAIL / ${INFO} INFO"
  echo -e "═════════════════════════════════════════════════"
  if [ "$FAILED" -gt 0 ]; then
    echo -e "❌ Des vérifications ont échoué. Corrige avant d'aller plus loin."
    exit 1
  else
    echo -e "✅ Tout est au vert pour cette étape."
    exit 0
  fi
}

need_docker() {
  if ! docker info >/dev/null 2>&1; then
    fail "Docker n'est pas accessible. Relance le script avec sudo."
    summary
  fi
}

# ─── Helpers de mesure du volume ─────────────────────────────────────────────
vol_size()   { docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:latest du -sh /data 2>/dev/null | cut -f1; }
vol_files()  { docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:latest sh -c 'find /data -type f | wc -l' 2>/dev/null | tr -d ' '; }
vol_sqlite() { docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:latest sh -c 'ls -1 /data/*.sqlite3 2>/dev/null'; }

free_ram_mb() { awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo; }
free_disk_gb(){ df -BG / | awk 'NR==2 {gsub(/G/,"",$4); print $4}'; }

write_baseline() {
  mkdir -p "$(dirname "$BASELINE")"
  {
    echo "VOLUME_SIZE=$(vol_size)"
    echo "FILE_COUNT=$(vol_files)"
    echo "DB_FILES=$(vol_sqlite | tr '\n' ',' )"
    echo "TIMESTAMP=$(date +%Y%m%d-%H%M%S)"
  } > "$BASELINE"
}

read_baseline() {
  [ -f "$BASELINE" ] && grep "^${1}=" "$BASELINE" | cut -d= -f2- || echo ""
}

# ═════════════════════════════════════════════════════════════════════════
#  STAGE : preflight (avant de toucher à quoi que ce soit)
# ═════════════════════════════════════════════════════════════════════════
stage_preflight() {
  need_docker
  echo -e "═════════════════════════════════════════════════"
  echo -e "  PREFLIGHT — état des lieux avant migration"
  echo -e "═════════════════════════════════════════════════"

  # 1. Docker
  hdr "Docker"
  info "docker $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"

  # 2. Volume
  hdr "Volume '${VOLUME_NAME}'"
  if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    ok "Volume présent — taille : $(vol_size) — fichiers : $(vol_files)"
  else
    fail "Volume '${VOLUME_NAME}' introuvable"
  fi

  # 3. Conteneurs Kamal
  hdr "Conteneurs Kamal"
  if [ -n "$(docker ps -q --filter "name=${APP_NAME}")" ]; then
    ok "Conteneur(s) '${APP_NAME}' en cours d'exécution"
  else
    fail "Aucun conteneur '${APP_NAME}' ne tourne"
  fi
  if [ -n "$(docker ps -q --filter "name=${PROXY_NAME}")" ]; then
    ok "Proxy '${PROXY_NAME}' en cours d'exécution"
  else
    fail "Proxy '${PROXY_NAME}' non détecté"
  fi

  # 4. Ports actuellement occupés (informatif)
  hdr "Ports occupés actuellement (informatif)"
  for port in 80 443; do
    if ss -ltn 2>/dev/null | grep -q ":${port} "; then
      info "Port ${port} occupé (normal : c'est kamal-proxy)"
    else
      info "Port ${port} libre (surprenant ? vérifie que le site tourne)"
    fi
  done

  # 5. Dimensionnement (le vrai gate)
  hdr "Dimensionnement (Coolify va s'ajouter au VPS)"
  ram=$(free_ram_mb)
  disk=$(free_disk_gb)
  info "RAM libre : ${ram} Mo — Disque libre : ${disk} Go"
  if [ "${ram:-0}" -ge "$MIN_RAM_MB" ]; then
    ok "RAM libre suffisante (>= ${MIN_RAM_MB} Mo)"
  else
    fail "RAM libre insuffisante pour Coolify + foto (considère un VPS plus gros ou le plan 'nouveau VPS')"
  fi
  if [ "${disk:-0}" -ge "$MIN_DISK_GB" ]; then
    ok "Disque libre suffisant (>= ${MIN_DISK_GB} Go)"
  else
    fail "Disque libre insuffisant"
  fi

  # 6. Backup présent
  hdr "Backup"
  if ls /tmp/foto-backup-* >/dev/null 2>&1; then
    ok "Backup(s) trouvé(s) dans /tmp :"
    ls -d /tmp/foto-backup-* | sed 's/^/       /'
    info "Pense à en garder une COPIE LOCALE avant de killer Kamal (rsync)."
  else
    fail "Aucun backup trouvé dans /tmp — exécute d'abord scripts/backup-production.sh"
  fi

  # 7. DNS (informatif)
  hdr "DNS foto.rip (informatif)"
  resolved=$(getent hosts foto.rip | awk '{print $1}' | head -1)
  info "foto.rip résout vers : ${resolved:-'(non résolu)'}"
  info "IP du serveur (interfaces) : $(hostname -I 2>/dev/null | tr ' ' ', ')"
  info "Si ces IP diffèrent, foto.rip passe peut-être par Cloudflare/proxy — rien à changer, sinon vérifie."

  # Écrire la baseline pour les comparaisons postérieures
  write_baseline
  info "Baseline enregistrée dans ${BASELINE} (taille/nb fichiers à comparer plus tard)"
  summary
}

# ═════════════════════════════════════════════════════════════════════════
#  STAGE : post-kill (après kill-kamal.sh)
# ═════════════════════════════════════════════════════════════════════════
stage_post_kill() {
  need_docker
  echo -e "═════════════════════════════════════════════════"
  echo -e "  POST-KILL — Kamal arrêté, prêt pour Coolify"
  echo -e "═════════════════════════════════════════════════"

  hdr "Conteneurs Kamal supprimés"
  if [ -z "$(docker ps -a -q --filter "name=${APP_NAME}")" ]; then
    ok "Plus aucun conteneur '${APP_NAME}'"
  else
    fail "Des conteneurs '${APP_NAME}' existent encore (même stoppés)"
  fi
  if [ -z "$(docker ps -a -q --filter "name=${PROXY_NAME}")" ]; then
    ok "Plus de proxy '${PROXY_NAME}'"
  else
    fail "Le proxy '${PROXY_NAME}' existe encore"
  fi

  hdr "Ports libérés"
  for port in 80 443 8000; do
    if ss -ltn 2>/dev/null | grep -q ":${port} "; then
      fail "Port ${port} encore occupé"
    else
      ok "Port ${port} libre"
    fi
  done

  hdr "Volume intact"
  if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    ok "Volume présent — taille : $(vol_size) — fichiers : $(vol_files)"
    base_size=$(read_baseline VOLUME_SIZE)
    base_files=$(read_baseline FILE_COUNT)
    if [ -n "$base_size" ] && [ "$base_size" = "$(vol_size)" ]; then
      ok "Taille du volume identique à la baseline (${base_size})"
    elif [ -n "$base_size" ]; then
      fail "La taille du volume a changé (baseline ${base_size} vs ${base_files:-?} fichiers) → vérifie !"
    else
      info "Pas de baseline pour comparaison stricte."
    fi
    if [ -n "$base_files" ] && [ "$base_files" = "$(vol_files)" ]; then
      ok "Nombre de fichiers identique à la baseline (${base_files})"
    elif [ -n "$base_files" ]; then
      fail "Le nombre de fichiers a changé (${base_files} → $(vol_files))"
    fi
  else
    fail "Volume '${VOLUME_NAME}' introuvable !!"
  fi

  summary
}

# ═════════════════════════════════════════════════════════════════════════
#  STAGE : coolify (après installation de Coolify)
# ═════════════════════════════════════════════════════════════════════════
stage_coolify() {
  need_docker
  echo -e "═════════════════════════════════════════════════"
  echo -e "  COOLIFY — vérification post-installation"
  echo -e "═════════════════════════════════════════════════"

  hdr "Conteneurs Coolify"
  if docker ps --format '{{.Names}}' | grep -qiE 'coolify|traefik'; then
    ok "Conteneurs Coolify détectés :"
    docker ps --format '{{.Names}}\t{{.Status}}' | grep -iE 'coolify|traefik' | sed 's/^/       /'
  else
    fail "Aucun conteneur Coolify/Traefik détecté"
  fi

  hdr "Ports"
  for port in 8000 443 80; do
    if ss -ltn 2>/dev/null | grep -q ":${port} "; then
      ok "Port ${port} en écoute"
    else
      fail "Port ${port} pas en écoute"
    fi
  done

  hdr "Panel Coolify"
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://localhost:8000 || echo "000")
  if [ "$code" = "200" ] || [ "$code" = "302" ] || [ "$code" = "303" ]; then
    ok "Panel Coolify répond (HTTP ${code}) sur :8000"
  else
    fail "Panel Coolify ne répond pas (HTTP ${code})"
  fi

  summary
}

# ═════════════════════════════════════════════════════════════════════════
#  STAGE : app (après déploiement de foto dans Coolify)
# ═════════════════════════════════════════════════════════════════════════
stage_app() {
  need_docker
  echo -e "═════════════════════════════════════════════════"
  echo -e "  APP — foto redéployé dans Coolify"
  echo -e "═════════════════════════════════════════════════"

  hdr "Conteneur foto (via le volume monté)"
  cid=$(docker ps -q --filter "volume=${VOLUME_NAME}")
  if [ -n "$cid" ]; then
    ok "Un conteneur monte bien '${VOLUME_NAME}' : $(docker inspect --format '{{.Name}}' "$cid" | sed 's|^/||')"
  else
    fail "Aucun conteneur ne monte '${VOLUME_NAME}' — redéploie et rattache le volume existant"
  fi

  hdr "Site foto.rip"
  code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 https://foto.rip || echo "000")
  if [ "$code" = "200" ]; then
    ok "https://foto.rip répond HTTP ${code}"
  elif [ "$code" = "000" ]; then
    fail "https://foto.rip injoignable"
  else
    fail "https://foto.rip répond HTTP ${code} (attendu 200)"
  fi

  hdr "Certificat SSL"
  exp=$(echo | openssl s_client -connect foto.rip:443 -servername foto.rip 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -n "$exp" ]; then
    ok "Certificat présent — expire le ${exp}"
  else
    fail "Impossible de récupérer le certificat SSL"
  fi

  summary
}

# ═════════════════════════════════════════════════════════════════════════
#  STAGE : data (intégrité des données)
# ═════════════════════════════════════════════════════════════════════════
stage_data() {
  need_docker
  echo -e "═════════════════════════════════════════════════"
  echo -e "  DATA — intégrité des fichiers et des bases SQLite"
  echo -e "═════════════════════════════════════════════════"

  hdr "Comptage de fichiers vs baseline"
  now_files=$(vol_files)
  info "Fichiers dans le volume : ${now_files}"
  base_files=$(read_baseline FILE_COUNT)
  if [ -n "$base_files" ]; then
    if [ "$now_files" -ge "$base_files" ]; then
      ok "Nombre de fichiers >= baseline (${base_files})"
    else
      fail "Moins de fichiers qu'avant la migration (${base_files} → ${now_files})"
    fi
  else
    info "Pas de baseline (générée au preflight)."
  fi

  hdr "Bases SQLite"
  dbs=$(vol_sqlite)
  if [ -z "$dbs" ]; then
    fail "Aucun fichier .sqlite3 trouvé dans le volume"
  else
    echo "$dbs" | while read -r db; do
      [ -z "$db" ] && continue
      header=$(docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:latest \
        sh -c "head -c 16 '${db}'" 2>/dev/null)
      if [ "$header" = "SQLite format 3" ]; then
        ok "$(basename "$db") — en-tête valide"
      else
        fail "$(basename "$db") — en-tête corrompu ou illisible"
      fi
    done
  fi

  hdr "Astuce vérification profonde (optionnel)"
  info "Pour un check SQLite complet, exécute depuis le conteneur foto :"
  info 'bin/rails runner "ActiveRecord::Base.connection.execute(\"PRAGMA integrity_check\")"'

  summary
}

# ═════════════════════════════════════════════════════════════════════════
#  Dispatcher
# ═════════════════════════════════════════════════════════════════════════
usage() {
  echo "Usage : sudo $0 <stage>"
  echo ""
  echo "Stages (dans l'ordre) :"
  echo "  preflight   AVANT de tuer Kamal (état des lieux + baseline)"
  echo "  post-kill   APRÈS kill-kamal.sh (ports libres, volume intact)"
  echo "  coolify     APRÈS l'installation de Coolify"
  echo "  app         APRÈS le déploiement de foto dans Coolify"
  echo "  data        Vérification d'intégrité des données (dernière étape)"
  echo ""
  echo "Variables d'environnement ajustables :"
  echo "  MIN_RAM_MB   (défaut 2048) RAM libre minimum"
  echo "  MIN_DISK_GB  (défaut 10)   Disque libre minimum"
}

case "${1:-}" in
  preflight) stage_preflight ;;
  post-kill) stage_post_kill ;;
  coolify)   stage_coolify ;;
  app)       stage_app ;;
  data)      stage_data ;;
  *) usage; exit 2 ;;
esac