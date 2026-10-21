---
description: Réponses JSON via le responder du projet
paths:
  - "app/controllers/**/*.rb"
---

# Contrôleurs

Toute réponse JSON de succès ou d'erreur passe par `respond_with_json`, fourni par le concern `Responder`. Ne pas construire de réponse artisanale avec `render json:`.

- Record ActiveRecord invalide : `respond_with_json.error(record)` pour conserver `errors` et `errors_by_field`.
- Message simple : `respond_with_json.error(message)` pour le champ `error`.
- Préserver la forme attendue par le frontend existant ; adapter le consommateur si le contrat change.
- Ne pas utiliser le helper legacy `json_response` dans du nouveau code.
- Pour un endpoint uniquement JSON, pas de `respond_to` superflu. Pour HTML et JSON, conserver `respond_to` et utiliser le responder dans la branche JSON.

```ruby
respond_with_json.success(message: t('.success'), export_id: export.id)
respond_with_json.error(record, status: :unprocessable_entity)
```
