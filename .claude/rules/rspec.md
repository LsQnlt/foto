---
description: RSpec, contrats publics et doubles
paths:
  - "spec/**/*.rb"
---

# RSpec

- Tester le comportement via l'API publique et couvrir les cas utiles. Les tests directs de méthodes privées doivent rester exceptionnels et être justifiés à l'utilisateur.
- Ne pas utiliser `allow_any_instance_of`. Stubber une instance précise ou utiliser `instance_double` avec la construction contrôlée de cette instance.
- Préférer `allow(...).to receive(...)` avant l'action puis `have_received(...)` après l'action aux attentes d'appel placées avant l'exécution.
- Préférer l'appel direct, puis `public_send` pour un nom dynamique. Ne pas utiliser `Object#send` ; réserver `__send__` aux rares accès privés réellement nécessaires.
- Écrire ou adapter les specs des changements ; lancer les vérifications ciblées selon `AGENTS.md`. Ne pas confondre un défaut de code avec un échec de l'environnement de test.

## Structure et données

- Tester au niveau pertinent : modèle/service pour le métier, request pour le contrat HTTP, worker pour son exécution. Séparer la mise en file de l'exécution ; les workers du dépôt utilisent Sidekiq et ses helpers de test.
- Un exemple vérifie un comportement cohérent, avec plusieurs attentes si nécessaire. Les `context` décrivent les variations utiles ; ne pas découper artificiellement pour imposer une seule attente.
- Garder les factories minimales et utiliser les traits. Préférer `build` ou `build_stubbed` si la persistance n'est pas nécessaire ; utiliser `create` pour les requêtes et comportements réellement persistés. Réserver `let!` aux données qui doivent exister avant l'action.
- Préférer les doubles vérifiés pour les collaborateurs remplacés et isoler les services externes. Ne pas stubber la logique que l'exemple prétend vérifier. Conserver WebMock et la vérification des doubles existants.
- Stabiliser les scénarios temporels avec les helpers déjà disponibles (`travel_to`, `freeze_time`) et restaurer l'horloge après l'exemple.

Source : [tests Ruby/Rails de bsene/skills](https://github.com/bsene/skills/blob/81a792df63add57e3b7f1c494eb97cc714909fd2/ruby/testing.md), adaptés à nos spies et à Sidekiq. Ici `spec/spec_helper.rb` charge déjà Rails : remplacer `rails_helper` par `spec_helper` n'isole pas une spec du framework. Cette règle n'ajoute ni outil de test ni autorisation de validation navigateur.
