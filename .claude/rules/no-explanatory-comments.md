---
description: Nommage sémantique et politique de commentaires
paths:
  - "**/*.{rb,js,erb,jbuilder,rake}"
---

# Commentaires

Exprimer l'intention par les noms métier, les méthodes courtes et la structure du code. Ne pas ajouter spontanément de commentaires explicatifs, JSDoc, TODO, bandeaux de section ou code commenté. Renommer, extraire ou simplifier lorsque cela rend le code compréhensible.

Les commentaires explicitement demandés sont autorisés. Conserver :

- l'en-tête de licence AGPL en tête des fichiers qui en ont un ;
- les blocs `# == Schema Information` générés par annotaterb ;
- une très courte explication d'une contrainte externe que le code ne peut pas exprimer (contournement d'ActiveAnalytics, limite de libvips).
