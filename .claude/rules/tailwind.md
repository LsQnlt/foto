---
description: Classes Tailwind 4 et tokens de couleur
paths:
  - "app/views/**/*.erb"
  - "app/javascript/**/*.js"
  - "app/assets/tailwind/**/*.css"
  - "app/assets/stylesheets/**/*.css"
---

# Tailwind

- Le projet utilise Tailwind 4 via `tailwindcss-rails`. La configuration est en CSS dans `app/assets/tailwind/application.css` (`@theme`, `@layer`) ; il n'y a pas de `tailwind.config.js` et il ne faut pas en créer.
- La palette de la marque est `main` (`main-lighter`, `main-light`, `main`, `main-dark`, `main-darkened`). Utiliser ces tokens pour tout élément identitaire (titre, cœur de like, accents) plutôt qu'une couleur Tailwind brute.
- Les polices passent par les utilitaires `font-title` et `font-main` déjà définis.
- Écrire des classes complètes : `liked ? "text-main" : "text-main-lighter"`, jamais `text-${color}`. Tailwind ne génère que ce qu'il lit dans les fichiers.
- Rester sur des utilitaires ; pas de CSS personnalisé tant qu'une combinaison de classes suffit. Un nouvel utilitaire va dans `@layer utilities`.
- Le tri des classes est fait par `prettier-plugin-tailwindcss` ; ne pas réordonner à la main.
- Consulter la documentation Tailwind v4, pas la v3.
