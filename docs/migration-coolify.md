# Migration Foto → Coolify (nouveau VPS + nouveau domaine)

> **Statut** : Plan d'attaque — Phase 0 prête à exécuter  
> **Objectif** : Migrer l'app Rails `foto` de Kamal 2 (VPS OVH actuel) vers Coolify sur un nouveau VPS OVH, sans perte de données.

---

## 📋 Prérequis & Checklist avant départ

- [ ] Avoir accès SSH root/sudo sur le **VPS actuel** (`54.36.100.76`)
- [ ] Avoir `RAILS_MASTER_KEY` et `SMTP_*` (présents dans `.kamal/secrets` localement)
- [ ] Disposer d'un moyen de paiement pour le nouveau VPS + nouveau domaine
- [ ] S'assurer que le repo GitHub est accessible et à jour

---

## Phase 0 — Backup complet depuis le VPS actuel

> ⏱️ Downtime : ~2 min (arrêt du conteneur pour garantir la cohérence SQLite)  
> 📍 Où : sur le VPS actuel en SSH

### 0.1 Se connecter au VPS actuel

```bash
ssh ubuntu@54.36.100.76
```

### 0.2 Copier le script de backup

Depuis ta machine locale, copier le script sur le VPS :

```bash
scp scripts/backup-production.sh ubuntu@54.36.100.76:/tmp/backup-production.sh
```

Puis sur le VPS :

```bash
chmod +x /tmp/backup-production.sh
sudo /tmp/backup-production.sh
```

Le script va :
1. Créer un répertoire `/tmp/foto-backup-YYYYMMDD-HHMMSS/`
2. Arrêter le conteneur `foto` proprement
3. Dumper le volume Docker `foto_storage` dans une archive `foto_storage.tar.gz`
4. Sauvegarder les métadonnées du conteneur (image, env, etc.)
5. Relancer le conteneur

### 0.3 Récupérer le backup en local

```bash
# Sur ta machine locale
mkdir -p ~/foto-migration-backups
rsync -avz --progress ubuntu@54.36.100.76:/tmp/foto-backup-* ~/foto-migration-backups/
```

> 💡 **Astuce** : garde aussi une copie du backup ailleurs (cloud) par sécurité.

---

## Phase 1 — Infrastructure neuve

### 1.1 Souscrire un nouveau VPS OVH

- **OS** : Ubuntu 24.04 LTS (ou Debian 12)
- **Taille** : minimum équivalente à l'actuelle (app photo + SQLite = légère, mais Coolify consomme un peu plus)
- **Zone** : idéalement la même région (moins de latence)
- ** SSH key** : préconfigurer ta clé SSH

## 1.2 Choisir et configurer le nom de domaine principal

Tu vas utiliser **`louis.dev`** comme domaine principal. Ce domaine sera partagé entre plusieurs apps sur le même VPS.

### Domaines à configurer

| Domaine | Destination | Rôle |
|---------|------------|------|
| `louis.dev` | Nouveau VPS | Ton blog (future app Coolify) |
| `coolify.louis.dev` | Nouveau VPS | Panel d'administration Coolify |
| `foto.louis.dev` | Nouveau VPS | App foto (temporaire pendant la migration) |
| `foto.rip` | Nouveau VPS | App foto (domaine final, après cutover) |

### Enregistrements DNS (chez ton registrar)

```
A     louis.dev          → <IP_NOUVEAU_VPS>
A     coolify.louis.dev  → <IP_NOUVEAU_VPS>
A     foto.louis.dev     → <IP_NOUVEAU_VPS>
A     foto.rip           → <IP_NOUVEAU_VPS>
```

> 💡 Tu peux aussi mettre un wildcard `*.louis.dev` vers le nouveau VPS si tu prévois de lancer plein d'apps (ex: `app3.louis.dev`, `staging.louis.dev`).

> ⚠️ **Si ton blog `louis.dev` est actuellement ailleurs**, il faudra d'abord le migrer comme app Coolify, ou accepter un downtime temporaire si tu veux tout regrouper immédiatement.


---

## Phase 2 — Installation de Coolify

> 📍 Où : sur le nouveau VPS

### 2.1 Se connecter au nouveau VPS

```bash
ssh root@<IP_NOUVEAU_VPS>
```

### 2.2 Ouvir les ports nécessaires

Coolify a besoin de :
- `22` (SSH)
- `80` / `443` (HTTP/HTTPS — Traefik)
- `8000` (panel Coolify — à restreindre plus tard via firewall si besoin)

Sur OVH (depuis le manager ou via UFW) :
```bash
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8000
ufw enable
```

### 2.3 Installer Coolify

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

L'installation prend ~2-3 minutes. À la fin, elle affichera :
- L'URL du panel (ex: `http://<IP>:8000`)
- Le mot de passe root temporaire (à copier !)

### 2.4 Premier accès à Coolify

1. Ouvrir `http://<IP_NOUVEAU_VPS>:8000`
2. Se connecter avec `root@localhost` et le mot de passe affiché
3. Changer le mot de passe root immédiatement
4. Configurer le domaine de Coolify : `coolify.louis.dev`
5. Activer le SSL (Let's Encrypt) pour le panel Coolify

---

## Phase 3 — Déploiement de `foto` dans Coolify

### 3.1 Connecter le repo GitHub

1. Dans Coolify : **Projects** → **Create Project** (nom: `foto`)
2. **Add Resource** → **Application** → **Public Repository**
3. Coller l'URL GitHub : `https://github.com/LsQnlt/foto`
4. Branch : `main` (ou `master`)
5. Build Pack : **Dockerfile** (Coolify doit détecter automatiquement le `Dockerfile` à la racine)

### 3.2 Configuration du build

**Settings** → **General**
- Base Directory : `/` (racine)
- Dockerfile path : `Dockerfile`

**Settings** → ** Environment Variables**
Ajouter les variables suivantes :

| Clé | Valeur | Secret ? |
|-----|--------|----------|
| `RAILS_MASTER_KEY` | `8bf3a8b4d...` | ✅ |
| `SMTP_USERNAME` | `92e38f001@smtp-brevo.com` | ✅ |
| `SMTP_PASSWORD` | `tH2awqAUCTmO5hp3` | ✅ |
| `RAILS_ENV` | `production` | ❌ |
| `SOLID_QUEUE_IN_PUMA` | `true` | ❌ |
| `RAILS_LOG_LEVEL` | `info` | ❌ |

> ⚠️ Les variables marquées "Secret" doivent être cochées comme telles dans Coolify (ne seront pas affichées en clair).

### 3.3 Volume persistant (CRITIQUE)

C'est ce qui remplace `foto_storage:/rails/storage` de Kamal.

Dans Coolify, aller dans **Storage** (ou **Volumes** selon la version) :
- **Type** : `Volume`
- **Source** : `foto-storage` (nom explicite du volume Docker)
- **Destination** : `/rails/storage`
- **Read Only** : ❌

> 🔴 **Pourquoi c'est critique** : sans ce volume, chaque redéploiement Docker supprimerait toutes les images et la DB SQLite. Le volume persistant garantit la survie des données entre les builds.

### 3.4 Domaine & SSL

Dans **Settings** → **Domains** :
- Ajouter : `foto.louis.dev`
- SSL / HTTPS : ✅ activé (Let's Encrypt auto)

### 3.5 Premier déploiement (base vide)

Cliquer sur **Deploy**.

Ce premier build va :
- Construire l'image Docker
- Créer le volume `foto-storage` (vide)
- Lancer le container avec `db:prepare`
- Démarrer le serveur

Vérifier que `https://foto.louis.dev` répond (page d'accueil, mais sans les anciennes photos pour l'instant).

---

## Phase 4 — Restauration des données

> 📍 Où : sur le nouveau VPS

### 4.1 Copier le backup sur le nouveau VPS

```bash
# Depuis ta machine locale
scp ~/foto-migration-backups/foto-backup-*/foto_storage.tar.gz root@<IP_NOUVEAU_VPS>:/tmp/
```

### 4.2 Identifier le volume Coolify

Vérifier que le volume existe :
```bash
docker volume ls | grep foto
# Doit afficher : foto-storage (ou un nom similaire)
```

### 4.3 Exécuter le script de restauration

Copier le script sur le nouveau VPS :
```bash
scp scripts/restore-production.sh root@<IP_NOUVEAU_VPS>:/tmp/
ssh root@<IP_NOUVEAU_VPS> "chmod +x /tmp/restore-production.sh && /tmp/restore-production.sh /tmp/foto_storage.tar.gz"
```

Le script va :
1. Exporter le contenu de `foto_storage.tar.gz` dans le volume `foto-storage`
2. Appliquer les permissions `1000:1000` (user `rails` du container)

### 4.4 Redémarrer le container

Dans l'interface Coolify : **Restart** (ou **Redeploy**).

### 4.5 Vérifier l'intégrité

- [ ] Se connecter à `https://foto.louis.dev`
- [ ] Vérifier que toutes les anciennes photos s'affichent
- [ ] Se connecter en admin (si auth il y a)
- [ ] Uploader une nouvelle photo et vérifier qu'elle persiste après un redeploy
- [ ] Vérifier que `foto-storage` a bien grossi :
  ```bash
  docker run --rm -v foto-storage:/data alpine du -sh /data
  ```

---

## Phase 5 — Bascule DNS (cutover)

Une fois que `foto.louis.dev` est validé et stable :

### 5.1 Préparer la bascule de `foto.rip`

Modifier l'enregistrement DNS de `foto.rip` :
```
A   foto.rip   → <IP_NOUVEAU_VPS>
```

### 5.2 Ajouter `foto.rip` comme domaine dans Coolify

Dans Coolify, dans les settings de l'app `foto` :
- Ajouter le domaine `foto.rip`
- SSL : ✅ activé
- Redeploy

Coolify (via Traefik) gérera automatiquement le certificat Let's Encrypt pour `foto.rip`.

### 5.3 Attendre la propagation DNS

```bash
watch -n 5 dig foto.rip +short
```

Vérifier que `foto.rip` pointe bien vers la nouvelle IP.

### 5.4 Tester en production

- [ ] `https://foto.rip` fonctionne
- [ ] Les images s'affichent
- [ ] L'upload fonctionne
- [ ] Pas d'erreur SSL (certificat valide)

---

## Phase 6 — Nettoyage ancien VPS

Attendre 24-48h pour s'assurer que tout est stable, puis :

```bash
# Sur l'ancien VPS (54.36.100.76)
# Optionnel : arrêter proprement Kamal
docker stop $(docker ps -q --filter "name=foto")
docker rm $(docker ps -aq --filter "name=foto")
```

> ⚠️ Ne supprime **pas** le backup local (`~/foto-migration-backups`) immédiatement. Garder au moins 30 jours.

Lorsque tu es sûr :
- Résilier l'ancien VPS OVH (`54.36.100.76`)
- Ou le garder 1 mois comme fallback

---

## Phase 7 — Montées de versions

Une fois l'infra stabilisée, il sera temps de faire évoluer le code.

### 7.1 Pré-requis
- [ ] Vérifier qu'on peut déployer une nouvelle version via Coolify sans casser les données
- [ ] Créer une branche dédiée sur GitHub (`upgrade/rails-8` par ex.)

### 7.2 Ordre de montée
1. **Ruby** : `3.2.2` → `3.3.x` (Voir `.ruby-version` + `Dockerfile`)
2. **Rails** : Dernière version compatible (probablement 8.0.x)
3. **Gems** : `bundle update` + résolution des conflits
4. **Dockerfile** : Mettre à jour l'image de base `ruby:3.3.x-slim`
5. **Tests en local** : `bin/rails test` doit passer
6. **Déploiement** : Push sur GitHub → Coolify déploie automatiquement

> Coolify supporte le déploiement automatique au push (`Auto Deploy` à activer dans les settings du projet).

---

## 📁 Fichiers liés à cette migration

- `scripts/backup-production.sh` — script à exécuter sur l'ancien VPS
- `scripts/restore-production.sh` — script à exécuter sur le nouveau VPS
- `scripts/setup-coolify.sh` — installation rapide de Coolify (optionnel)

---

## 🔐 Checklist sécurité post-migration

- [ ] Le panel Coolify (`coolify.louis.dev`) est protégé par un mot de passe fort
- [ ] Le registre Docker (si utilisé) est sécurisé
- [ ] Les variables d'env secrets sont bien marquées comme telles dans Coolify
- [ ] Les backups automatiques de Coolify sont configurés (ou un cron personnalisé)
- [ ] Le firewall UFW est actif et restreint les ports inutiles
- [ ] Les anciens secrets `.kamal/secrets` ne sont plus utilisés

---

## ❓ FAQ / Debugging

### "La restauration a écrasé les nouvelles images"
→ Le backup était fait AVANT l'upload des nouvelles images. C'est normal. Refaire un backup si besoin.

### "Le container ne démarre pas après restauration"
→ Problème de permissions probable. Vérifier :
```bash
docker run --rm -v foto-storage:/data alpine ls -la /data
# Doit être owned par 1000:1000
```

### "SQLite database is locked"
→ En prod avec Docker, s'assurer qu'un seul process écrit sur la DB à la fois. Solid Queue en mode `in_puma` est OK. Si tu sépares web et worker plus tard, il faudra soit SQLite en mode WAL strict, soit migrer vers PostgreSQL.

### "Les certificats SSL ne se génèrent pas"
→ Vérifier que le DNS pointe bien vers le nouveau VPS **avant** de demander le certificat. Traefik/Let's Encrypt valident via DNS ou HTTP challenge.
