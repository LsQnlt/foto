---
description: Composants Vue et organisation du frontend
paths:
  - "app/frontend/javascript/**/*.{vue,js,ts}"
---

# Vue

- Préférer la Composition API. Composants en PascalCase, composables préfixés par `use`, stores et services dans leurs emplacements/alias existants.
- Utiliser `shared/inputs/FormInput.vue` pour les formulaires : options sous forme `{ value, label }` ou groupes `{ group, items }`. Les contrôles natifs restent réservés à l'implémentation des primitives, aux champs cachés et aux besoins vraiment spécifiques.
- Étendre `FormInput` pour les besoins non couverts plutôt que multiplier les contrôles parallèles. Justifier une exception spécifique.
- Ranger les composants par fonctionnalité : formulaires de réglage dans `settings`, concepts métier dans leur dossier et primitives UI dans `shared/<kind>`.
- Ne pas extraire un wrapper trivial utilisé une seule fois. Extraire s'il a plusieurs consommateurs, un état non trivial ou une logique de rendu dont l'extraction clarifie réellement le parent.
- Enregistrer globalement seulement les composants montés directement depuis ERB. Les sous-composants sont importés localement.
- Suivre `.claude/rules/tailwind-merge.md` pour la fusion des classes.

## Réactivité et cycle de vie

- Utiliser `computed` pour une valeur dérivée ; garder son getter sans mutation, requête réseau ou écriture DOM. Réserver les watchers aux effets déclenchés par un changement, sans maintenir une copie d'état qui peut être calculée.
- Déclarer les props et les événements du composant. Faire remonter les modifications par événement ou contrat `v-model`, sans modifier implicitement les objets reçus du parent. Pour observer une prop, fournir une source réactive, par exemple `watch(() => props.clinicId, ...)`, pas sa valeur instantanée.
- Donner aux éléments des listes modifiables une `key` stable issue de leur identité, sans index dépendant du tri. Éviter les mutations du tableau source dans un getter de tri.
- Nettoyer au démontage les listeners, timers et observers créés par le composant/composable. Pour les îlots et changements de page/frame, lire `.claude/rules/turbo.md`.

Le formatage reste défini par `.eslintrc.json` et `.prettierrc.json` ; ne pas recopier celui des exemples documentaires.

Sources officielles : [computed](https://vuejs.org/guide/essentials/computed.html#best-practices), [props](https://vuejs.org/guide/components/props.html), [listes](https://vuejs.org/guide/essentials/list.html#maintaining-state-with-key) et [démontage](https://vuejs.org/api/composition-api-lifecycle.html#onunmounted). Ces règles complètent les choix d'équipe ; bsene/skills ne fournit pas de skill Vue dédié.
