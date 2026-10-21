# Plan de montée de version — Foto

> Rédigé le 21 octobre 2026, sur la branche `upgrade/versions` (identique à `main` pour l'instant).
> Fait suite au runbook de migration Coolify (`migration-runbook-complet.md`) : l'infra est stable, on passe au code.
> Remplace la « Phase 7 » de `migration-coolify.md`, qui visait Ruby 3.3 / Rails 8.0 (des cibles qui ne sont plus à jour).

---

## 📸 État des lieux

| Composant | Actuel | Dernière dispo | Remarque |
|-----------|--------|----------------|----------|
| Ruby | 3.2.2 | 4.0.7 (3.4.x stable) | **3.2 est EOL depuis mars 2026** |
| Bundler | 2.4.10 | 4.0.x | |
| Rails | 8.0.2 | 8.1.4 | contrainte `~> 8.0.2` dans le Gemfile |
| ActiveAdmin | 4.0.0.beta11 | 4.0.0.beta23 | 12 bétas d'écart, breaking changes possibles |
| activeadmin_assets | 1.0.2 | 1.3.0 | va avec ActiveAdmin |
| puma | 6.6.0 | 8.0.2 | **2 versions majeures** |
| solid_queue | 1.1.5 | 1.7.0 | regarder les migrations de schéma (DB `queue`) |
| solid_cable | 3.0.8 | 4.1.0 | **majeure** (DB `cable`) |
| image_processing | 1.14.0 | 2.2.0 | **majeure**, contrainte `~> 1.2` |
| active_storage_validations | 3.0.0 | 4.1.1 | **majeure** |
| tailwindcss-rails | 4.2.3 | 4.6.0 | |
| kamal | 2.6.1 | — | **plus utilisé** depuis Coolify → à supprimer |

### ⚠️ Points relevés pendant l'analyse

1. ~~**Les tests sont tous en erreur** (16/16)~~ → ✅ corrigé (jalon 0.2) : 58 tests, 144 assertions, tous verts.
   Il y avait deux fixtures avec le même `token`, et les tests de scaffold visaient des routes qui n'existent pas.
2. **Incohérence dans le traitement d'images** : `config/application.rb` force `variant_processor = :mini_magick`, alors que `OptimizePhotoJob` utilise déjà Vips (commit `faca7e2`). Le Dockerfile installe les deux (`libvips` + `imagemagick`).
3. **Secret exposé** : le mot de passe SMTP Brevo était en clair dans `docs/migration-coolify.md` (commit `65380b3`, poussé sur `origin/main`). → Les secrets sont retirés des docs. La clé est **déjà désactivée côté Brevo**, donc pas besoin de réécrire l'historique. Il faut créer une nouvelle clé (voir 0.1).
4. **Déploiement** : Coolify est désormais branché sur GitHub, et **chaque push sur `main` déclenche un déploiement**. Docker Hub n'est plus utilisé. Conséquences :
   - le merge sur `main` *est* la mise en prod : on ne merge qu'une fois la CI verte, car Coolify n'attend pas la CI ;
   - rollback : passer par l'onglet *Rollback* de Coolify, qui garde les images des déploiements précédents (à vérifier une fois avant d'en avoir besoin), ou faire un `git revert` puis un push ;
   - le build se fait sur le VPS, dont la RAM a été augmentée depuis le gel décrit dans le runbook : ✅ OK pour builder.
7. **CI `scan_ruby` toujours rouge** : `bin/brakeman` tourne avec `--ensure-latest` et échoue tant que Brakeman n'est pas à jour (7.0.2 contre 8.1.0). Ce sera réglé en B.1. Le seul vrai avertissement est Ruby 3.2 en fin de vie, réglé en C.1.
5. Les migrations tournent automatiquement au démarrage (`bin/docker-entrypoint` → `db:prepare`) sur les **4 bases SQLite de prod**. Toute migration ajoutée par une gem (solid_queue, solid_cable, active_storage…) s'exécutera en prod dès le déploiement.
6. Restes à nettoyer : `package.json` (ESLint/Vue/Vite/husky, alors que l'app tourne avec importmap), `node_modules/`, `.kamal/`, `config/deploy.yml`, `bin/kamal`, `bin/deploy`.

---

## 🧭 Principes

- **Une étape = un sujet = un commit** (que tu relis et commits toi-même). Pas de `bundle update` global en un seul coup.
- Après chaque étape : `bin/rails test`, `bin/rubocop`, `bin/brakeman`, puis le **smoke test manuel** (voir plus bas).
- **Backup du volume `foto-storage` avant chaque déploiement en prod** (méthode du runbook : pipe SSH, pas `/tmp`).
- Déploiement en prod seulement à la fin des jalons A, B, C et D, pas à chaque étape.

---

## 🗺️ Les étapes

### Jalon 0 — Sécuriser le terrain (avant de toucher aux versions)

| # | Étape | Fichiers |
|---|-------|----------|
| 0.1 | ✅ Secrets retirés des docs. **Reste à faire (toi)** : créer une nouvelle clé SMTP Brevo et la mettre dans Coolify (`SMTP_USERNAME` / `SMTP_PASSWORD`). D'ici là, **les invitations ne partent pas en prod**. | `docs/migration-*.md` |
| 0.2 | ✅ Fixtures réécrites (admin/alice/bob, albums publics/brouillon/protégé, invitations valide/utilisée/expirée, photos avec vraies images). | `test/fixtures/**` |
| 0.3 | ✅ Tests des parcours critiques : modèles, albums publics et protégés, likes, connexion, inscription par invitation, mail d'invitation, policies Pundit, admin (pages, droits, création d'album avec photos), `OptimizePhotoJob`. | `test/**` |
| 0.4 | ✅ CI : ajout de `libvips` + `imagemagick`, nécessaires aux tests du job. En local : `sudo dnf install vips`, sinon ces 2 tests sont ignorés. | `.github/workflows/ci.yml` |

> 🎯 **Fin du jalon 0** : tests verts en local et en CI.

### 🐛 Bugs révélés par les tests (à trancher, pas corrigés)

| Bug | Impact | Remarque |
|-----|--------|----------|
| ✅ `Photo#lightbox_variant` demandait la taille `:lightbox_variant`, absente de `PHOTO_SIZES` → `resize_to_limit: nil` | La lightbox était l'original (≤ 2048 px) réencodé, au lieu d'une version 1800×1350. | **Corrigé** (`:lightbox`). Regénération en prod : voir ci-dessous. |
| ✅ `User` déclarait `rolify` puis redéclarait `has_and_belongs_to_many :roles` | Warning `already initialized constant User::HABTM_Roles` dans les tests. | **Corrigé** : `rolify before_add: :ensure_only_one_role`. La règle « un seul rôle » est couverte par un test. |
| ✅ `delete_photo` (admin albums) ne vérifiait pas le propriétaire de la photo | N'importe quel utilisateur connecté pouvait supprimer la photo d'un autre. | **Corrigé** : la photo est cherchée dans l'album via `resource`, qui est déjà limité par `policy_scope`, puis `authorize photo, :destroy?`. |
| ✅ `user_id` (albums) et `album_id` (photos) acceptés sans vérification du rôle | Un utilisateur non admin pouvait réattribuer un album ou poster dans l'album d'un autre. | **Corrigé** : les attributs autorisés viennent de `policy(...).permitted_attributes`, et `authorize` est appelé avant chaque sauvegarde (`before_save`, plus le `create` personnalisé des albums). |
| ✅ `AlbumsController#show` faisait `Album.find(params[:id])` sans vérifier `published` ni le propriétaire | Un brouillon répondait en 200 sur `/<n'importe quel pseudo>/albums/<id>`. | **Corrigé** : l'album est cherché parmi ceux du pseudo de l'URL, et un brouillon renvoie une 404 sauf pour son propriétaire ou un admin connecté (`AlbumPolicy#show?`). |

### 🖼️ Regénérer les lightbox en prod (après le déploiement de la correction)

```bash
# Nom du conteneur : sudo docker ps --filter volume=foto-storage
ssh coolify
sudo docker exec -it <CONTENEUR_FOTO> bin/rails photos:generate_variants              # crée les variantes manquantes, idempotent
sudo docker exec -it <CONTENEUR_FOTO> bin/rails photos:purge_obsolete_lightboxes      # DRY-RUN : compte les anciennes lightbox et l'espace occupé
sudo docker exec -it <CONTENEUR_FOTO> bin/rails photos:purge_obsolete_lightboxes CONFIRM=1   # supprime les anciennes lightbox
```

### 🧹 Nettoyer le disque (fichiers inutilisés)

Toutes ces tâches sont en DRY-RUN par défaut et ne suppriment qu'avec `CONFIRM=1`. **Faire un backup du volume avant**, puis les lancer dans cet ordre :

```bash
sudo docker exec -it <CONTENEUR_FOTO> bin/rails photos:purge_obsolete_lightboxes   # anciennes lightbox non redimensionnées
sudo docker exec -it <CONTENEUR_FOTO> bin/rails photos:purge_unattached_blobs      # blobs en base rattachés à aucune photo (de plus d'un jour)
sudo docker exec -it <CONTENEUR_FOTO> bin/rails photos:purge_orphan_files          # fichiers sur le disque sans blob en base
# Puis relancer chacune avec CONFIRM=1 si le DRY-RUN est cohérent
```

> `purge_orphan_files` n'examine que les fichiers rangés au format Active Storage (`ab/cd/abcd…`) : les bases SQLite à la racine de `/rails/storage` ne sont jamais touchées.

> ⚠️ Ne **pas** lancer `photos:process_all` : cette tâche relance `OptimizePhotoJob`, qui réencode les originaux une fois de plus (perte de qualité) et invalide toutes les variantes.

### Jalon A — Nettoyage (pas de risque fonctionnel)

| # | Étape |
|---|-------|
| A.1 | Retirer Kamal : gem `kamal`, `config/deploy.yml`, `.kamal/`, `bin/kamal`, `bin/deploy`. Mettre à jour les commentaires du Dockerfile et la section Rollback de `migration-coolify-inplace.md`, qui renvoie vers `bin/kamal deploy`. |
| A.2 | Choisir **un seul** processeur d'images. Je recommande **Vips** : c'est le défaut Rails, il est déjà utilisé dans le job, plus rapide et moins gourmand en RAM (utile sur un VPS de 2 Go). Concrètement : supprimer la ligne `variant_processor`, la gem `mini_magick` et `imagemagick` du Dockerfile. Les variantes existantes restent valides. |
| A.3 | Faire le tri dans `package.json`/`yarn.lock` : ne garder que ce qui sert réellement, ou tout supprimer si rien n'est utilisé. |

### Jalon B — Gems sans changement majeur (Ruby 3.2, Rails 8.0)

| # | Étape |
|---|-------|
| B.1 | `bundle update --conservative` sur les gems de dev/test (rubocop & co). Corriger les nouvelles alertes ou les ajouter à `.rubocop_todo.yml`. |
| B.2 | Rails `8.0.2` → dernier patch `8.0.x` (correctifs de sécurité). |
| B.3 | Mises à jour mineures : turbo-rails, importmap-rails, propshaft, sqlite3, bootsnap, solid_cache, thruster, tailwindcss-rails, pundit, jbuilder. |
| B.4 | solid_queue `1.1` → `1.7` : **lire le CHANGELOG** pour repérer les migrations à ajouter dans `db/queue_schema.rb`. |

> 🚀 **Déploiement n°1**, avec backup avant.

### Jalon C — Ruby

| # | Étape |
|---|-------|
| C.1 | Ruby `3.2.2` → **`3.4.x`** dans `.ruby-version`, `mise.toml` et `Dockerfile` (`ARG RUBY_VERSION`). Bundler → dernière 2.x (`bundle update --bundler`). |
| C.2 | Corriger les warnings Ruby 3.4 (gems sorties de la stdlib comme `csv`, `base64` ou `bigdecimal`, frozen string literals…). |

> 🚀 **Déploiement n°2.**

#### C.3 — Ruby 4.0 (après le jalon D) : critères de validation

On ne passe en Ruby 4 que si **toutes** ces conditions sont remplies. Ce sont des critères vérifiables, pas « ça a l'air de marcher » :

1. **Prérequis** : la prod tourne depuis au moins une semaine sans erreur avec Ruby 3.4 et Rails 8.1 (jalons C et D terminés). En cas de souci, on saura alors que Ruby 4 est en cause.
2. **Dépendances** : `bundle install` passe sans conflit de `required_ruby_version`, et les gems natives (`sqlite3`, `bcrypt`, `nokogiri`, `ffi`…) ont un **binaire précompilé pour Ruby 4.0**. Sinon elles sont compilées pendant le build Coolify, ce qui est lent et gourmand en RAM sur le VPS.
3. **Tests** : `bin/rails test` vert, **0 skip inattendu**, avec libvips installé.
4. **Warnings** : `RUBYOPT="-W:deprecated" bin/rails test` n'affiche **aucun warning venant de `app/`, `lib/` ou `config/`**. Ceux des gems sont listés et acceptés un par un.
5. **CI** verte (tests, rubocop, brakeman).
6. **Build Docker** réussi en local (`docker build .`) avant de pousser sur `main`.
7. **Smoke test** complet en local avec l'image buildée (`docker run` sur une copie du volume de prod).
8. **Après le déploiement** : smoke test en prod, `PRAGMA integrity_check` OK, et RAM/CPU dans Coolify comparables à la semaine précédente, à surveiller pendant 48 h.
9. **Rollback prêt** : backup du volume pris juste avant, et procédure de rollback Coolify testée.

### Jalon D — Rails 8.1 + majeures

| # | Étape |
|---|-------|
| D.1 | Rails `~> 8.1` + `rails-i18n ~> 8.1`. Lancer `bin/rails app:update` et relire chaque diff (je te les présenterai un par un). Garder `load_defaults 8.0`, puis activer les nouveaux défauts un par un via `config/initializers/new_framework_defaults_8_1.rb`, et passer à `load_defaults 8.1` une fois que tout passe. |
| D.2 | **ActiveAdmin beta11 → beta23** + activeadmin_assets 1.3 : lire `UPGRADING.md` et le CHANGELOG, regénérer les vues/assets si nécessaire, tester chaque écran admin (albums, photos, users, dashboard) avec les autorisations. |
| D.3 | puma 6 → 8 : vérifier `config/puma.rb` (plugin `solid_queue`, `SOLID_QUEUE_IN_PUMA`). |
| D.4 | solid_cable 3 → 4 : schéma de la DB `cable`. |
| D.5 | image_processing 1 → 2 (passer la contrainte à `~> 2.0`) et active_storage_validations 3 → 4 : relire le modèle `Photo` et `OptimizePhotoJob`. |

> 🚀 **Déploiement n°3**, avec backup avant et vérification `PRAGMA integrity_check` après (commande dans le runbook).

---

## ✅ Smoke test manuel (après chaque jalon)

- [ ] Page d'accueil et liste des albums
- [ ] Album protégé : accès refusé sans droits, accepté avec
- [ ] Upload d'une photo → conversion en webp + vignette générée (logs Solid Queue)
- [ ] Lightbox
- [ ] Envoi d'une invitation par mail (`letter_opener_web` en local)
- [ ] Admin : dashboard, CRUD albums/photos/users
- [ ] En prod : `https://foto.rip` en 200, anciennes photos visibles, intégrité SQLite OK

---

## 🆘 Rollback

1. Coolify → l'application → *Rollback* : redéployer l'image précédente. Ou faire `git revert` du merge puis pousser sur `main`.
2. Si une migration a cassé une base, restaurer `foto-storage` depuis le backup pris juste avant (procédure du runbook).
