# Intégration Telegram

Connectez ULY à Telegram pour une expérience d'assistant IA complète sur mobile.

## Ce Que Ça Fait

- **Discuter avec ULY** - IA conversationnelle complète via Telegram
- **Lire/écrire des fichiers** - Accéder à votre espace de travail ULY de n'importe où
- **Récupérer des URLs** - Obtenir des transcriptions YouTube, posts Reddit, articles
- **Rechercher des fichiers** - Trouver du contenu dans vos notes et documents
- **Envoyer des fichiers** - Recevoir des documents en pièces jointes Telegram
- **Analyse d'images** - Envoyer des photos pour que Claude les analyse
- **Historique de conversation** - Le contexte persiste entre les messages

## Pour Qui C'est

Toute personne qui veut ULY accessible depuis son téléphone. Parfait pour :
- Capturer des idées en déplacement
- Recherches rapides de fichiers loin de votre bureau
- Envoyer des liens pour que ULY les traite et sauvegarde
- Workflows mobile-first

## Prérequis

- Python 3.10+
- Un compte Telegram
- Une clé API Anthropic (`ANTHROPIC_API_KEY` dans votre environnement)

## Configuration

```bash
./.uly/integrations/telegram/setup.sh
```

Le script vous guidera à travers :
1. La création d'un bot Telegram via BotFather
2. L'installation des dépendances Python
3. La configuration de votre token de bot
4. La configuration de l'autorisation utilisateur (optionnel)

## Lancer le Bot

Après la configuration, démarrez le bot :

```bash
./.uly/integrations/telegram/run.sh
```

Ou lancez directement :

```bash
cd .uly/integrations/telegram
source venv/bin/activate
python telegram_bot.py
```

**Conseil :** Lancez le bot dans un onglet terminal, une session tmux, ou comme processus de fond pour le garder disponible.

## Essayez

Après la configuration, envoyez un message à votre bot sur Telegram :

- "Qu'est-ce qu'il y a dans mon état actuel ?"
- "Cherche les notes de réunion de la semaine dernière"
- "Sauvegarde ça dans ma boîte de réception : [votre idée]"
- Envoyez un lien YouTube - "Résume cette vidéo"
- Envoyez une photo - "Qu'est-ce qu'il y a dans cette image ?"
- "Envoie-moi le fichier à content/notes.md"

## Commandes du Bot

| Commande | Ce Qu'elle Fait |
|----------|-----------------|
| `/start` | Introduction et capacités |
| `/help` | Afficher les commandes disponibles |
| `/clear` | Effacer l'historique de conversation |
| `/status` | Vérifier le statut du bot |
| `/save [sujet]` | Sauvegarder le résumé de conversation dans le journal de session |

## Configuration

### Variables d'Environnement

Définissez celles-ci dans `.env` ou votre environnement :

| Variable | Requis | Description |
|----------|--------|-------------|
| `TELEGRAM_BOT_TOKEN` | Oui | Token de bot de BotFather |
| `ANTHROPIC_API_KEY` | Oui | Votre clé API Anthropic |
| `TELEGRAM_ALLOWED_USERS` | Non | IDs utilisateur séparés par des virgules pour l'autorisation |

### Autorisation Utilisateur

Pour la sécurité, vous pouvez restreindre le bot à des utilisateurs Telegram spécifiques :

1. Envoyez un message à votre bot et lancez `/status` pour voir votre ID utilisateur
2. Ajoutez à `.env` : `TELEGRAM_ALLOWED_USERS=123456789`
3. Utilisateurs multiples : `TELEGRAM_ALLOWED_USERS=123456789,987654321`

Si non défini, le bot accepte les messages de n'importe qui (non recommandé pour la production).

## Zone de Danger

Cette intégration a accès à votre espace de travail ULY :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Écrire/écraser des fichiers | **Moyen** | Votre espace de travail local |
| Supprimer des fichiers | **Moyen** | Votre espace de travail local |
| Lire des fichiers | Faible | Pas d'impact externe |
| Récupérer des URLs | Faible | Pas d'impact externe |

**Considérations de sécurité :**
- Définissez `TELEGRAM_ALLOWED_USERS` pour restreindre qui peut utiliser votre bot
- Le token du bot donne un contrôle total - gardez-le secret
- Les fichiers ne sont accessibles que dans votre espace de travail ULY (sandboxé)

**ULY confirmera avant d'écraser des fichiers existants.**

## Dépannage

**"Unauthorized" en envoyant un message au bot**
- Vérifiez que votre ID utilisateur est dans `TELEGRAM_ALLOWED_USERS`
- Lancez `/status` pour vérifier votre ID utilisateur

**Le bot ne répond pas**
- Assurez-vous que le processus du bot est en cours d'exécution
- Vérifiez que `TELEGRAM_BOT_TOKEN` est correctement défini
- Vérifiez que `ANTHROPIC_API_KEY` est valide

**"Could not fetch transcript" pour YouTube**
- Certaines vidéos ont les transcriptions désactivées
- Essayez une autre vidéo pour vérifier que la fonctionnalité marche

**Erreurs Python au démarrage**
- Assurez-vous d'utiliser Python 3.10+
- Activez l'environnement virtuel : `source venv/bin/activate`
- Réinstallez les dépendances : `pip install -r requirements.txt`

## Architecture

Cette intégration tourne comme un processus Python autonome (pas un serveur MCP). Elle :
- Utilise la librairie `python-telegram-bot` pour l'API Telegram
- Appelle Claude directement via le SDK Anthropic avec l'utilisation d'outils
- Stocke l'historique de conversation dans SQLite (`telegram.db`)
- A accès à votre espace de travail ULY pour les opérations sur fichiers

## Fichiers

| Fichier | But |
|---------|-----|
| `telegram_bot.py` | Bot principal avec intégration Claude |
| `content_fetcher.py` | Extraction de contenu d'URL (YouTube, Reddit, etc.) |
| `requirements.txt` | Dépendances Python |
| `setup.sh` | Script d'installation |
| `run.sh` | Script de démarrage |

---

*Contribué par Sterling Chin*
