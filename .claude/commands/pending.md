---
description: Lister les tâches ACTIVES en attente de retour (compatible N8N)
---

# /pending - Tâches Actives en Attente

Génère un message de relance pour les projets ACTIFS uniquement.
Les projets "En pause" ne sont PAS inclus.

## Instructions

### 1. Lire le Fichier
Lire `state/current.md`, section `## En Attente de Retour`, sous-section `### Actif`.

**IGNORER** la sous-section `### En pause`.

### 2. Compter les Tâches Actives
Compter UNIQUEMENT les `- [ ]` dans `### Actif`.
Les commentaires `<!-- -->` ne comptent pas.

### 3. Répondre

**RÈGLE ABSOLUE : Si zéro tâche dans Actif → RIEN. Pas un mot.**

**Si au moins une tâche dans Actif :**
Message de relance avec ta personnalité. Exemple :
```
Alors, où t'en es sur :
• Refonte de l'API
• Design page d'accueil

Avancé ? Bloqué ? Terminé ?
```

## Exemples

**Exemple 1 - Actif vide :**
```markdown
### Actif

### En pause
- [ ] Projet X — en attente client
```
→ Réponse : (rien)

**Exemple 2 - Tâches actives :**
```markdown
### Actif
- [ ] Refonte API — depuis le 2025-01-20

### En pause
- [ ] Projet X — en attente client
```
→ Réponse : Message de relance sur "Refonte API" uniquement
