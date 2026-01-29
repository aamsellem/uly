---
description: Point de contrôle rapide sans terminer la session
---

# /update - Point de Contrôle Rapide

Sauvegarde légère sans terminer la session. À utiliser fréquemment pour préserver le contexte.

## Instructions

### 1. Identifier Ce Qui a Changé
Scanner rapidement la conversation récente pour :
- Sujets travaillés
- Décisions prises
- Fichiers créés/modifiés
- Tout changement d'état nécessaire

Rester bref. Pas besoin de résumé complet.

### 2. Ajouter au Journal de Session
Obtenir la date d'aujourd'hui : `date +%Y-%m-%d`

Ajouter à `sessions/{AUJOURDHUI}.md` :
```markdown
## Mise à jour : {HEURE}
- {sur quoi on a travaillé, 1-3 points}
```

Si le fichier n'existe pas, créer avec l'en-tête : `# Journal de Session : {AUJOURDHUI}`

### 3. Mettre à Jour l'État (si nécessaire)
Ne mettre à jour `state/current.md` que si quelque chose a vraiment changé :
- Nouveau fil ouvert
- Élément terminé
- Priorité modifiée
- Nouvelle tâche découverte

Passer si rien de matériel n'a changé.

### 4. Confirmer (minimal)
Une ligne : "Sauvegardé : {brève description}"

Pas de résumé. Pas de liste "prochaines actions". Juste confirmer la sauvegarde.
