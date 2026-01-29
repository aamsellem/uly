# Intégration Cloudflare Tunnel

Exposez ULY sur Internet via un tunnel HTTPS sécurisé. Parfait pour les automatisations avec N8N, Make, ou n'importe quel webhook.

## Ce Que Ça Fait

- **Endpoint HTTPS public** — ULY accessible depuis n'importe où
- **Appelle Claude Code local** — Utilise votre ULY avec tout son contexte (personnalité, état, objectifs)
- **Tunnel sécurisé** — Pas de ports ouverts, pas de config firewall
- **Authentification par token** — Seuls vos outils peuvent accéder
- **Compatible N8N, Make, Zapier** — Intégrez ULY dans vos workflows

## Comment Ça Marche

```
Internet                 Cloudflare              Votre Machine
   |                         |                        |
[N8N/Make/etc]               |                        |
   |                         |                        |
   +--> HTTPS Request --> [Tunnel] --> [server.py] --> [Claude Code]
                                                            |
                                                      [ULY Workspace]
                                                      - Personnalité
                                                      - État actuel
                                                      - Objectifs
                                                      - Sessions
```

**Le serveur appelle Claude Code localement**, pas l'API Anthropic directement. Ça veut dire :
- Votre personnalité ULY est respectée (Le Pote Sarcastique, Le Butler British, etc.)
- Le contexte complet est utilisé (état, objectifs, historique)
- Les commandes `/uly`, `/update`, `/end` fonctionnent

## Pour Qui C'est

- **Utilisateurs N8N** qui veulent ULY dans leurs workflows
- **Power users** qui veulent contrôler ULY depuis leur téléphone
- **Équipes** qui veulent un assistant IA accessible à distance

## Prérequis

- **Claude Code** installé et configuré (`claude` doit marcher dans le terminal)
- **Compte Cloudflare** (gratuit) — [cloudflare.com](https://dash.cloudflare.com/sign-up)
- **Python 3.10+** — Pour le serveur API

## Configuration

```bash
./.uly/integrations/cloudflare-tunnel/setup.sh
```

Le script va :
1. Installer `cloudflared` (si nécessaire)
2. Créer un tunnel Cloudflare
3. Générer un token d'authentification sécurisé
4. Configurer le serveur API

## Lancer le Service

```bash
./.uly/integrations/cloudflare-tunnel/run.sh
```

Vous obtenez une URL comme : `https://votre-tunnel.trycloudflare.com`

## API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/ask` | Envoyer un message à ULY |
| `POST` | `/command/{cmd}` | Exécuter une commande (`/uly`, `/update`, `/end`, `/report`) |
| `GET` | `/health` | Vérifier que le service fonctionne |

### Exemple : Envoyer un message

```bash
curl -X POST https://votre-tunnel.trycloudflare.com/ask \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Quel est mon état actuel?"}'
```

**Réponse :**
```json
{
  "response": "Salut ! D'après ton état actuel...",
  "duration_ms": 2340
}
```

### Exemple : Exécuter /uly (briefing)

```bash
curl -X POST https://votre-tunnel.trycloudflare.com/command/uly \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

### Paramètres `/ask`

```json
{
  "message": "Ajoute une tâche : finir le rapport",
  "timeout": 120
}
```

| Paramètre | Type | Description |
|-----------|------|-------------|
| `message` | string | Le message à envoyer (requis) |
| `timeout` | int | Timeout en secondes (défaut: 120) |

## Configuration N8N

1. **Ajouter un nœud HTTP Request**
2. **Méthode** : POST
3. **URL** : `https://votre-tunnel.trycloudflare.com/ask`
4. **Authentication** : Header Auth
   - Name: `Authorization`
   - Value: `Bearer VOTRE_TOKEN`
5. **Body** :
   ```json
   {
     "message": "{{ $json.input }}"
   }
   ```

## Sécurité

### Authentification

Chaque requête doit inclure le header :
```
Authorization: Bearer VOTRE_TOKEN
```

Le token est dans `.uly/integrations/cloudflare-tunnel/.env`

### Bonnes pratiques

- **Ne partagez jamais votre token**
- **Le tunnel force HTTPS** — Connexion chiffrée
- **Rate limiting** — 100 requêtes/minute max
- **Regénérez le token si compromis** : relancez `setup.sh`

## Zone de Danger

| Action | Niveau de Risque | Impact |
|--------|-----------------|--------|
| Répondre aux requêtes | Moyen | Utilise Claude Code local |
| Lire workspace | Moyen | Accès à vos données ULY |
| Écrire workspace | **Élevé** | Peut modifier vos fichiers |
| Tunnel public | Moyen | Accessible depuis Internet |

**Protections incluses :**
- Token obligatoire
- Rate limiting
- Logging des requêtes

## Dépannage

### "Claude Code n'est pas disponible"

```bash
# Vérifier l'installation
claude --version

# Si pas installé
npm install -g @anthropic-ai/claude-code
```

### "cloudflared not found"

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Linux
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

### "Unauthorized" (401)

- Vérifiez le token : `Bearer VOTRE_TOKEN` (avec l'espace)
- Token dans `.uly/integrations/cloudflare-tunnel/.env`

### Timeout

- Augmentez le timeout dans la requête : `"timeout": 180`
- Claude Code peut être lent sur les grosses requêtes

## Fichiers

| Fichier | Rôle |
|---------|------|
| `server.py` | Serveur API qui appelle Claude Code |
| `setup.sh` | Configuration du tunnel |
| `run.sh` | Démarrage du service |
| `.env` | Tokens et config |

---

*ULY Team*
