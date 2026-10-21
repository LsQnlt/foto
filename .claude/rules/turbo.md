---
description: Navigation Turbo et montage des îlots Vue
paths:
  - "app/frontend/entrypoints/**/*.js"
  - "app/frontend/javascript/**/*.{js,ts,vue}"
  - "app/views/**/*.erb"
  - "app/controllers/**/*.rb"
---

# Turbo et îlots Vue

Lire `app/frontend/entrypoints/application.js` et `app/frontend/javascript/lib/islandMount.js` avant de modifier le cycle de navigation. Le helper de montage est décrit dans `.claude/rules/vue-islands.md`.

- Réutiliser `mountIslands` et `unmountIslands`, sans ajouter une application Vue racine autour de l'HTML serveur ni un second système de montage.
- Distinguer les visites de page (`turbo:load`) des chargements de frame (`turbo:frame-load`). Réinitialiser seulement la zone concernée ; le remplacement d'une frame ne doit pas démonter les îlots qui l'entourent.
- Conserver le démontage avant mise en cache/remplacement de page et avant remplacement du contenu d'une frame, avec les conditions existantes. Une visite qui synchronise l'historique sans remplacer la page ne justifie pas de détruire les îlots restants.
- Toute initialisation doit supporter plusieurs passages sans dupliquer widgets, listeners ou montage. Utiliser les hooks de cycle de vie pour nettoyer les ressources, sans temporisation arbitraire ni désactivation globale de Turbo pour masquer un défaut.
- Pour une modification de navigation, fournir un scénario manuel incluant chargement initial, navigation, retour/précédent et mise à jour de frame. La validation navigateur reste à l'utilisateur selon `AGENTS.md`.

Vérifier la version JavaScript dans `yarn.lock`, distincte de la gem dans `Gemfile.lock` : le frontend est sur Turbo 7.3 lors de cette passe. Ne pas supposer disponibles les fonctionnalités de morphing de Turbo 8.

Sources officielles : [cache et initialisations répétées](https://turbo.hotwired.dev/handbook/building) et [événements de navigation](https://turbo.hotwired.dev/reference/events). Le montage des îlots et ses conditions sont propres au dépôt ; bsene/skills ne fournit pas de skill Turbo dédié.
