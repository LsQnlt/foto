---
description: Contrôleurs Stimulus, Turbo et importmap
paths:
  - "app/javascript/**/*.js"
  - "config/importmap.rb"
---

# Stimulus et Turbo

- Un comportement = un contrôleur Stimulus dans `app/javascript/controllers`, chargé automatiquement par l'importmap. Pas de bundler, pas de framework supplémentaire, pas de dépendance npm sans l'épingler via `bin/importmap pin`.
- Utiliser l'API Stimulus : `static targets`, `static values`, `data-action`. Ne pas chercher des éléments par classe CSS quand une target fait le travail.
- Tout listener posé sur `window` ou `document` dans `connect()` est retiré dans `disconnect()` ; Turbo réutilise la page et reconnecte les contrôleurs.
- Un contrôleur doit supporter plusieurs `connect()` sans dupliquer l'état (préchargements, compteurs, écouteurs).
- Les appels au serveur envoient le jeton CSRF depuis la balise meta et déclarent `Accept: application/json` quand une réponse JSON est attendue.
- Le HTML généré côté JS reste minimal. Si un gabarit dépasse quelques lignes, préférer un `<template>` dans la vue ou un partial servi par Turbo.
- Pas de `console.log` de débogage dans le code livré ; `console.error` seulement dans un `catch`.
- Le frontend est sur Turbo 7.3 (`yarn.lock`), distinct de la gem `turbo-rails` 2.x : ne pas supposer les fonctionnalités de Turbo 8 comme le morphing.
- Le formatage vient de la configuration Prettier et ESLint du dépôt quand elle existe, sinon de celui des contrôleurs existants. Ne pas créer ni modifier cette configuration dans une modification de code.
