---
description: Modèles, requêtes ActiveRecord, ActiveStorage et jobs
paths:
  - "app/models/**/*.rb"
  - "app/jobs/**/*.rb"
  - "app/policies/**/*.rb"
  - "lib/**/*.rb"
---

# Rails et persistance

Complète `.claude/rules/ruby.md`.

## Requêtes

- Garder filtrage, tri et comptage dans la relation ActiveRecord. `pluck` pour une colonne, `exists?` pour une existence ; ne pas charger tous les records pour compter en Ruby.
- Préférer un scope nommé (`Album.published`) à une condition répétée dans les contrôleurs.
- Avant une boucle qui touche une association ou une pièce jointe, précharger : `includes(image_attachment: :blob)` pour les photos, `includes(cover_photo: { image_attachment: :blob })` pour les couvertures d'albums. Une grille de photos sans préchargement produit une requête par vignette.
- Passer les valeurs aux conditions SQL par hash ou paramètres liés ; jamais d'interpolation de paramètre utilisateur.

## Écritures et transactions

- Regrouper dans une transaction les écritures qui doivent réussir ensemble.
- Un effet externe (job, mail) qui dépend de la persistance part en `after_commit`, comme `generate_variants_async` sur `Photo`.
- Un job reçoit un id, pas un record. Il recharge avec `find_by` et sort proprement si le record a disparu (photo supprimée entre la mise en file et l'exécution).
- Les jobs tournent sur Solid Queue ; les rendre rejouables sans effet de bord supplémentaire.

## ActiveStorage et images

- Les tailles de variantes vivent dans `PhotoVariants::PHOTO_SIZES` ; ne pas dupliquer de dimensions ailleurs.
- Le traitement lourd (conversion WebP, génération des variantes) reste dans `OptimizePhotoJob`, jamais dans une requête web.
- Conserver les validations de type et le `spoofing_protection` sur les pièces jointes.

## Administration et autorisation

- Tout modèle exposé dans ActiveAdmin définit `ransackable_attributes` et, si besoin, `ransackable_associations`.
- L'autorisation passe par Pundit : une `Scope` par policy, `policy_scope` dans les collections admin. Les rôles viennent de Rolify (`admin`, `user`).
- Les en-têtes `# == Schema Information` sont générés par annotaterb ; ne pas les éditer à la main.

Vérifier les API contre la version de Rails dans `Gemfile.lock` (8.0).
