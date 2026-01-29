---
description: Lister les tâches en attente de retour utilisateur (compatible N8N)
---

# /pending - Tâches en Attente de Retour

Génère un message de relance pour les tâches où ULY attend un retour de l'utilisateur.

## Instructions

### 1. Lire le Fichier
Lire `state/current.md` et trouver la section `## En Attente de Retour`.

### 2. Compter les Tâches
Compter UNIQUEMENT les lignes qui commencent par `- [ ]` (case non cochée).
Les commentaires HTML `<!-- -->` ne comptent PAS comme des tâches.

### 3. Répondre

**RÈGLE ABSOLUE : Si zéro tâche `- [ ]` → tu réponds avec RIEN. Pas un mot. Pas d'explication. RIEN.**

**Si au moins une tâche `- [ ]` existe :**
Générer un message de relance avec ta personnalité. Exemple :
```
J'attends toujours ton retour sur :
• Validation du design
• Retour sur l'API

Tu me fais signe ?
```

## Exemples

**Exemple 1 - Section vide :**
```markdown
## En Attente de Retour

<!-- Tâches où ULY attend un retour -->
```
→ Réponse : (rien, vide, aucun caractère)

**Exemple 2 - Avec tâches :**
```markdown
## En Attente de Retour

- [ ] Validation du design — depuis le 2025-01-20
- [ ] Choix techno backend — depuis le 2025-01-22
```
→ Réponse : Message de relance avec personnalité
