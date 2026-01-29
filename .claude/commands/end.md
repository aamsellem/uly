---
description: Terminer la session ULY - sauvegarder le contexte et l'état
---

# /end - Terminer la Session ULY

Conclure la session en cours et sauvegarder le contexte pour la continuité.

## Instructions

### 1. Résumer Cette Session
Revoir la conversation et extraire :
- **Sujets discutés** - Sur quoi avons-nous travaillé ?
- **Décisions prises** - Qu'est-ce qui a été décidé ?
- **Fils ouverts** - Qu'est-ce qui est inachevé ou nécessite un suivi ?
- **Actions à faire** - Que faut-il faire ensuite ?

### 2. Mettre à Jour le Journal de Session
Obtenir la date d'aujourd'hui avec `date +%Y-%m-%d`.

Ajouter à `sessions/{AUJOURDHUI}.md` (créer si n'existe pas) :
```markdown
## Session : {HEURE}

### Sujets
- {sujet 1}
- {sujet 2}

### Décisions
- {décision 1}

### Fils Ouverts
- {fil 1}

### Prochaines Actions
- {action 1}
```

Si création d'un nouveau fichier, ajouter l'en-tête : `# Journal de Session : {AUJOURDHUI}`

### 3. Mettre à Jour l'État
Mettre à jour `state/current.md` avec :
- Toute nouvelle priorité
- Statuts de projets modifiés
- Nouveaux fils ouverts
- Éléments supprimés/terminés

### 4. Confirmer
Montrer un bref résumé :
- Ce qui a été enregistré
- Éléments clés pour la prochaine session
- Confirmation de mise à jour de l'état

Rester concis.
