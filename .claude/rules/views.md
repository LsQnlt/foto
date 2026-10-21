---
description: Vues ERB, jbuilder et helpers
paths:
  - "app/views/**/*.erb"
  - "app/views/**/*.jbuilder"
  - "app/helpers/**/*.rb"
---

# Vues

- L'ERB affiche : partials, helpers, conditions simples, boucles sur des collections préparées par le contrôleur, `t(".key")` et chemins nommés.
- Pas de calcul de chemin, de `case` ou de hash multiligne dans une vue. Si une condition d'affichage dépasse une ligne, la sortir dans un helper nommé d'après ce qu'elle décide (`show_back_arrow?`).
- Le JavaScript se branche par attributs Stimulus (`data-controller`, `data-action`, `data-*-target`), jamais par `onclick` inline. Voir `.claude/rules/stimulus.md`.
- Les données nécessaires au JS passent par `data:` sur l'élément concerné (`photo_id`, `full_url`, `liked`), sans sérialisation JSON manuelle.
- Garder le fragment cache existant sur chaque carte photo (`cache [photo, photo.likes_count]`) ; une clé qui oublie `likes_count` figerait le compteur de likes.
- Une vignette utilise `thumb_variant`, la lightbox `lightbox_variant` ; ne jamais servir l'original dans une page.
- Les textes visibles passent par les locales, y compris les `alt`, `title` et `aria-label`.
- Les réponses JSON de listing restent en jbuilder, un partial par ressource.
