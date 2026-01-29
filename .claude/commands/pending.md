---
description: Lister les tâches en attente de retour utilisateur (compatible N8N)
---

# /pending - Tâches en Attente de Retour

Génère un message de relance pour les tâches où ULY attend un retour de l'utilisateur.
Conçu pour être utilisé dans un workflow N8N ou manuellement.

## Instructions

### 1. Lire les Attentes
Lire `state/current.md` et chercher la section `## En Attente de Retour`.

Cette section contient les tâches au format :
```markdown
## En Attente de Retour

- [ ] {description de la tâche} — depuis le {date}
- [ ] {autre tâche} — depuis le {date}
```

### 2. Analyser et Répondre

**Si la section est vide ou n'existe pas :**
- Ne rien répondre (sortie vide)
- Aucun texte, aucun message

**Si des tâches sont en attente :**
- Générer un message de relance naturel
- Adapter le ton à la personnalité configurée dans CLAUDE.md
- Format suggéré :

```
J'attends toujours ton retour sur :
• {tâche 1}
• {tâche 2}

Tu peux me faire un point quand tu as un moment ?
```

### 3. Format de Sortie (N8N)

Pour une intégration N8N optimale :
- Texte brut uniquement, pas de markdown complexe
- Une seule réponse, pas de questions de suivi
- Si rien en attente : sortie strictement vide (pas même un espace)

## Gestion des Attentes

Pour ajouter une tâche en attente, utiliser `/update` ou `/end` et ajouter dans `state/current.md` :
```markdown
## En Attente de Retour

- [ ] Retour sur la proposition de refacto API — depuis le 2025-01-15
```

Quand l'utilisateur donne son retour, cocher ou supprimer la ligne.
