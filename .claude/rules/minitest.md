---
description: Tests Minitest, fixtures et tests système
paths:
  - "test/**/*.rb"
  - "test/fixtures/**/*.yml"
---

# Minitest

- Le projet utilise Minitest et les fixtures Rails, pas RSpec ni FactoryBot. Lancer `bin/rails test` ou un fichier ciblé `bin/rails test test/models/photo_test.rb`.
- Tester au bon niveau : modèle pour les règles métier (album protégé, scope `published`), test d'intégration pour le contrat HTTP (accès, redirections, JSON du like), test système Capybara seulement pour un parcours visiteur complet.
- Tester le comportement visible, pas les méthodes privées.
- Un test couvre un comportement cohérent et peut porter plusieurs assertions. Nommer le test d'après la situation : `test "visitor is redirected to password page for protected album"`.
- Les fixtures restent minimales et nommées d'après leur rôle (`albums(:protected)`), pas `:one`/`:two`.
- Utiliser les helpers de routes avec le pseudonyme : `user_album_url(album, pseudonym: user.pseudonym)`. Si un test cible une route absente de `config/routes.rb`, corriger le test, pas la route.
- Les jobs : vérifier la mise en file avec `assert_enqueued_with`, et exécuter avec `perform_enqueued_jobs` seulement si le test porte sur le résultat.
- Pour le temps, utiliser `travel_to` / `freeze_time` et restaurer l'horloge.
- Ne pas confondre un défaut de code avec un défaut d'environnement (driver Selenium, libvips absent) : le dire explicitement dans le compte rendu.
