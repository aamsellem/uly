---
description: Afficher les commandes et intégrations disponibles
---

# /help - Aide ULY

Montrer à l'utilisateur ce que ULY peut faire et quelles intégrations sont disponibles.

## Instructions

### 1. Afficher les Commandes Disponibles

Afficher cette référence :

```
## Commandes Slash

| Commande  | Ce Qu'elle Fait                          |
|-----------|------------------------------------------|
| /uly      | Démarrer une session avec un briefing    |
| /end      | Terminer la session et tout sauvegarder  |
| /update   | Point de contrôle rapide (sauvegarder)   |
| /report   | Générer un résumé hebdomadaire du travail|
| /commit   | Réviser et commiter les changements git  |
| /code     | Ouvrir ULY dans votre IDE                |
| /help     | Afficher ce guide d'aide                 |
| /sync     | Obtenir les mises à jour du modèle ULY   |
```

### 2. Afficher les Intégrations Actuelles

Vérifier quels serveurs MCP sont configurés en lançant :
```bash
claude mcp list
```

Puis afficher quelque chose comme :

```
## Vos Intégrations

Ce sont les outils auxquels ULY peut actuellement accéder :

| Intégration      | Ce Qu'elle Fait                                    |
|------------------|---------------------------------------------------|
| Google Workspace | Lire/envoyer des emails, vérifier le calendrier, accéder à Drive |
| Atlassian        | Voir les tickets Jira, rechercher dans Confluence |

(Lister uniquement ce qui est réellement configuré selon la sortie mcp list)
```

Si aucune intégration n'est configurée, dire :
```
## Vos Intégrations

Aucune intégration configurée pour l'instant. Je peux vous aider à en configurer une, ou vous pouvez lancer les scripts de configuration dans `.uly/integrations/`.
```

### 3. Afficher les Intégrations Disponibles

Lire `.uly/integrations/README.md` pour voir la liste complète des intégrations disponibles, puis afficher :

```
## Intégrations Disponibles

Celles-ci peuvent être ajoutées à tout moment. Parcourez `.uly/integrations/` pour les détails.

| Intégration      | Commande de Configuration                        | Ce Qu'elle Fait               |
|------------------|--------------------------------------------------|-------------------------------|
| Google Workspace | ./.uly/integrations/google-workspace/setup.sh    | Gmail, Calendar, Drive        |
| Atlassian        | ./.uly/integrations/atlassian/setup.sh           | Jira, Confluence              |

Vous voulez autre chose ? Vérifiez `.uly/integrations/REQUESTS.md` pour voir ce qui est prévu ou demander une nouvelle intégration !
```

### 4. Proposer les Prochaines Étapes

Terminer avec :

```
---

Voulez-vous que je vous aide à configurer une intégration, créer une nouvelle compétence, ou en apprendre plus sur ce que je peux faire ?

Sinon, appuyez sur **Esc** pour retourner au travail.
```

Attendre que l'utilisateur réponde ou quitte.
