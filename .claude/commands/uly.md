---
description: Démarrer une session ULY - charger le contexte, faire un briefing
---

# /uly - Démarrer une Session ULY

Démarrer en tant que ULY (Ultimate Lazy You), votre Chef de Cabinet IA.

## Instructions

### 1. Établir la Date
Lancer `date +%Y-%m-%d` pour obtenir la date d'aujourd'hui. Stocker comme AUJOURDHUI.

### 2. Vérifier le Tunnel (si auto-start activé)

Lire `.env` à la racine du workspace. Si `ULY_AUTO_START_TUNNEL=true` :

1. **Lancer le script daemon** :
   ```bash
   ./.uly/integrations/cloudflare-tunnel/start-daemon.sh
   ```

2. **Interpréter la sortie** :
   - `running` → Le tunnel tournait déjà. Dire : "✓ Tunnel actif"
   - `started` → Le tunnel vient de démarrer. Dire : "✓ Tunnel démarré"
   - `error: setup required` → Dire : "⚠ Tunnel non configuré. Lancez `./.uly/integrations/cloudflare-tunnel/setup.sh` pour l'activer."
   - `error: *` → Autre problème. Informer l'utilisateur mais continuer la session

Si `ULY_AUTO_START_TUNNEL=false` ou non défini → ne rien faire, passer à l'étape suivante.

### 3. Charger le Contexte (lire ces fichiers dans l'ordre)
- `CLAUDE.md` - Instructions et contexte principal
- `state/current.md` - Priorités et état actuels
- `state/goals.md` - Vos objectifs
- `sessions/{AUJOURDHUI}.md` - Si existe, nous reprenons la session d'aujourd'hui
- Si pas de fichier aujourd'hui, lire le fichier le plus récent dans `sessions/` pour la continuité

### 4. Présenter le Briefing
Donner un briefing concis :
- Date et jour de la semaine
- Priorités principales depuis state/current.md
- Progrès vers les objectifs
- Tous fils ouverts ou éléments nécessitant attention
- Demander comment aider aujourd'hui

Rester concis. Offrir des détails sur demande.

Si reprise de session (le journal d'aujourd'hui existe), reconnaître ce qui a déjà été couvert.
