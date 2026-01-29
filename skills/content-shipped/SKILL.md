---
name: content-shipped
description: |
  Enregistrer le contenu publié dans le journal de contenu. Utiliser quand l'utilisateur dit "j'ai publié", "j'ai posté", "je viens de publier", ou mentionne avoir terminé un travail de contenu.
license: MIT
compatibility: uly
metadata:
  uly-category: content
  user-invocable: false
  slash-command: null
  model: default
  proactive: true
---

# Compétence Contenu Publié

Enregistrer le contenu terminé pour suivre le progrès par rapport aux objectifs.

## Quand Utiliser

Phrases déclencheuses :
- "J'ai publié..."
- "J'ai posté..."
- "Je viens de poster..."
- "J'ai terminé le/la..."
- "L'{article/vidéo/post} est en ligne"

## Processus

### Étape 1 : Extraire les Détails du Contenu
Depuis la conversation, identifier :
- **Type** : Article, vidéo, podcast, post social, etc.
- **Titre** : Le titre du contenu
- **URL** : Lien si disponible
- **Plateforme** : Où c'est publié
- **Objectif** : Quel objectif mensuel/annuel cela compte

### Étape 2 : Confirmer les Détails
Si des détails ne sont pas clairs, demander :
- "Quel est le titre ?"
- "Où c'est publié ?"
- "Quel objectif cela compte ?"

### Étape 3 : Enregistrer dans le Fichier de Contenu
Ajouter à `content/log.md` :

```markdown
### {DATE}
- **[{TYPE}]** "{Titre}"
  - URL : {lien}
  - Plateforme : {où publié}
  - Objectif : {quel objectif cela soutient}
```

### Étape 4 : Mettre à Jour le Progrès
Vérifier `state/goals.md` pour les cibles mensuelles pertinentes et noter le progrès.

### Étape 5 : Célébrer (brièvement)
Reconnaître le travail publié :
- "Super ! Ça fait {X}/{Y} pour le mois."
- "Enregistré. Vous êtes en bonne voie pour {objectif}."

## Format de Sortie

```
Enregistré : **[{TYPE}]** "{Titre}"
Progrès : {X}/{Y} {type de contenu} ce mois-ci
```

## Notes
- Être proactif pour détecter le contenu publié dans la conversation
- Ne pas exiger de déclencheur explicite si le contexte est clair
- Garder la célébration brève, pas exagérée

---

*Compétence créée : 2026-01-22*
