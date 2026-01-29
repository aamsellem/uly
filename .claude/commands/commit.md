---
description: Réviser les changements et créer des commits git propres
---

# /commit - Workflow de Commit Git

Réviser les changements non commités et créer des commits logiques et bien organisés.

## Instructions

### 1. Vérifier l'État Actuel
Lancer `git status` et `git diff --stat` pour voir tous les changements.

### 2. Grouper les Changements
Identifier les groupements logiques depuis les changements :

| Groupe | Fichiers | Type de Commit |
|--------|----------|----------------|
| Fonctionnalités/Scripts | `src/*.py`, `*.js` | `feat:` |
| Config | `CLAUDE.md`, `*.json` | `chore:` |
| Contenu | `content/`, `research/` | `content:` |
| État/Sessions | `state/`, `sessions/` | `chore:` |
| Docs | `*.md` (non-état) | `docs:` |

### 3. Créer les Commits
Pour chaque groupe logique, créer un commit ciblé :

```bash
git add <fichiers-pertinents>
git commit -m "$(cat <<'EOF'
<type>: <courte description>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 4. Ordre des Commits
1. Dépendances d'abord (si B utilise A, commiter A d'abord)
2. Fonctionnalités avant docs
3. Contenu avant état
4. **État/sessions toujours en dernier**

### 5. Push (si demandé)
Après que tous les commits sont créés :
```bash
git push
```

### 6. Vérifier
Montrer les commits créés :
```bash
git log --oneline -5
```

## Types de Commit

| Type | Utiliser Pour |
|------|---------------|
| `feat` | Nouvelles fonctionnalités, scripts, intégrations |
| `fix` | Corrections de bugs |
| `docs` | Documentation, guides de configuration |
| `content` | Articles de blog, recherche, fichiers de contenu |
| `chore` | Config, maintenance, mises à jour d'état |
