---
description: Synchroniser les mises à jour depuis le modèle ULY
---

# /sync - Obtenir les Mises à Jour

Récupérer les nouvelles fonctionnalités et commandes depuis le modèle ULY dans votre espace de travail.

## Instructions

### 1. Trouver le Modèle

Lire `.uly-source` pour obtenir le chemin vers le répertoire modèle :
```bash
cat .uly-source
```

Si ce fichier n'existe pas, dire à l'utilisateur :
> "Je ne trouve pas la source de votre modèle. Cela signifie généralement que vous avez configuré ULY manuellement. Voulez-vous me dire où se trouve votre dossier modèle ?"

### 2. Vérifier Ce Qui Est Nouveau

Comparer les fichiers du modèle avec l'espace de travail de l'utilisateur :

**Fichiers à synchroniser :**
- `.claude/commands/` - Commandes slash
- `skills/` - Capacités ULY

**Fichiers à NE JAMAIS synchroniser (données utilisateur) :**
- `state/` - Objectifs et état actuel de l'utilisateur
- `sessions/` - Journaux de session
- `reports/` - Rapports hebdomadaires
- `content/` - Contenu de l'utilisateur
- `CLAUDE.md` - Profil de l'utilisateur
- `.env` - Secrets de l'utilisateur

### 3. Identifier les Changements

Pour chaque fichier dans `.claude/commands/` et `skills/` du modèle :
- S'il n'existe pas dans l'espace de travail : NOUVEAU
- S'il existe mais diffère : CONFLIT (la version de l'utilisateur gagne)
- S'il est identique : INCHANGÉ

### 4. Montrer Ce Qui Est Disponible

Afficher quelque chose comme :

```
## Mises à Jour Disponibles

**Nouvelles commandes :**
- /nouvellecommande - Description

**Nouvelles compétences :**
- nouvelle-competence/ - Description

**Conflits (votre version conservée) :**
- /commandeexistante - Le modèle a des mises à jour, mais on garde la vôtre

Aucun changement à vos données (objectifs, sessions, etc.) - celles-ci sont toujours en sécurité.
```

### 5. Appliquer les Mises à Jour

Demander : "Voulez-vous que j'ajoute les nouvelles commandes/compétences ?"

Si oui, copier uniquement les fichiers NOUVEAUX. Ne jamais écraser les fichiers existants.

```bash
# Exemple pour une nouvelle commande
cp {modele}/.claude/commands/nouvellecommande.md .claude/commands/
```

### 6. Gérer les Conflits

S'il y a des conflits, expliquer :
> "J'ai trouvé des commandes qui existent aux deux endroits. J'ai gardé vos versions puisque vous les avez peut-être personnalisées. Si vous voulez la version du modèle à la place, dites-moi lesquelles et je les mettrai à jour."

### 7. Terminer

Après la synchronisation :
> "Terminé ! Vous avez maintenant les dernières fonctionnalités ULY. Tapez `/help` pour voir ce qui est disponible."
