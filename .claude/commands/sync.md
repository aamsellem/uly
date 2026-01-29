---
description: Synchroniser les mises à jour depuis le dépôt ULY officiel
---

# /sync - Obtenir les Mises à Jour

Récupérer les nouvelles fonctionnalités et commandes depuis le dépôt ULY officiel.

## Instructions

### 1. Trouver la Source

Vérifier si `.uly-source` existe :
```bash
cat .uly-source 2>/dev/null
```

**Si le fichier existe :** Utiliser ce chemin/URL comme source.

**Si le fichier n'existe pas :** Proposer à l'utilisateur :

> "Je n'ai pas trouvé de source configurée pour les mises à jour.
>
> **Option 1 (recommandé) :** Synchroniser depuis le dépôt officiel GitHub
> ```
> https://github.com/aamsellem/uly
> ```
>
> **Option 2 :** Utiliser un chemin local vers un template ULY
>
> Que préférez-vous ?"

Si l'utilisateur choisit GitHub ou valide l'option 1, créer le fichier :
```bash
echo "https://github.com/aamsellem/uly" > .uly-source
```

### 2. Récupérer les Mises à Jour

**Si la source est une URL GitHub :**

```bash
# Créer un dossier temporaire
TEMP_DIR=$(mktemp -d)

# Cloner le repo (shallow clone pour la vitesse)
git clone --depth 1 https://github.com/aamsellem/uly.git "$TEMP_DIR"

# La source est maintenant dans $TEMP_DIR
```

**Si la source est un chemin local :**
```bash
# Utiliser directement le chemin
SOURCE_DIR=$(cat .uly-source)
```

### 3. Comparer les Fichiers

**Fichiers à synchroniser :**
- `.claude/commands/` - Commandes slash
- `skills/` - Capacités ULY
- `.uly/integrations/` - Scripts d'intégration (setup.sh, etc.)

**Fichiers à NE JAMAIS synchroniser (données utilisateur) :**
- `state/` - Objectifs et état actuel
- `sessions/` - Journaux de session
- `reports/` - Rapports hebdomadaires
- `content/` - Contenu de l'utilisateur
- `CLAUDE.md` - Profil de l'utilisateur (sauf si non configuré)
- `.env` - Secrets

### 4. Identifier les Changements

Pour chaque fichier dans les dossiers à synchroniser :
- **NOUVEAU** : N'existe pas dans l'espace de travail
- **MIS À JOUR** : Existe mais diffère (montrer le diff si demandé)
- **IDENTIQUE** : Aucun changement

### 5. Afficher le Résumé

```
## Mises à Jour Disponibles

**Nouvelles commandes :**
- /nouvelle-commande - Description

**Commandes mises à jour :**
- /commande-existante - Nouvelles fonctionnalités

**Nouvelles intégrations :**
- cloudflare-tunnel/ - Exposer ULY via HTTPS

**Aucun changement à vos données** (objectifs, sessions, profil)
```

### 6. Appliquer les Mises à Jour

Demander : "Voulez-vous appliquer ces mises à jour ?"

**Options :**
- **Tout appliquer** : Copier tous les nouveaux fichiers et mises à jour
- **Choisir** : Lister et laisser l'utilisateur sélectionner
- **Annuler** : Ne rien faire

Pour les fichiers MIS À JOUR, demander si l'utilisateur veut :
- Remplacer par la nouvelle version
- Garder sa version actuelle
- Voir le diff avant de décider

### 7. Nettoyer

Si un dossier temporaire a été créé :
```bash
rm -rf "$TEMP_DIR"
```

### 8. Terminer

> "Synchronisation terminée ! Vous avez maintenant les dernières fonctionnalités ULY.
>
> **Nouveautés ajoutées :**
> - /nouvelle-commande
> - integration-x/
>
> Tapez `/help` pour voir toutes les commandes disponibles."

---

## Notes

- La synchronisation ne touche **jamais** aux données utilisateur
- Les fichiers personnalisés par l'utilisateur sont préservés (sauf demande explicite)
- Source par défaut : `https://github.com/aamsellem/uly`
