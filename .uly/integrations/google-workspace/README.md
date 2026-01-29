# Intégration Google Workspace

Connectez ULY à votre compte Google pour l'accès aux emails, calendrier et fichiers.

## Ce Que Ça Fait

- **Gmail** - Lire, rechercher et envoyer des emails
- **Calendar** - Voir les événements, vérifier la disponibilité, créer des réunions
- **Drive** - Rechercher et lire des documents, feuilles de calcul, présentations

## Pour Qui C'est

Toute personne qui utilise Google Workspace (Gmail, Google Calendar, Google Drive) pour le travail ou l'usage personnel.

## Prérequis

- Un compte Google
- Le secret client OAuth (demandez à Sterling ou consultez les instructions de configuration)

## Configuration

```bash
./integrations/google-workspace/setup.sh
```

Le script va :
1. Vérifier que vous avez les outils requis installés
2. Demander le secret client OAuth
3. Configurer le serveur MCP
4. Ouvrir un navigateur pour vous connecter avec votre compte Google

## Essayez

Après la configuration, essayez ces commandes avec ULY :

- "Qu'est-ce que j'ai dans mon calendrier aujourd'hui ?"
- "Montre-moi mes emails non lus"
- "Cherche dans mon Drive les rapports trimestriels"
- "Quelles réunions ai-je cette semaine ?"
- "Envoie un email à [personne] au sujet de [sujet]"

## Zone de Danger

Cette intégration peut effectuer des actions qui affectent les autres ou ne peuvent pas être facilement annulées :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Envoyer des emails | **Élevé** | Les destinataires le voient immédiatement |
| Créer/modifier des événements de calendrier | **Moyen** | Les autres participants sont notifiés |
| Supprimer des emails | **Moyen** | Peut être récupéré depuis la corbeille |
| Lire emails, calendrier, Drive | Faible | Pas d'impact externe |

**ULY confirmera toujours avant d'envoyer des emails ou de modifier des événements de calendrier.**

## Dépannage

**"Client secret is required"**
Vous avez besoin du secret client OAuth. Demandez à Sterling ou consultez la documentation du projet.

**Le navigateur ne s'ouvre pas pour la connexion**
Essayez de relancer le script de configuration, ou visitez manuellement l'URL affichée dans le terminal.

**Erreurs "Permission denied"**
Assurez-vous de vous connecter avec le bon compte Google et d'accorder toutes les permissions demandées.

---

*Créé par Sterling Chin*
