# Intégration Cloudflare Tunnel

Exposez ULY sur Internet via un tunnel HTTPS sécurisé. Parfait pour les automatisations avec N8N, Make, ou n'importe quel webhook.

## Ce Que Ca Fait

- **Endpoint HTTPS public** - ULY accessible depuis n'importe ou dans le monde
- **Tunnel securise** - Pas de ports ouverts, pas de config firewall, zero trust
- **API REST simple** - Envoyez des requetes, recevez des reponses de Claude
- **Authentification par token** - Seuls vos outils peuvent acceder
- **Compatible N8N, Make, Zapier** - Integrez ULY dans vos workflows d'automatisation

## Pour Qui C'est

- **Utilisateurs N8N** qui veulent integrer Claude dans leurs workflows
- **Developpeurs** qui construisent des automatisations avec des webhooks
- **Equipes** qui veulent un assistant IA accessible a distance
- **Power users** qui veulent controler ULY depuis leur telephone ou tablette

## Prerequis

- **Compte Cloudflare** (gratuit) - [cloudflare.com](https://dash.cloudflare.com/sign-up)
- **cloudflared** installe - Le CLI sera installe automatiquement si manquant
- **Python 3.10+** - Pour le serveur API
- **Cle API Anthropic** - `ANTHROPIC_API_KEY` dans votre environnement

## Configuration

```bash
./.uly/integrations/cloudflare-tunnel/setup.sh
```

Le script vous guidera a travers :
1. Installation de `cloudflared` (si necessaire)
2. Connexion a votre compte Cloudflare
3. Creation d'un tunnel nomme
4. Generation d'un token d'authentification securise
5. Configuration du serveur API local

## Lancer le Service

Apres la configuration :

```bash
./.uly/integrations/cloudflare-tunnel/run.sh
```

Cela demarre :
1. Le serveur API local (port 8787)
2. Le tunnel Cloudflare qui expose votre endpoint

Vous obtenez une URL comme : `https://votre-tunnel.trycloudflare.com`

## Utilisation avec N8N

### Endpoint disponible

| Methode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/ask` | Envoyer une question a Claude |
| GET | `/health` | Verifier que le service fonctionne |

### Exemple de requete

```bash
curl -X POST https://votre-tunnel.trycloudflare.com/ask \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Quel est mon etat actuel?"}'
```

### Configuration N8N

1. **Ajouter un noeud HTTP Request**
2. **Methode** : POST
3. **URL** : `https://votre-tunnel.trycloudflare.com/ask`
4. **Authentication** : Header Auth
   - Name: `Authorization`
   - Value: `Bearer VOTRE_TOKEN`
5. **Body** :
   ```json
   {
     "message": "Votre question ici"
   }
   ```

### Parametres avances

```json
{
  "message": "Analyse ce texte",
  "context": "Tu es un assistant specialise en marketing",
  "workspace_access": true,
  "max_tokens": 2048
}
```

| Parametre | Type | Description |
|-----------|------|-------------|
| `message` | string | La question ou instruction (requis) |
| `context` | string | Contexte supplementaire pour Claude |
| `workspace_access` | bool | Autoriser l'acces aux fichiers ULY (defaut: true) |
| `max_tokens` | int | Limite de tokens pour la reponse (defaut: 4096) |

## Securite

### Authentification

Chaque requete doit inclure le header `Authorization` :

```
Authorization: Bearer VOTRE_TOKEN
```

Le token est genere automatiquement lors de la configuration et sauvegarde dans `.env`.

### Bonnes pratiques

- **Ne partagez jamais votre token** - Traitez-le comme un mot de passe
- **Utilisez HTTPS uniquement** - Le tunnel Cloudflare force HTTPS
- **Limitez les IPs si possible** - Configurez Cloudflare Access pour plus de controle
- **Regenerez le token** si compromis : relancez `setup.sh`

### Cloudflare Access (optionnel)

Pour une securite renforcee, configurez Cloudflare Access :

1. Allez sur [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Applications > Add Application > Self-hosted
3. Ajoutez votre domaine de tunnel
4. Configurez les regles d'acces (email, IP, etc.)

## Zone de Danger

Cette integration expose ULY sur Internet :

| Action | Niveau de Risque | Qui Est Affecte |
|--------|-----------------|-----------------|
| Repondre aux requetes API | **Moyen** | Consomme vos credits Anthropic |
| Lire fichiers workspace | Moyen | Expose potentiellement des donnees sensibles |
| Ecrire fichiers workspace | **Eleve** | Peut modifier votre espace de travail |
| Tunnel public | Moyen | Accessible depuis Internet |

**Mesures de protection incluses :**
- Authentification obligatoire par token
- Rate limiting (100 requetes/minute)
- Logging de toutes les requetes
- Sandboxing des operations fichiers

## Depannage

### "cloudflared not found"

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Linux
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

### "Tunnel connection failed"

1. Verifiez votre connexion Internet
2. Reessayez `cloudflared tunnel login`
3. Supprimez et recreez le tunnel :
   ```bash
   cloudflared tunnel delete uly-tunnel
   ./.uly/integrations/cloudflare-tunnel/setup.sh
   ```

### "Unauthorized" (401)

- Verifiez que le token dans votre requete correspond a celui dans `.env`
- Assurez-vous du format : `Bearer VOTRE_TOKEN` (avec l'espace)

### "Service unavailable" (503)

- Le serveur API local n'est pas demarre
- Lancez : `./.uly/integrations/cloudflare-tunnel/run.sh`

### Le serveur demarre mais pas de reponses

- Verifiez que `ANTHROPIC_API_KEY` est defini
- Testez l'API localement : `curl http://localhost:8787/health`

## Fichiers

| Fichier | Role |
|---------|------|
| `server.py` | Serveur API FastAPI |
| `setup.sh` | Script de configuration |
| `run.sh` | Script de demarrage |
| `.env` | Configuration (tokens, etc.) |
| `config.yml` | Configuration du tunnel Cloudflare |

## Architecture

```
Internet                 Cloudflare              Votre Machine
   |                         |                        |
[N8N/Make/etc]               |                        |
   |                         |                        |
   +--> HTTPS Request --> [Tunnel] --> [server.py:8787]
                                              |
                                        [Claude API]
                                              |
                                        [ULY Workspace]
```

---

*Contribue par ULY Team*
