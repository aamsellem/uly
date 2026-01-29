# Intégration Atlassian

Connectez ULY à Jira et Confluence.

## Ce Que Ça Fait

- **Jira** - Voir les tickets, rechercher les issues, vérifier le statut du sprint
- **Confluence** - Rechercher la documentation, lire les pages

## Pour Qui C'est

Les équipes qui utilisent les produits Atlassian pour la gestion de projet et la documentation.

## Prérequis

- Un compte Atlassian (Jira et/ou Confluence)
- Accès à l'espace de travail Atlassian que vous voulez connecter

## Configuration

```bash
./integrations/atlassian/setup.sh
```

Le script va :
1. Configurer le serveur MCP Atlassian
2. Vous guider à travers l'authentification manuelle via `claude mcp`

## Essayez

Après la configuration, essayez ces commandes avec ULY :

- "Montre-moi mes tickets Jira ouverts"
- "Quel est le statut de PROJECT-123 ?"
- "Cherche dans Confluence la documentation d'onboarding"
- "Quels tickets sont dans le sprint actuel ?"
- "Trouve les issues Jira qui me sont assignées"

## Zone de Danger

Cette intégration peut effectuer des actions qui affectent votre équipe :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Modifier les tickets Jira | **Moyen** | L'équipe voit les changements, notifications envoyées |
| Éditer les pages Confluence | **Moyen** | L'équipe voit les changements dans les docs partagés |
| Créer des issues/pages | Faible | Crée de nouveaux éléments, n'affecte pas l'existant |
| Lire tickets, pages, rechercher | Faible | Pas d'impact externe |

**ULY confirmera toujours avant de modifier des tickets ou d'éditer des pages.**

## Dépannage

**Problèmes d'authentification / boucle "Unauthorized"**

Ré-authentifiez manuellement :

1. Lancez `claude mcp` dans votre terminal
2. Trouvez `atlassian` dans la liste des serveurs et sélectionnez-le
3. Choisissez "Authenticate"
4. Complétez la connexion dans le navigateur qui s'ouvre

**Erreurs "Unauthorized"**

Assurez-vous de vous connecter avec un compte qui a accès à l'espace de travail Jira/Confluence.

**Impossible de trouver votre espace de travail**

La première fois que vous utilisez les commandes Jira ou Confluence, vous devrez peut-être sélectionner à quel site Atlassian vous connecter.

---

*Créé par Sterling Chin*
