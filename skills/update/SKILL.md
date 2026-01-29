---
name: update
description: |
  Point de contrôle rapide du contexte sans terminer la session. Utiliser quand l'utilisateur tape /update. Sauvegarde le progrès dans le journal de session et met à jour l'état si nécessaire.
license: MIT
compatibility: uly
metadata:
  uly-category: session
  user-invocable: true
  slash-command: /update
  model: default
  proactive: false
---

# Compétence Mise à Jour

Sauvegarde légère sans terminer la session. Utiliser fréquemment pour préserver le contexte.

## Quand Utiliser

- L'utilisateur tape `/update`
- Après avoir terminé un bloc de travail
- Avant de changer de contexte
- Environ toutes les heures pendant les longues sessions
- Quand le contexte devient limité

## Processus

### Étape 1 : Identifier Ce Qui a Changé
Scanner rapidement la conversation récente pour :
- Sujets travaillés
- Décisions prises
- Fichiers créés/modifiés
- Tout changement d'état nécessaire

Rester bref. Pas besoin de résumé complet.

### Étape 2 : Ajouter au Journal de Session
Obtenir la date d'aujourd'hui : `date +%Y-%m-%d`

Ajouter à `sessions/{AUJOURDHUI}.md` :
```markdown
## Mise à jour : {HEURE}
- {sur quoi on a travaillé, 1-3 points}
```

Si le fichier n'existe pas, créer avec l'en-tête : `# Journal de Session : {AUJOURDHUI}`

### Étape 3 : Mettre à Jour l'État (si nécessaire)
Ne mettre à jour `state/current.md` que si quelque chose a vraiment changé :
- Nouveau fil ouvert
- Élément terminé
- Priorité modifiée
- Nouveau projet/tâche découvert

Passer si rien de matériel n'a changé.

### Étape 4 : Confirmer (minimal)
Une ligne : "Sauvegardé : {brève description}"

Pas de résumé. Pas de liste "prochaines actions". Juste confirmer la sauvegarde.

## Format de Sortie

```
Sauvegardé : {description en 2-5 mots de ce qui a été sauvegardé}
```

## Notes
- C'est intentionnellement léger
- Ne pas utiliser pour une clôture complète de session (utiliser `/end` pour ça)
- Plusieurs mises à jour par jour s'ajoutent au même fichier de session

---

*Compétence créée : 2026-01-22*
