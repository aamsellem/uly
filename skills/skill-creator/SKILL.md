---
name: skill-creator
description: |
  Créer de nouvelles compétences ULY sur demande. Utiliser quand l'utilisateur dit "donne-toi la capacité de X" ou "crée une compétence pour Y". Génère une structure de compétence appropriée avec SKILL.md.
license: MIT
compatibility: uly
metadata:
  uly-category: meta
  user-invocable: false
  slash-command: null
  model: default
  proactive: false
---

# Compétence Créateur de Compétences

Créer de nouvelles compétences ULY basées sur les demandes utilisateur.

## Quand Utiliser

Phrases déclencheuses :
- "Donne-toi la capacité de..."
- "Crée une compétence pour..."
- "Ajoute un workflow pour..."
- "Je veux que ULY puisse..."

## Processus

### Étape 1 : Comprendre la Demande
Clarifier :
- Que doit faire la compétence ?
- Quand doit-elle se déclencher ?
- De quelles entrées a-t-elle besoin ?
- Quelle sortie doit-elle produire ?

### Étape 2 : Concevoir la Compétence
Déterminer :
- **name** : Identifiant court en kebab-case (ex: `revue-hebdo`)
- **description** : Explication claire du but et déclencheurs
- **category** : session, work, content, research, events, communication, meta
- **user-invocable** : A-t-elle une commande slash ?
- **slash-command** : Si oui, quelle commande ? (ex: `/revue`)
- **proactive** : ULY doit-il détecter et déclencher automatiquement ?

### Étape 3 : Créer le Répertoire de Compétence
```bash
mkdir -p skills/{nom-competence}
```

### Étape 4 : Écrire SKILL.md
Créer `skills/{nom-competence}/SKILL.md` avec :

```markdown
---
name: {nom-competence}
description: |
  {Ce que fait cette compétence et quand l'utiliser.}
license: MIT
compatibility: uly
metadata:
  uly-category: {category}
  user-invocable: {true|false}
  slash-command: {/commande ou null}
  model: default
  proactive: {true|false}
---

# {Titre de la Compétence}

{Brève description}

## Quand Utiliser

- {Condition de déclenchement 1}
- {Condition de déclenchement 2}

## Processus

### Étape 1 : {Première Étape}
{Description}

### Étape 2 : {Deuxième Étape}
{Description}

## Format de Sortie

{Sortie attendue}

---

*Compétence créée : {AUJOURDHUI}*
```

### Étape 5 : Ajouter des Scripts (si nécessaire)
Si la compétence nécessite du code :
```bash
mkdir -p skills/{nom-competence}/scripts
```

Créer les scripts nécessaires dans ce répertoire.

### Étape 6 : Mettre à Jour l'Index des Compétences
Ajouter la nouvelle compétence à l'Index des Compétences dans `CLAUDE.md` :

```markdown
| `{nom-competence}` | {déclencheurs} | {description} |
```

### Étape 7 : Confirmer la Création
Dire à l'utilisateur :
- Compétence créée à `skills/{nom-competence}/SKILL.md`
- Comment la déclencher
- Prête à utiliser immédiatement

## Format de Sortie

```
Compétence créée : **{nom-competence}**
- Emplacement : `skills/{nom-competence}/SKILL.md`
- Déclencheur : {comment l'utiliser}
- Catégorie : {category}

La compétence est prête à utiliser.
```

## Notes
- Utiliser le modèle à `skills/_template/SKILL.md` comme point de départ
- Garder les compétences focalisées sur une tâche
- Inclure des conditions de déclenchement claires pour que ULY sache quand l'utiliser

---

*Compétence créée : 2026-01-22*
