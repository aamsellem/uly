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
| `POST` | `/command/{cmd}` | Exécuter n'importe quelle commande slash |
| `POST` | `/raw` | Envoyer une commande brute (message ou slash) |
| `GET` | `/health` | Vérifier que le service fonctionne |

---

### `/ask` — Envoyer un message

```bash
curl -X POST https://votre-tunnel.trycloudflare.com/ask \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Quel est mon état actuel?"}'
```

---

### `/command/{cmd}` — Exécuter une commande slash

**N'importe quelle commande Claude Code :**

```bash
# Briefing
curl -X POST https://votre-tunnel.trycloudflare.com/command/uly \
  -H "Authorization: Bearer VOTRE_TOKEN"

# Commit avec message
curl -X POST https://votre-tunnel.trycloudflare.com/command/commit \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"args": "-m \"feat: nouvelle fonctionnalité\""}'

# Update
curl -X POST https://votre-tunnel.trycloudflare.com/command/update \
  -H "Authorization: Bearer VOTRE_TOKEN"

# Help
curl -X POST https://votre-tunnel.trycloudflare.com/command/help \
  -H "Authorization: Bearer VOTRE_TOKEN"

# Report
curl -X POST https://votre-tunnel.trycloudflare.com/command/report \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

**Paramètres optionnels :**
```json
{
  "args": "arguments supplémentaires",
  "timeout": 180
}
```

---

### `/raw` — Commande brute

Envoie **exactement** ce que tu veux à Claude Code :

```bash
# Une commande slash
curl -X POST https://votre-tunnel.trycloudflare.com/raw \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "/commit -m \"fix: correction bug\""}'

# Une question
curl -X POST https://votre-tunnel.trycloudflare.com/raw \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Liste mes tâches en retard"}'

# Une instruction
curl -X POST https://votre-tunnel.trycloudflare.com/raw \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Crée un fichier content/idees.md avec mes dernières idées"}'
```

---

### Paramètres communs

| Paramètre | Type | Description |
|-----------|------|-------------|
| `message` | string | Le message/commande (requis pour `/ask` et `/raw`) |
| `session_id` | string | ID de session pour reprendre une conversation |
| `args` | string | Arguments pour `/command/{cmd}` |
| `timeout` | int | Timeout en secondes (défaut: 120-180) |

---

## Sessions (conversations continues)

Pour avoir une conversation avec plusieurs échanges (comme un chat), utilise `session_id` :

**1. Premier message — pas de session_id**
```bash
curl -X POST https://tunnel.example.com/ask \
  -H "Authorization: Bearer TOKEN" \
  -d '{"message": "Salut, je travaille sur le projet X"}'
```

**Réponse :**
```json
{
  "response": "Salut ! Qu'est-ce que tu veux faire sur le projet X ?",
  "session_id": "a1b2c3d4",
  "duration_ms": 1500
}
```

**2. Message suivant — avec session_id**
```bash
curl -X POST https://tunnel.example.com/ask \
  -H "Authorization: Bearer TOKEN" \
  -d '{"message": "Ajoute une tâche pour finir la doc", "session_id": "a1b2c3d4"}'
```

ULY se souvient du contexte (projet X) grâce au `session_id`.

**Dans N8N :**
1. Premier nœud : envoie le message, stocke `session_id` de la réponse
2. Nœuds suivants : passe le `session_id` dans les requêtes

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

### IP Whitelist (optionnel)

Restreindre l'accès à certaines IPs uniquement (ex: ton serveur N8N) :

```bash
# Dans .env
ULY_IP_WHITELIST=192.168.1.100,10.0.0.50
```

- **Vide** = tout le monde peut accéder (avec le token)
- **Défini** = seules ces IPs peuvent accéder

L'API gère automatiquement les headers Cloudflare (`CF-Connecting-IP`) pour récupérer l'IP réelle.

**Trouver l'IP de ton serveur N8N :**
```bash
# Sur le serveur N8N
curl ifconfig.me
```

### Bonnes pratiques

- **Ne partagez jamais votre token**
- **Le tunnel force HTTPS** — Connexion chiffrée
- **Rate limiting** — 100 requêtes/minute max
- **IP Whitelist** — Active-la si tu connais les IPs sources
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
