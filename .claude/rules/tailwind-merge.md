---
description: Classes Tailwind, tokens et résolution des conflits
paths:
  - "app/frontend/**/*.{vue,js,ts}"
  - "app/frontend/**/*.{css,scss,sass}"
  - "app/views/**/*.erb"
  - "app/helpers/**/*.rb"
  - "tailwind.config.js"
---

# Classes Tailwind

Fusionner les classes de base et leurs overrides avec `mergeTailwindClasses` de `@lib/utils`. L'utilitaire résout les conflits et connaît les palettes du projet ; une concaténation ou une déduplication par `Set` ne le remplace pas.

Si nécessaire, étendre l'utilitaire et sa configuration en gardant une logique simple. Si le besoin le complexifie fortement, exposer le problème avant de construire une solution générale disproportionnée.

```javascript
import { mergeTailwindClasses } from '@lib/utils';

const classes = mergeTailwindClasses(base, overrides);
```

## Génération et design system

- Suivre `tailwind.config.js` et les tokens de `app/frontend/design-system/tokens.js` pour les couleurs, tailles et variantes existantes. Laisser le plugin Prettier configuré trier les classes.
- Écrire les variantes comme des classes complètes dans les fichiers scannés : `error ? 'text-danger-600' : 'text-success-600'`, sans construire `text-${color}-600`. Vérifier `content` lorsqu'un nouveau type ou emplacement de fichier contient des classes ; il ne couvre pas automatiquement tous les chemins.
- Le projet utilise Tailwind 3 : consulter sa documentation v3. Ne pas introduire une configuration Tailwind 4 (`@theme`, `@source`) dans une modification de style.

Source officielle : [détection des classes Tailwind 3](https://v3.tailwindcss.com/docs/content-configuration). Les tokens et `mergeTailwindClasses` sont propres au dépôt ; bsene/skills ne fournit pas de skill Tailwind dédié.
