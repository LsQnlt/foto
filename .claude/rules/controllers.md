---
description: Contrôleurs, authentification et réponses
paths:
  - "app/controllers/**/*.rb"
  - "config/routes.rb"
---

# Contrôleurs

- Les pages publiques (albums d'un pseudonyme, like, suivi de vue) déclarent `allow_unauthenticated_access` ; tout le reste exige une session via le concern `Authentication`.
- L'utilisateur courant est `Current.user`, aussi utilisé par Pundit (`pundit_user`). Ne pas réintroduire un `current_user` parallèle.
- Les routes publiques sont préfixées par le pseudonyme : `user_albums_path(pseudonym:)`, `user_album_path(album, pseudonym:)`. Garder cette forme dans les redirections.
- Un contrôleur orchestre : il charge via `before_action`, délègue au modèle, puis rend ou redirige. Pas de traitement d'image ni de logique métier dedans.
- Réponse JSON ponctuelle (like) : `render json:` avec un hash plat et un statut explicite. Pas de couche de « responder » tant qu'il n'y a que deux endpoints JSON.
- Les messages vont dans `config/locales` et se lisent avec `t(".key")` ; pas de texte en dur côté contrôleur.
- Un état de visiteur (albums déverrouillés, photos aimées) vit dans `session`, avec un helper privé par opération comme `unlock_album`.
- `record_page_view` compte une page vue seulement sur une réponse HTML ; conserver ce filtre.
