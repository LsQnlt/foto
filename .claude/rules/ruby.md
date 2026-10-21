---
description: Conventions Ruby du projet
paths:
  - "**/*.rb"
---

# Ruby

- Choisir des noms métier précis (`album_unlocked?`, `cover_photo`) et des prédicats lisibles. Extraire une condition complexe dans un prédicat plutôt que de la commenter.
- Préférer les sorties anticipées (`return unless photo`) aux imbrications.
- Respecter l'ordre imposé par `Layout/ClassStructure` : `include`/`extend`, constantes, méthodes de classe, méthodes publiques, puis `private`.
- Pas de préfixe `is_` sur les prédicats ; utiliser `?`.
- Utiliser le shorthand de hash quand clé et variable portent le même nom : `photo_variant(self, :thumb, method:)`.
- Pas de `attr_reader` privé pour remplacer un accès à `@ivar`.
- Préférer `public_send` à `send` pour un nom de méthode dynamique.
- Pour une collection en mémoire, choisir la méthode qui dit l'intention : `map`, `select`, `find`, `any?`, `sum`. Pour une relation ActiveRecord, lire `.claude/rules/rails.md` avant de rapatrier le calcul en Ruby.
- Pas de couche de services tant qu'un modèle, un concern ou un job suffit. Si une classe PORO devient nécessaire, la nommer d'après son cas d'usage et exposer une seule méthode publique.
- Le style vient de `.rubocop.yml` (base `rubocop-shopify`) et de `.ruby-version` (3.4.11). Lancer `bundle exec rubocop` sur les fichiers modifiés ; ne pas rouvrir `.rubocop_todo.yml` pour un fichier non touché.
- Appliquer `.claude/rules/no-explanatory-comments.md`.
