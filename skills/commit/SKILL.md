---
name: commit
description: |
  Réviser les changements et créer des commits git propres. Utiliser quand l'utilisateur tape /commit ou demande à commiter des changements. Crée des commits bien structurés avec des messages appropriés.
license: MIT
compatibility: uly
metadata:
  uly-category: work
  user-invocable: true
  slash-command: /commit
  model: default
  proactive: false
---

# Compétence Commit

Réviser les changements et créer des commits git propres et bien structurés.

## Quand Utiliser

- L'utilisateur tape `/commit`
- L'utilisateur demande de "commiter les changements" ou "sauvegarder dans git"
- Après avoir complété un travail

## Processus

### Étape 1 : Vérifier le Statut Actuel
```bash
git status --short
git diff --stat
```

Réviser ce qui a changé :
- Nouveaux fichiers
- Fichiers modifiés
- Fichiers supprimés

### Étape 2 : Réviser les Changements
```bash
git diff
```

Comprendre ce qui a changé et pourquoi. Grouper les changements liés.

### Étape 3 : Vérifier l'Historique Récent
```bash
git log --oneline -5
```

Correspondre au style de commit du dépôt.

### Étape 4 : Créer des Commits Logiques

Grouper les fichiers par type et créer des commits séparés :

| Catégorie | Fichiers | Type de Commit |
|-----------|----------|----------------|
| Fonctionnalités | Nouvelles fonctionnalités | `feat:` |
| Corrections | Corrections | `fix:` |
| Documentation | `*.md`, docs | `docs:` |
| Configuration | Fichiers de config | `chore:` |
| État/Sessions | `state/`, `sessions/` | `chore:` |

### Étape 5 : Stager et Commiter

Pour chaque groupe :
```bash
git add <fichiers spécifiques>
git commit -m "$(cat <<'EOF'
<type>: <courte description>

<description plus longue optionnelle>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Étape 6 : Push (si demandé)
```bash
git push
```

## Directives pour les Messages de Commit

**Format :**
```
<type>: <description>

[corps optionnel]

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types :**
- `feat:` — Nouvelle fonctionnalité
- `fix:` — Correction de bug
- `docs:` — Documentation
- `chore:` — Maintenance, config, mises à jour d'état
- `refactor:` — Restructuration de code
- `test:` — Tests

**Bons exemples :**
- `feat: ajouter système de notification par email`
- `fix: résoudre problème de timeout à la connexion`
- `docs: mettre à jour documentation API`
- `chore: journal de session et mise à jour d'état`

**Mauvais exemples :**
- `update` (trop vague)
- `correction de trucs` (pas descriptif)
- `WIP` (ne pas commiter du travail en cours)

## Format de Sortie

```
**Changements :**
- {fichier 1}: {ce qui a changé}
- {fichier 2}: {ce qui a changé}

**Commits créés :**
1. `<type>: <message>`
2. `<type>: <message>`

{Poussé vers origin/main | Prêt à pousser}
```

---

*Compétence créée : 2026-01-22*
