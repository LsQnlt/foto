---
description: Requêtes ActiveRecord et limites de transaction
paths:
  - "app/**/*.rb"
  - "lib/**/*.rb"
  - "spec/**/*.rb"
---

# Rails et persistance

Complète `.claude/rules/ruby.md`. Les conventions de services, contrôleurs, vues et migrations restent dans leurs règles dédiées et `AGENTS.md`.

- Garder le filtrage et les agrégations dans la relation ActiveRecord lorsque le résultat attendu le permet. Utiliser `pluck` pour des colonnes seules et `exists?` pour une existence ; ne pas charger tous les records pour compter ou filtrer en Ruby.
- Avant une boucle qui lit des associations, vérifier les requêtes produites. Choisir `preload`, `includes` ou `eager_load` selon les filtres et le résultat attendu ; ces méthodes ne sont pas interchangeables. Préserver le périmètre de clinique et les autorisations existants.
- Passer les valeurs aux conditions SQL par hash ou paramètres liés. Pour des colonnes ou un tri dynamiques, utiliser une liste de choix autorisés, sans interpoler les paramètres utilisateur.
- Regrouper les écritures qui doivent réussir ensemble dans une transaction. Un effet externe dépendant de leur persistance doit attendre le commit ; un `after_save` peut encore être suivi d'un rollback. Un callback `after_commit` ne rend pas cet effet atomique avec la base : conserver le mécanisme de livraison existant et ses garanties.

Sources : [requêtes ActiveRecord](https://guides.rubyonrails.org/active_record_querying.html) et [callbacks de transaction](https://guides.rubyonrails.org/active_record_callbacks.html#transaction-callbacks). Vérifier les API contre la version de `Gemfile.lock`. Ces précisions viennent de Rails, pas d'un skill Rails dédié dans bsene/skills.
