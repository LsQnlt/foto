---
description: Conventions Ruby et Rails du projet
paths:
  - "**/*.rb"
---

# Ruby et Rails

- Choisir des noms métier précis, des prédicats lisibles et des symboles/enums nommés plutôt que des noms génériques ou valeurs magiques. Extraire les conditions complexes dans des prédicats. Préférer les sorties anticipées aux imbrications et macros inutiles.
- Les services héritent de `ApplicationService` et exposent `call` ; les appelants utilisent `MonService.call(...)`. Nommer les PORO selon leur cas d'usage, sans leur imposer un héritage de service s'ils n'en sont pas.
- Utiliser le shorthand quand clé et variable ont le même nom : `service.call(clinic:, user:)`.
- Ne pas créer de `attr_reader`, `attr_writer` ou `attr_accessor` privés pour remplacer les accès à `@ivar`. Pour une exception réellement justifiée, l'expliquer et attendre la confirmation de l'utilisateur.
- Préférer quelques lignes inline à une abstraction prématurée, notamment sous trois appelants avec peu de duplication. Si deux usages divergent sur une même règle métier sans distinction établie, signaler cette divergence et obtenir l'arbitrage prévu dans `AGENTS.md` avant de l'entériner.
- Placer les constantes en tête de classe, avant les méthodes, puis `private_constant` immédiatement après les constantes privées.
- Préférer les scopes ActiveRecord au SQL brut. Respecter les rôles existants : services d'orchestration, formulaires YAAF, autorisation Pundit, decorators de présentation et workers Sidekiq.
- Appliquer les conventions de commentaires de `.claude/rules/no-explanatory-comments.md` et celles des générateurs/migrations dans `AGENTS.md`.

## Idiomes et références

- Pour une collection déjà en mémoire, choisir la méthode qui exprime l'opération : `map`, `select`, `find`, `any?`, `sum`, plutôt qu'une boucle avec accumulateur quand elle n'apporte rien. Préserver la sémantique : `filter_map` élimine aussi `false`. Pour une relation ActiveRecord, lire `.claude/rules/rails.md` avant de déplacer le calcul en Ruby.
- Vérifier les syntaxes/API contre `.ruby-version` ; les nouvelles syntaxes ne justifient pas une réécriture du code voisin. Le formatage et les seuils viennent de `.rubocop.yml`, de ses héritages et exclusions, sans importer de budget différent selon l'auteur humain ou agent.

Sources : [skill Ruby de bsene/skills](https://github.com/bsene/skills/blob/81a792df63add57e3b7f1c494eb97cc714909fd2/ruby/SKILL.md) pour la simplicité et la compatibilité des versions ; [Enumerable Ruby 4.0](https://docs.ruby-lang.org/en/4.0/Enumerable.html) pour le comportement des méthodes. L'héritage `ApplicationService`, les attributs privés et le shorthand sont des choix d'équipe.
