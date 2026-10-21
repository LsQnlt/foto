---
description: Façon de travailler sur Foto, valable pour tous les fichiers
---

# Règles générales

## Réponses

- Répondre de façon concise : la conclusion d'abord, le détail seulement s'il change quelque chose pour le lecteur.
- Quand on parle de code, le relier à ce que vit l'utilisateur de Foto : « ce scope filtre les albums publiés, donc un visiteur ne voit pas un album en préparation », plutôt qu'une description technique seule.
- Répondre en français ; le code, les identifiants et les messages de commit restent en anglais.

## KISS

- Préférer la solution la plus simple qui résout le besoin exprimé. Pas d'abstraction, d'option ou de généralisation « au cas où ».
- Utiliser d'abord ce que Rails fournit (scopes, callbacks, helpers, `t(".key")`) avant d'écrire un mécanisme maison.
- Une modification touche le minimum de fichiers. Ne pas réécrire du code voisin qui fonctionne.
- Si deux approches sont possibles, en proposer une et dire pourquoi, sans dérouler toutes les alternatives.

## Git

- Ne jamais lancer `git add`, `git commit`, `git push` ni aucune commande qui modifie l'historique. La revue et le commit appartiennent au développeur.
- En fin de tâche, proposer un message de commit prêt à copier : impératif présent en anglais, une ligne de titre, puis un court corps si le pourquoi n'est pas évident.

## Vocabulaire métier

- **Utilisateur** : propriétaire d'albums, identifié publiquement par son `pseudonym` dans l'URL (`/LsQnlt`).
- **Album** : regroupe des photos ; `published` le rend visible, `password_protected` demande un mot de passe au visiteur (déverrouillage gardé en session).
- **Photo** : image ActiveStorage, convertie en WebP et déclinée en variantes `thumb` (grille) et `lightbox` (plein écran) par `OptimizePhotoJob`.
- **Visiteur** : personne non connectée qui parcourt les albums, aime une photo (`likes_count`, limité par la session) et dont les vues sont comptées par ActiveAnalytics.
- **Administration** : ActiveAdmin, réservé aux rôles Rolify et filtré par les policies Pundit.
