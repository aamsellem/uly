---
description: Générer un rapport hebdomadaire de votre travail
---

# /report - Rapport Hebdomadaire

Générer un résumé de ce que vous avez accompli cette semaine.

## Instructions

### 1. Rassembler les Données

Lire les journaux de session de cette semaine :
- Lancer `date +%Y-%m-%d` pour obtenir la date d'aujourd'hui
- Lire les fichiers de session depuis `sessions/` pour les 7 derniers jours
- Aussi lire `state/current.md` pour le contexte sur les priorités
- Lire `state/goals.md` pour connecter le travail aux objectifs

### 2. Compiler le Rapport

Créer un rapport avec ces sections :

```markdown
# Rapport Hebdomadaire : {Semaine du DATE}

## Points Forts
- Top 3-5 accomplissements de cette semaine
- Rester concis, se concentrer sur les résultats pas les activités

## Travail Terminé
- Organisé par projet ou domaine d'objectif
- Inclure les livrables spécifiques, décisions prises, problèmes résolus

## En Cours
- Ce sur quoi on travaille activement
- Achèvement prévu ou prochaines étapes

## Blocages / Nécessite Attention
- Tout ce qui est bloqué ou en attente d'autres personnes
- Décisions nécessaires

## Semaine Prochaine
- Priorités principales pour la semaine à venir
- Report des fils ouverts

## Progrès vers les Objectifs
- Mise à jour rapide sur le progrès vers les objectifs annuels (depuis state/goals.md)
- Noter tout objectif qui a reçu de l'attention cette semaine
```

### 3. Sauvegarder le Rapport

Sauvegarder dans `reports/AAAA-MM-JJ.md` en utilisant la date d'aujourd'hui.

### 4. Proposer les Prochaines Étapes

Demander : "Voulez-vous que je copie ceci quelque part, le partage, ou ajuste le format ?"

Suivis courants :
- Copier dans le presse-papiers pour coller dans Slack/email
- Ajuster le ton (plus formel pour les managers, décontracté pour l'équipe)
- Se concentrer sur des projets ou objectifs spécifiques
