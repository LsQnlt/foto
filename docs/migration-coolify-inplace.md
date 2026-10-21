# Migration Foto → Coolify (in-place, sur le VPS actuel)

> **Statut** : ✅ Chemin recommandé — on garde le VPS actuel (`54.36.100.76`) au lieu d'en souscrire un nouveau.
> **Objectif** : remplacer Kamal 2 par Coolify sur la même machine, **sans perte de données** (le volume `foto_storage` reste en place).
>
> 📄 L'ancien plan « nouveau VPS » reste dispo ici : [`migration-coolify.md`](./migration-coolify.md).

---

## 🤔 Pourquoi in-place

- Plus de galère de stock VPS OVH (Espagne/Canada) → on utilise la machine déjà en prod.
- **Aucun transfert de données** : le volume Docker `foto_storage` survit au kill de Kamal.
- **Aucun changement DNS** : `foto.rip` pointe déjà sur cette IP.

En contrepartie, on travaille **à chaud** sur la seule machine de prod : le **backup devient non négociable**, et il y aura un **downtime** de `foto.rip` (compter 1 à 2 h).

---

## 📋 Prérequis

- [ ] Accès SSH sudo sur le VPS (`54.36.100.76`)
- [ ] `RAILS_MASTER_KEY` et `SMTP_*` disponibles (`.kamal/secrets` en local)
- [ ] Repo GitHub accessible
- [ ] **RAM libre ≥ 2 Go et disque libre ≥ 10 Go** (Coolify s'ajoute à `foto`) — vérifié en Phase 0

---

## 🗺️ Vue d'ensemble des phases

| # | Phase | Script / commande |
|---|-------|-------------------|
| 0 | Backup + relever les specs | `scripts/backup-production.sh` + `verify-migration.sh preflight` |
| 1 | Arrêter Kamal (sans toucher aux données) | `scripts/kill-kamal.sh` |
| 2 | Vérifier que tout est propre | `verify-migration.sh post-kill` |
| 3 | Installer Coolify | `scripts/setup-coolify.sh` |
| 4 | Vérifier Coolify | `verify-migration.sh coolify` |
| 5 | Déployer `foto` en rattachant le volume existant | UI Coolify |
| 6 | Vérifier le site | `verify-migration.sh app` |
| 7 | Vérifier l'intégrité des données | `verify-migration.sh data` |
| 8 | Ajouter `lsqnlt.dev` / `coolify.lsqnlt.dev` (et SSL) | UI Coolify |

> Les deux scripts `kill-kamal.sh` et `verify-migration.sh` sont à copier sur le VPS d'abord :
> ```bash
> scp scripts/kill-kamal.sh scripts/verify-migration.sh ubuntu@54.36.100.76:/tmp/
> ```

---

## Phase 0 — Backup + état des lieux

### 0.1 Backup (obligatoire)

```bash
# En local
scp scripts/backup-production.sh ubuntu@54.36.100.76:/tmp/
ssh ubuntu@54.36.100.76 "chmod +x /tmp/backup-production.sh && sudo /tmp/backup-production.sh"
```

Puis récupérer l'archive **en local** (pas seulement dans `/tmp` du serveur) :

```bash
mkdir -p ~/foto-migration-backups
rsync -avz --progress ubuntu@54.36.100.76:/tmp/foto-backup-* ~/foto-migration-backups/
```

### 0.2 Preflight (le gate de dimensionnement)

```bash
ssh ubuntu@54.36.100.76 "sudo /tmp/verify-migration.sh preflight"
```

Regarder en particulier le bloc **Dimensionnement** :
- Si **FAIL** sur la RAM ou le disque → la machine est peut-être trop juste pour accueillir Coolify en plus de `foto`. À ce moment-là, repasser sur le plan « nouveau VPS » (`migration-coolify.md`).
- Si tout est **PASS** (surtout RAM ≥ 2 Go, disque ≥ 10 Go, backup présent) → go.

> ℹ️ Le preflight crée une **baseline** dans `/tmp/foto-migration-baseline` (taille du volume + nombre de fichiers). Les étapes suivantes s'y comparent pour prouver que rien n'a été perdu.

---

## Phase 1 — Arrêter Kamal

> 🔴 **Point clé** : il faut supprimer **le proxy `kamal-proxy` en plus des conteneurs `foto`**, sinon Coolify (Traefik) ne pourra pas prendre les ports 80/443.

```bash
ssh ubuntu@54.36.100.76
sudo /tmp/kill-kamal.sh            # d'abord en DRY-RUN : montre ce qui serait supprimé
sudo /tmp/kill-kamal.sh --yes      # puis exécute réellement
```

Ce que fait le script :
1. Liste les conteneurs `foto` + `kamal-proxy`
2. Les supprime (`docker rm -f`) — **jamais** le volume
3. Ré-affiche l'état du volume `foto_storage` (doit être intact)
4. Vérifie que 80/443/8000 sont libres

---

## Phase 2 — Vérifier le post-kill

```bash
sudo /tmp/verify-migration.sh post-kill
```

Doit afficher **0 FAIL** :
- plus de conteneur `foto` ni `kamal-proxy`
- ports 80/443/8000 libres
- volume intact, taille/nb de fichiers identiques à la baseline

> ❌ Si un port reste occupé : `docker ps` pour trouver le conteneur fautif, le supprimer, re-lancer la vérif.

---

## Phase 3 — Installer Coolify

```bash
sudo /tmp/setup-coolify.sh
```

Ou, à la main :

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

L'installation affiche l'URL du panel (`http://<IP>:8000`) et le mot de passe root temporaire.

> ℹ️ Le `rm -rf /data/coolify` du script `setup-coolify.sh` est inoffensif : c'est le répertoire de Coolify, **sans rapport** avec `/rails/storage` ni le volume `foto_storage`.

---

## Phase 4 — Vérifier Coolify

```bash
sudo /tmp/verify-migration.sh coolify
```

Attendu : conteneurs Coolify/Traefik qui tournent, ports 8000/443/80 en écoute, panel qui répond.

Puis, dans l'UI :
1. Ouvrir `http://<IP>:8000`, se connecter (`root@localhost` + mdp affiché)
2. Changer le mot de passe root
3. (Optionnel) configurer le domaine du panel : `coolify.lsqnlt.dev`

> ℹ️ Le TLD `.dev` est sur la **HSTS preload list** : les navigateurs refusent tout accès HTTP. Coolify gère automatiquement le SSL (Let's Encrypt) via Traefik — c'est transparent.

---

## Phase 5 — Déployer `foto` avec le volume EXISTANT

Dans Coolify : **Projects → Create Project (`foto`)** → **Add Resource → Application → Public Repository** (`github.com/LsQnlt/foto`, branche `main`, build pack **Dockerfile**).

**Environment Variables** (les mêmes que le plan initial) :

| Clé | Valeur | Secret ? |
|-----|--------|----------|
| `RAILS_MASTER_KEY` | (celle de `.kamal/secrets`) | ✅ |
| `SMTP_USERNAME` | (depuis Brevo) | ✅ |
| `SMTP_PASSWORD` | (celle de `.kamal/secrets`) | ✅ |
| `RAILS_ENV` | `production` | ❌ |
| `SOLID_QUEUE_IN_PUMA` | `true` | ❌ |
| `RAILS_LOG_LEVEL` | `info` | ❌ |

**Storage (le point critique)** :

🔴 **Ne PAS créer un volume neuf.** À la place, rattacher le volume Docker **déjà existant** :
- Destination : `/rails/storage`
- Source : le volume nommé **`foto-storage`** tel qu'il apparaît dans `docker volume ls`

> Différence clé avec le plan « nouveau VPS » : le volume n'est pas vide, il contient déjà la DB SQLite et toutes les photos. Le premier `db:prepare`/migrations tourne sur des données existantes (idempotent et sûr).

**Domaines & SSL** :
- Ajouter `foto.rip` (le domaine final) + SSL Let's Encrypt activé
- (Optionnel, temporaire) `foto.lsqnlt.dev`

> ⚠️ Tous les domaines en `.dev` **doivent** avoir HTTPS actif. Coolify/Traefik demande et renouvelle les certificats Let's Encrypt automatiquement.

**Deploy.**

---

## Phase 6 — Vérifier le site

```bash
sudo /tmp/verify-migration.sh app
```

Attendu :
- un conteneur monte bien `foto_storage`
- `https://foto.rip` répond HTTP 200
- certificat SSL valide

---

## Phase 7 — Vérifier l'intégrité des données

```bash
sudo /tmp/verify-migration.sh data
```

Attendu :
- nombre de fichiers ≥ baseline (preflight)
- en-têtes SQLite valides sur tous les `.sqlite3`

Pour une vérification **profonde** (integridad réelle des bases), depuis le conteneur :

```bash
# Récupérer le nom du conteneur avec : docker ps --filter volume=foto_storage
docker exec -it <CONTENEUR_FOTO> bin/rails runner \
  'puts ActiveRecord::Base.connection.execute("PRAGMA integrity_check").to_a.inspect'
```

> ✅ `ok` est le résultat attendu.

---

## Phase 8 — Domaines supplémentaires

Une fois `foto.rip` validé :
- Ajouter `coolify.lsqnlt.dev` (domaine du panel) + SSL
- Ajouter `lsqnlt.dev` (→ future app blog) + `*.lsqnlt.dev` en wildcard si besoin
- Enregistrements DNS à créer chez le registrar (A → `54.36.100.76`) :
  ```
  A  coolify.lsqnlt.dev  →  54.36.100.76
  A  lsqnlt.dev          →  54.36.100.76
  A  *.lsqnlt.dev        →  54.36.100.76
  ```
  (`foto.rip` existe déjà, ne pas y toucher.)

> 🔒 Rappel `.dev` : le navigateur bloquera tout accès non-HTTPS. Heureusement Coolify gère le SSL (Let's Encrypt) automatiquement dès que le domaine est ajouté.

---

## 🔐 Checklist sécurité post-migration

- [ ] **Compte admin Coolify créé immédiatement** (premier arrivé = root, sécurise vite)
- [ ] **Backup de `/data/coolify/source/.env` en local** :
  ```bash
  scp coolify:/data/coolify/source/.env ~/foto-migration-backups/coolify-env-backup
  ```
- [ ] Mot de passe admin Coolify fort
- [ ] SSL actif sur `coolify.lsqnlt.dev`, `foto.rip`, `lsqnlt.dev`
- [ ] Variables d'env secrètes cochées "Secret" dans Coolify
- [ ] Backups locaux conservés ≥ 30 jours (`~/foto-migration-backups`)
- [ ] Firewall UFW actif (SSH + 80/443 + 8000)
- [ ] Anciens secrets Kamal (`.kamal/secrets`) désactivés / plus utilisés

---

## 🆘 Rollback (si quelque chose casse)

> ℹ️ La config Kamal (`config/deploy.yml`, `.kamal/`, `bin/kamal`) a été retirée du repo après la migration. Elle reste consultable dans l'historique git (commit `ea4fc15`).

1. Backup/restauration des données via l'archive locale `~/foto-migration-backups`
2. Re-déployer `foto` manuellement (`docker run`) avec le volume `foto_storage`, ou réinstaller Coolify et recréer la ressource (voir `migration-runbook-complet.md`)

> Le volume `foto_storage` étant intact, le retour arrière se limite à re-lancer les conteneurs, pas à re-importer des données.

---

## 📁 Fichiers liés

- `scripts/kill-kamal.sh` — arrêt propre de Kamal (DRY-RUN par défaut, préserve le volume)
- `scripts/verify-migration.sh` — vérifications par phase (preflight/post-kill/coolify/app/data)
- `scripts/backup-production.sh` — backup avant migration
- `scripts/restore-production.sh` — restauration (utilisé ici seulement en rollback)
- `scripts/setup-coolify.sh` — installation rapide de Coolify