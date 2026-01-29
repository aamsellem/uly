---
name: daily-briefing
description: |
  Générer un briefing quotidien avec priorités, progrès et alertes. Utilisé dans le cadre du démarrage de session ou quand l'utilisateur demande "qu'est-ce qu'il y a aujourd'hui". Compétence interne supportant la compétence uly.
license: MIT
compatibility: uly
metadata:
  uly-category: session
  user-invocable: false
  slash-command: null
  model: default
  proactive: false
---

# Compétence Briefing Quotidien

Générer un briefing quotidien complet avec priorités, progrès et alertes.

## Quand Utiliser

- Dans le cadre de la compétence `uly` (démarrage de session)
- L'utilisateur demande "qu'est-ce qu'il y a aujourd'hui" ou "briefing quotidien"
- Demandes de check-in matinal

## Processus

### Étape 1 : Aperçu du Calendrier (si disponible)
- Événements d'aujourd'hui avec heures
- Événements de demain (aperçu)
- 7 prochains jours : toutes échéances importantes

### Étape 2 : Statut des Tâches
Depuis `state/current.md` :
- Priorités actives
- Éléments en retard
- À faire aujourd'hui
- Fils ouverts nécessitant attention

### Étape 3 : Vérification du Progrès
Pour le mois en cours depuis `state/goals.md` :
- Progrès par rapport à chaque objectif
- Jours restants dans le mois

Si en retard sur le rythme, le signaler.

### Étape 4 : Fils Ouverts
Depuis `state/current.md` :
- Tout ce qui attend un suivi
- Fils périmés (pas de mise à jour > 5 jours)

### Étape 5 : Suggestions Proactives
Basées sur les patterns :
- "Vous n'avez pas progressé sur {objectif} cette semaine"
- "L'échéance pour {élément} est dans 3 jours"
- "Revue mensuelle à venir — voulez-vous la planifier ?"

## Format de Sortie

Rester concis. Structurer comme :
```
## {Jour}, {Date}

**Aujourd'hui** : {résumé}

**Alertes** :
- {éléments urgents}

**Progrès** : {résumé du statut des objectifs}

**Focus** : {top 1-2 priorités}
```

Proposer d'étendre toute section sur demande.

---

*Compétence créée : 2026-01-22*
