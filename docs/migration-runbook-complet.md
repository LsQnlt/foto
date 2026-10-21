# Runbook complet — Migration Foto (Kamal → Coolify)

> Session du 20 octobre 2026.
> Objectif : migrer `foto.rip` de Kamal 2 vers Coolify sur le même VPS OVH.
>
> **Statut final** : ✅ Migration réussie. `foto.rip` est en ligne sur Coolify.

---

## 🗺️ Vue d'ensemble de l'architecture finale

```
VPS OVH (54.36.100.76) — Ubuntu 24.04 LTS
├── Coolify (panel : https://coolify.lsqnlt.dev)
│   └── Traefik (reverse proxy + SSL Let's Encrypt)
│
└── App "foto"
    ├── Image Docker : lsqnlt/coolify:latest
    ├── Volume persistant : foto-storage → /rails/storage
    │   ├── SQLite (4 bases : production, cache, queue, cable)
    │   └── Active Storage (6200+ fichiers, ~3.5 Go)
    └── Domaine : https://foto.rip

DNS lsqnlt.dev :
    A  coolify.lsqnlt.dev  → 54.36.100.76
    A  lsqnlt.dev          → 54.36.100.76 (futur blog)
    A  *.lsqnlt.dev        → 54.36.100.76
```

---

## 📋 Prérequis avant toute migration

- [ ] Avoir accès SSH au VPS avec une clé SSH (`~/.ssh/id_ed25519.pub`)
- [ ] Avoir les secrets de l'app (`RAILS_MASTER_KEY`, `SMTP_USERNAME`, `SMTP_PASSWORD`)
- [ ] Avoir le repo GitHub accessible : `https://github.com/LsQnlt/foto`
- [ ] Avoir un domaine principal (ex: `lsqnlt.dev`) + le domaine de l'app (`foto.rip`)
- [ ] **Disposer d'une copie locale du backup** (`~/foto-migration-backups/foto_storage.tar.gz`)

---

## 🚨 Complications majeures rencontrées et solutions

### 1. Ubuntu 24.10 (non-LTS) morte sur le VPS

**Symptôme** : `apt-get update` renvoie des 404 sur tous les repos (`nova.clouds.archive.ubuntu.com`, `security.ubuntu.com`).

**Cause** : Ubuntu 24.10 (Oracular Oriole) est EOL depuis juillet 2026. Les repos ont été supprimés des miroirs OVH.

**Solution adoptée** : **Réinstallation complète du VPS** en Ubuntu 24.04.4 LTS via le Manager OVH. L'IP (54.36.100.76) reste la même, donc les DNS de `foto.rip` restent valides.

**Leçon** : **Toujours utiliser une Ubuntu LTS** (20.04, 22.04, 24.04). Les `.10` intermédiaires ne sont supportées que 9 mois.

---

### 2. `/tmp` en tmpfs de 960 Mo

**Symptôme** : Le script `backup-production.sh` crashe avec `No space left on device` alors que le disque fait 38 Go.

**Cause** : Ubuntu monte `/tmp` en `tmpfs` (RAM disk) avec une taille limitée à ~960 Mo (50% de la RAM). Le volume Docker fait 3.5 Go.

**Solution** : Backup via **piping direct SSH** — `tar` s'envoie en local sans écrire sur le serveur :

```bash
ssh ubuntu@<IP> "docker run --rm -v foto_storage:/data alpine tar czf - -C /data ." \
  > ~/foto-migration-backups/foto_storage.tar.gz
```

Alternative : utiliser `/var/tmp` (disque physique, pas de limite RAM).

**Leçon** : **Ne jamais stocker de gros fichiers dans `/tmp` sur un VPS 2 Go.** Utiliser `/var/tmp` ou du piping.

---

### 3. BuildKit refuse de builder à cause de `# check=error=true`

**Symptôme** : `Deployment failed: lint violation found for rules: SecretsUsedInArgOrEnv`

**Cause** : Le Dockerfile contenait `# check=error=true` (directive lint BuildKit). Elle transforme les warnings en erreurs bloquantes quand on utilise `ARG` pour des secrets.

**Solution** : Supprimer la ligne `2` du Dockerfile :

```bash
sed -i '/check=error=true/d' Dockerfile
git add Dockerfile && git commit -m "Remove check=error=true for BuildKit compatibility"
git push origin main
```

**Leçon** : `check=error=true` est incompatible avec les images Rails classiques qui utilisent `ARG RAILS_MASTER_KEY`.

---

### 4. RAM insuffisante (2 Go) pour builder depuis le repo

**Symptôme** : Le build depuis GitHub plante le serveur (freeze total, plus d'accès SSH, UI Coolify déconnectée).

**Cause** : `bundle install` + `assets:precompile` + `docker build` consomment facilement 2–3 Go de RAM. Le VPS n'a que 2 Go. Le système swap à mort puis freeze.

**Solution adoptée** : Passer en mode **Docker Image** dans Coolify (`lsqnlt/coolify:latest`) au lieu de builder depuis le repo.

**Leçon** : **Un VPS pour builder des images Rails doit avoir 4 Go de RAM minimum.** Pour 2 Go, utiliser uniquement des images pré-buildées (Docker Hub).

---

### 5. Image Docker Hub privée → pull denied

**Symptôme** : `pull access denied for lsqnlt/foto, repository does not exist or may require 'docker login'`

**Cause** : L'image `lsqnlt/coolify:latest` était en mode **Private** sur Docker Hub.

**Solution** : Passer l'image en **Public** sur Docker Hub (Settings → Visibility → Public).

**Note pour plus tard** : Pour reprivatiser, il faudra configurer un Registry (`Sources` → `Private Registry`) dans Coolify avec un token Docker Hub.

---

### 6. Volume Coolify avec préfixe (volume vide créé)

**Symptôme** : L'app démarre avec une base SQLite vide (~184 Ko), aucune photo.

**Cause** : Dans Coolify, quand on ajoute un mount sans cocher **"Share volume"**, Coolify ajoute un préfixe magique :
```
z6ablzzdo3dz07cdxnjovc6x-foto-storage   # volume vide créé par Coolify
```
```
foto-storage                             # le vrai volume restauré
```

**Solution** : Dans Coolify → Storage → **cocher "Share volume"** (ou utiliser le nom exact sans préfixe). Le volume doit porter strictement le nom `foto-storage`.

---

### 7. Fingerpring SSH changé après réinstallation

**Symptôme** : `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`

**Solution** :
```bash
ssh-keygen -R 54.36.100.76
ssh ubuntu@54.36.100.76
# taper "yes" pour accepter le nouveau fingerprint
```

---

## 🔧 Commandes complètes (pour reproduction sur un nouveau VPS)

### Avant la migration — Backup des données

```bash
# Sur la machine locale
mkdir -p ~/foto-migration-backups

# Arrêter le conteneur et backup via pipe (pas d'écriture sur /tmp du serveur)
ssh ubuntu@54.36.100.76 "docker stop \\\$(docker ps -q --filter name=foto | head -1)"

ssh ubuntu@54.36.100.76 \
  "docker run --rm -v foto_storage:/data alpine tar czf - -C /data ." \
  > ~/foto-migration-backups/foto_storage.tar.gz

ssh ubuntu@54.36.100.76 \
  "docker start \\\$(docker ps -aq --filter name=foto | head -1)"

# Vérifier le backup
tar tzf ~/foto-migration-backups/foto_storage.tar.gz | wc -l
# attendu : ~6200 fichiers
```

---

### Réinstallation du VPS (si OS EOL ou migration vers nouveau hardware)

```bash
# 1. Depuis le Manager OVH : Réinstaller
#    OS : Ubuntu 24.04 LTS Server 64bits
#    Clé SSH : coller le contenu de ~/.ssh/id_ed25519.pub

# 2. Après réception du mail OVH
cat ~/.ssh/id_ed25519.pub | ssh ubuntu@54.36.100.76 \
  "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"

# Si fingerprint conflict :
ssh-keygen -R 54.36.100.76

# 3. Alias SSH (optionnel)
mkdir -p ~/.ssh
cat >> ~/.ssh/config << 'EOF'
Host foto
    HostName 54.36.100.76
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
```

---

### Installation Coolify + restauration données

```bash
# 1. Connexion et maj
ssh coolify
sudo apt update && sudo apt upgrade -y
# NOTE : si le kernel a changé, rebooter :
# sudo reboot

# 2. Installer Coolify
sudo bash -c 'curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash'
# Copier l'URL affichée (http://<IP>:8000) et le mot de passe root temporaire
# Créer immédiatement le compte admin dans l'UI

# 3. Backup de l'env Coolify (en local, depuis un autre terminal)
ssh coolify "sudo cat /data/coolify/source/.env" > ~/foto-migration-backups/coolify-env-backup

# 4. Créer le volume Docker et restaurer les données
ssh coolify "sudo docker volume create foto-storage"
scp ~/foto-migration-backups/foto_storage.tar.gz coolify:/var/tmp/
ssh coolify "sudo docker run --rm -v foto-storage:/data -v /var/tmp:/backup alpine tar xzf /backup/foto_storage.tar.gz -C /data"
ssh coolify "sudo docker run --rm -v foto-storage:/data alpine chown -R 1000:1000 /data"

# 5. Vérifier la restauration
ssh coolify "sudo docker run --rm -v foto-storage:/data alpine sh -c 'du -sh /data && ls /data/*.sqlite3'"
# Attendu : 3.5G + production.sqlite3, production_cache.sqlite3, production_queue.sqlite3, production_cable.sqlite3
```

---

### Configuration dans l'UI Coolify

1. **Projects** → **Create Project** (nom : `foto`)
2. **Add Resource** → **Application**
3. **Source** : `Docker Image` (PAS Public Repository si le serveur a peu de RAM)
4. **Image** : `lsqnlt/coolify:latest`
5. **Build** :
   - Base Directory : `/`
   - Dockerfile location : laisser par défaut (pas utilisé en mode Docker Image)
6. **Environment Variables** :

| Variable | Valeur | Secret |
|----------|--------|--------|
| `RAILS_MASTER_KEY` | (depuis `.kamal/secrets`) | ✅ |
| `SMTP_USERNAME` | (depuis Brevo) | ✅ |
| `SMTP_PASSWORD` | (depuis `.kamal/secrets`) | ✅ |
| `RAILS_ENV` | `production` | ❌ |
| `SOLID_QUEUE_IN_PUMA` | `true` | ❌ |
| `RAILS_LOG_LEVEL` | `info` | ❌ |

7. **Storage** → **Add Mount** :
   - Type : **Volume Mount**
   - ✅ **Share volume** (ou "Use exact name") — **SINON le volume sera vide**
   - Name : `foto-storage`
   - Destination Path : `/rails/storage`
8. **Domains** :
   - Domain : `foto.rip`
   - SSL/TLS : ✅ Enabled
9. **Deploy**

---

### Post-install : domaine du panel Coolify

Dans l'UI Coolify → Settings (⚙️) :
- Instance URL : `https://coolify.lsqnlt.dev`
- (Parfois il faut mettre `http://` d'abord, Traefik gère le SSL ensuite)

Dans le DNS (registrar, ex: OVH) :
```
A  coolify.lsqnlt.dev    54.36.100.76
A  lsqnlt.dev            54.36.100.76
A  *.lsqnlt.dev          54.36.100.76
```

Vérification DNS :
```bash
dig coolify.lsqnlt.dev +short
# attendu : 54.36.100.76
```

---

## 🧹 Maintenance ultérieure

### Vérifier l'intégrité des données

```bash
# Sur le serveur
ssh coolify
sudo docker run --rm -v foto-storage:/data alpine sh -c '
  echo "Fichiers : $(find /data -type f | wc -l)"
  echo "Taille : $(du -sh /data)"
  for db in /data/*.sqlite3; do
    head -c 16 "$db" | od -An -tx1 | grep -q "53 51 4c 69 74 65 20 66 6f 72 6d 61 74 20 33 00" \
      && echo "$(basename $db) OK" || echo "$(basename $db) CORROMPU"
  done
'
```

### Vérifier les logs de l'app

```bash
ssh coolify "sudo docker logs \\\$(sudo docker ps -q --filter ancestor=lsqnlt/coolify:latest | head -1) --tail 50"
```

### Redéployer (si nouvelle image pushée)

Depuis l'UI Coolify : bouton **Redeploy**.

Ou forcer un pull :
```bash
ssh coolify "sudo docker pull lsqnlt/coolify:latest"
# puis Redeploy dans l'UI
```

---

## 🔐 Checklist sécurité (post-migration)

- [ ] Compte admin Coolify créé + mot de passe fort
- [ ] `/data/coolify/source/.env` backupé en local
- [ ] Image Docker Hub reprivatisée (TODO dans prochaine session)
- [ ] Variables d'environnement secrètes cochées "Secret" dans Coolify
- [ ] Firewall UFW actif (22, 80, 443, 8000)
- [ ] Backup local `foto_storage.tar.gz` conservé ≥ 30 jours
- [ ] Anciens secrets Kamal (`.kamal/secrets`) désactivés

---

## 🆘 Rollback complet

Si tout casse et qu'il faut revenir à zéro :

```bash
# Le volume foto-storage sur le serveur est intact
# L'image Docker est sur Docker Hub
# Les secrets sont en local

# 1. Réinstaller Coolify (ou refaire un VPS frais)
# 2. Restaurer le volume depuis l'archive locale
# 3. Recréer la resource dans Coolify avec les même settings
```

---

## 💡 Pour un futur VPS (checklist dimensionnement)

| Ressource | Minimum pour Foto | Recommandé |
|-----------|-------------------|------------|
| RAM | 2 Go (limite, pas de build possible) | **4 Go** |
| Disk | 40 Go SSD | **80 Go SSD** |
| vCPU | 1 | **2** |
| OS | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| Build strategy | Docker Image (pré-buildée) | Docker Image ou 4 Go+ pour build |
| Méthode backup | Piping SSH ou `/var/tmp` | `/var/tmp` (pas `/tmp` en tmpfs) |

---

## 📁 Fichiers liés à cette migration

- `docs/migration-coolify-inplace.md` — plan initial
- `docs/migration-coolify.md` — plan alternatif (nouveau VPS)
- `scripts/kill-kamal.sh` — arrêt propre de Kamal
- `scripts/verify-migration.sh` — vérifications par phase
- `scripts/backup-production.sh` — backup (attention au /tmp)
- `scripts/restore-production.sh` — restauration (via volume)
- `scripts/setup-coolify.sh` — installation Coolify
- `scripts/setup-ssh.sh` — création de l'alias SSH
- `docs/resource-analysis.md` — analyse des ressources prod
