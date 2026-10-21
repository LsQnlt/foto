---
description: Présentation dans les helpers et decorators, vues ERB simples
paths:
  - "app/views/**/*.erb"
  - "app/helpers/**/*.rb"
  - "app/decorators/**/*.rb"
---

# Vues et présentation

- L'ERB rend le contenu : appels de partials/helpers, conditions simples, boucles de collections préparées, traductions et chemins.
- Ne pas construire de payload complexe, hash multiligne, transformation `map`, `case` de préparation ou dispatch de service dans les vues.
- Choisir le helper pour la présentation pure, le decorator quand elle appartient naturellement à une instance de modèle et le service pour le métier, les requêtes et les effets de bord.
- Les modèles et services exposent des noms Ruby en `snake_case`. Les helpers/decorators convertissent en `camelCase` à la frontière avec les props Vue. Un service ne construit pas le format de props d'un composant.
- Monter les composants depuis ERB via `vue_component`, selon `.claude/rules/vue-islands.md`.

```erb
<%= vue_component("QrCodeSettings", **qr_code_settings_view_props(clinic: @clinic)) %>
```
