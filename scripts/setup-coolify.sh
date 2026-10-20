#!/bin/bash
set -euo pipefail

# =============================================================================
# Setup Coolify — à exécuter sur le NOUVEAU VPS (Ubuntu/Debian)
# =============================================================================
# Ce script :
#   1. Met à jour le système
#   2. Installe les dépendances de base (curl, docker si absent...)
#   3. Configure le firewall UFW
#   4. Lance l'installation officielle de Coolify
# =============================================================================

echo "═══════════════════════════════════════════════════════════════"
echo "  Installation de Coolify"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── 1. Mise à jour du système ───────────────────────────────────────────────
echo "🔄 Mise à jour des paquets..."
apt-get update && apt-get upgrade -y

# ─── 2. Prérequis ────────────────────────────────────────────────────────────
echo "📦 Installation des prérequis..."
apt-get install -y curl wget git ufw

# ─── 3. Firewall ─────────────────────────────────────────────────────────────
echo "🔥 Configuration du firewall UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   comment 'SSH'
ufw allow 80/tcp   comment 'HTTP'
ufw allow 443/tcp  comment 'HTTPS'
ufw allow 8000/tcp comment 'Coolify Panel'

if ! ufw status | grep -q "Status: active"; then
  echo "y" | ufw enable
fi

ufw status verbose

# ─── 4. Docker (optionnel — Coolify peut l'installer) ──────────────────────
# Coolify s'installe généralement avec Docker. Si Docker n'est pas présent,
# le script officiel le gère, mais on s'assure qu'il n'y a pas de conflit.
if command -v docker &> /dev/null; then
  echo "🐳 Docker est déjà installé."
  docker --version
else
  echo "🐳 Docker non détecté. Le script Coolify l'installera automatiquement."
fi

# ─── 5. Installation Coolify ─────────────────────────────────────────────────
echo ""
echo "🚀 Lancement de l'installation Coolify..."
echo "   (Cette étape peut prendre 3 à 5 minutes)"
echo ""

# Supprimer toute ancienne installation résiduelle
rm -rf /data/coolify 2>/dev/null || true

curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Installation terminée"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── 6. Informations d'accès ─────────────────────────────────────────────────
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "📍 Adresse IP du serveur : $IP_ADDRESS"
echo ""
echo "🔗 Accès au panel Coolify :"
echo "   http://${IP_ADDRESS}:8000"
echo ""
echo "👤 Identifiant par défaut : root@localhost"
echo "   (le mot de passe temporaire est affiché ci-dessus dans les logs)"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Ouvrir http://${IP_ADDRESS}:8000 dans le navigateur"
echo "   2. Se connecter et changer le mot de passe root"
echo "   3. Configurer le domaine de Coolify dans Settings"
echo "   4. Créer le projet 'foto' et déployer l'application"
echo ""
