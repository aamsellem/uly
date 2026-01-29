# Intégration Slack

Connectez ULY à votre espace de travail Slack.

## Ce Que Ça Fait

- **Lire des messages** - Voir l'historique des canaux, rechercher des conversations
- **Envoyer des messages** - Poster dans des canaux et fils de discussion
- **Rechercher** - Trouver des messages à travers votre espace de travail
- **Canaux** - Lister et parcourir les canaux publics/privés

## Pour Qui C'est

Les équipes qui utilisent Slack pour la communication et veulent que ULY aide à chercher dans les conversations, suivre les discussions, ou poster des mises à jour.

## Prérequis

- Un espace de travail Slack où vous avez la permission de créer des applications
- L'approbation d'un admin peut être requise pour certains espaces de travail

## Configuration

```bash
./.uly/integrations/slack/setup.sh
```

Le script vous guidera à travers :
1. La création d'une Slack App dans votre espace de travail
2. L'ajout des permissions requises (scopes OAuth)
3. L'installation de l'application et l'obtention de votre token
4. La configuration du serveur MCP

## Permissions Slack Requises

Le script de configuration vous demandera d'ajouter ces User Token Scopes :

| Scope | Ce Qu'il Permet |
|-------|-----------------|
| `channels:history` | Lire les messages dans les canaux publics |
| `channels:read` | Voir les infos de base des canaux |
| `chat:write` | Envoyer des messages |
| `groups:history` | Lire les messages dans les canaux privés |
| `groups:read` | Voir les infos des canaux privés |
| `im:history` | Lire les messages directs |
| `im:read` | Voir les infos des DM |
| `mpim:history` | Lire les DM de groupe |
| `mpim:read` | Voir les infos des DM de groupe |
| `search:read` | Rechercher des messages |
| `users:read` | Voir les infos utilisateur |

## Essayez

Après la configuration, essayez ces commandes avec ULY :

- "Liste mes canaux Slack"
- "Cherche dans Slack les notes de réunion de la semaine dernière"
- "Montre les messages récents dans #engineering"
- "Qu'est-ce qui a été discuté sur la migration API ?"
- "Envoie un message à #general disant 'Bonjour l'équipe !'"

## Espaces de Travail Multiples

Vous pouvez connecter plusieurs espaces de travail Slack en relançant le script de configuration et en choisissant un nom de serveur différent (ex: `slack-work`, `slack-personal`).

## Zone de Danger

Cette intégration peut effectuer des actions qui affectent votre équipe :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Envoyer des messages | **Élevé** | Les membres de l'équipe le voient immédiatement |
| Lire des messages, rechercher | Faible | Pas d'impact externe |

**ULY confirmera toujours avant d'envoyer des messages.**

## Dépannage

**Erreurs "Invalid token"**
- Assurez-vous d'avoir copié le **User OAuth Token** (commence par `xoxp-`), pas le Bot token
- Vérifiez que l'application est installée dans votre espace de travail

**Canaux manquants**
- L'application peut seulement voir les canaux auxquels vous avez accès
- Pour les canaux privés, vous devez être membre

**Impossible d'envoyer des messages**
- Assurez-vous que le scope `chat:write` est ajouté
- Vous pouvez seulement poster dans les canaux dont vous êtes membre

**Permission refusée**
- Certains espaces de travail nécessitent l'approbation d'un admin pour les nouvelles applications
- Consultez votre admin Slack

## Serveur MCP

Cette intégration utilise [slack-mcp-server](https://github.com/korotovsky/slack-mcp-server) par korotovsky.

---

*Contribué par Peter Vanhee*
