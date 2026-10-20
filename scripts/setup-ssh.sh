#!/bin/bash
# setup-ssh.sh
# À exécuter dans un terminal normal (hors de pi), ou directement ici avec bash

VPS_IP="54.36.100.76"
VPS_USER="ubuntu"
SSH_KEY="$HOME/.ssh/id_ed25519.pub"

echo "🔑 Configuration SSH rapide pour $VPS_USER@$VPS_IP"

# 1. Copier la clé publique sur le VPS
if [ -f "$SSH_KEY" ]; then
  echo "→ Envoi de la clé publique sur le VPS..."
  cat "$SSH_KEY" | ssh "$VPS_USER@$VPS_IP" "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
  echo "✅ Clé copiée."
else
  echo "❌ Clé $SSH_KEY non trouvée"
  exit 1
fi

# 2. Créer l'alias
mkdir -p ~/.ssh
cat >> ~/.ssh/config << EOF
Host foto
    HostName $VPS_IP
    User $VPS_USER
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
echo "✅ Alias 'foto' créé dans ~/.ssh/config"

echo ""
echo "🧪 Teste maintenant: ssh foto"
echo "   (ça doit te connecter SANS mot de passe)"
