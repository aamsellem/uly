---
name: end
description: |
  Terminer la session ULY, sauvegarder le contexte et commiter les changements. Utiliser quand l'utilisateur tape /end ou /quit. Crée un journal de session, met à jour l'état, et optionnellement commite dans git.
license: MIT
compatibility: uly
metadata:
  uly-category: session
  user-invocable: true
  slash-command: /end
  model: default
  proactive: false
---

# Compétence Fin de Session

Terminer la session ULY avec préservation complète du contexte.

## Quand Utiliser

- Quand l'utilisateur tape `/end` ou `/quit`
- Quand vraiment terminé pour un moment
- Quand veut un résumé complet de session
- Quand clôture la journée

## Entrées

- Conversation complète de cette session
- État actuel depuis `state/current.md`
- Date d'aujourd'hui (depuis le démarrage)

## Processus

### Étape 1 : Résumer la Session
Réviser la conversation et extraire :
- **Sujets discutés** — Sur quoi avons-nous travaillé ?
- **Décisions prises** — Qu'est-ce qui a été décidé ?
- **Contenu publié** — Tout travail complété ou publié ?
- **Fils ouverts** — Qu'est-ce qui est inachevé ou nécessite un suivi ?
- **Actions à faire** — Que doit faire l'utilisateur ensuite ?

### Étape 2 : Mettre à Jour le Journal de Contenu
Si du contenu a été publié, ajouter à `content/log.md` :
```markdown
### {AUJOURDHUI}
- **[TYPE]** "Titre"
  - URL : {lien si applicable}
  - Notes : {notes pertinentes}
```

### Étape 3 : Mettre à Jour le Journal de Session
Ajouter à `sessions/{AUJOURDHUI}.md` :
```markdown
## Session : {TIMESTAMP}

### Sujets
- {sujet 1}
- {sujet 2}

### Décisions
- {décision 1}

### Publié
- {contenu publié, si applicable}

### Fils Ouverts
- {fil 1}

### Prochaines Actions
- {action 1}
```

Si le fichier n'existe pas, le créer avec l'en-tête :
```markdown
# Journal de Session : {AUJOURDHUI}
```

### Étape 4 : Mettre à Jour l'État
Mettre à jour `state/current.md` avec :
- Toutes nouvelles priorités ou actions à faire
- Statuts de projets modifiés
- Nouveaux fils ouverts
- Éléments supprimés/terminés (marquer comme fait)
- Mettre à jour le timestamp "Dernière mise à jour"

S'assurer que rien ne passe entre les mailles :
- Engagements pris → ajouter aux priorités avec contexte
- Suivis nécessaires → ajouter aux fils ouverts

### Étape 5 : Confirmer avec l'Utilisateur
Montrer un bref résumé :
- Ce qui a été enregistré
- Tous suivis planifiés
- État mis à jour

### Étape 6 : Commiter les Changements (Optionnel)
Si l'utilisateur veut commiter :
```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: journal de session et mise à jour d'état

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
git push
```

## Format de Sortie

```
**Résumé de Session :**
- Sujets : {liste}
- Publié : {contenu si applicable}
- Fils ouverts : {nombre}

**Mis à jour :**
- sessions/{AUJOURDHUI}.md
- state/current.md

À la prochaine !
```

## Notes
- Plusieurs appels `/end` dans une journée s'ajoutent au même fichier de session
- Garder les résumés concis mais assez complets pour le contexte futur

---

*Compétence créée : 2026-01-22*
