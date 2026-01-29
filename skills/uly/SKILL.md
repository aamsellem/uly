---
name: uly
description: |
  Démarrer une session ULY avec briefing. Utiliser quand l'utilisateur tape /uly ou démarre une nouvelle session. Charge le contexte, révise l'état, donne un briefing quotidien.
license: MIT
compatibility: uly
metadata:
  uly-category: session
  user-invocable: true
  slash-command: /uly
  model: default
  proactive: false
---

# Compétence Démarrage de Session

Démarrer une session ULY avec chargement complet du contexte et briefing quotidien.

## Quand Utiliser

- Quand l'utilisateur tape `/uly`
- Au démarrage de toute session Claude Code dans le répertoire ULY
- Quand reprend le travail après une pause

## Processus

### Étape 1 : Établir la Date Actuelle
```bash
date +%Y-%m-%d
```
Stocker comme `AUJOURDHUI`. Utiliser pour tous les nommages de fichiers et références de date.

### Étape 2 : Charger le Contexte

Lire dans l'ordre :
1. `state/current.md` — Priorités actuelles, fils ouverts, et état
2. `sessions/{AUJOURDHUI}.md` — Si existe, nous reprenons aujourd'hui
3. Si pas de fichier aujourd'hui, lire `sessions/{HIER}.md` pour la continuité

### Étape 3 : Réviser les Objectifs
Vérifier `state/goals.md` pour :
- Objectifs annuels et progrès
- Cibles mensuelles

### Étape 4 : Évaluer le Progrès
Vérifier `content/log.md` pour le mois en cours :
- Contenu publié vs. objectifs
- Jours restants dans le mois

### Étape 5 : Vérifier les Suivis
Réviser `state/current.md` pour tous éléments de suivi :
- Faire remonter tous éléments avec date de révision ≤ AUJOURDHUI
- Rappeler à l'utilisateur les suivis à venir dans les 3 jours

### Étape 6 : Faire Remonter les Alertes Proactives
Compiler et présenter :
- **Priorités actives** depuis `state/current.md`
- **Fils ouverts** nécessitant attention
- Statut du rythme de contenu (si en retard)
- Toutes échéances approchant

### Étape 7 : Saluer l'Utilisateur
Présenter un briefing concis :
- Date et jour de la semaine
- Top 3 priorités
- Toutes alertes ou rappels
- Demander comment aider aujourd'hui

## Format de Sortie

```
Bonjour ! On est {Jour}, {Date}.

**Focus d'Aujourd'hui :**
1. {Priorité 1}
2. {Priorité 2}
3. {Priorité 3}

**Alertes :**
- {Alerte si applicable}

**Progrès ({Mois}) :**
- {Objectif 1} : X/Y
- {Objectif 2} : X/Y

Comment puis-je vous aider aujourd'hui ?
```

## Notes
- Si c'est une session reprise (le journal d'aujourd'hui existe), reconnaître ce qui a déjà été couvert
- Garder le briefing concis — détails sur demande

---

*Compétence créée : 2026-01-22*
