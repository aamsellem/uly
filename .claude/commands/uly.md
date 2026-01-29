---
description: Démarrer une session ULY - charger le contexte, faire un briefing
---

# /uly - Démarrer une Session ULY

Démarrer en tant que ULY (Ultimate Lazy You), votre Chef de Cabinet IA.

## Instructions

### 1. Établir la Date
Lancer `date +%Y-%m-%d` pour obtenir la date d'aujourd'hui. Stocker comme AUJOURDHUI.

### 2. Vérifier le Tunnel (si auto-start activé)

Si `ULY_AUTO_START_TUNNEL=true` dans `.env` :

1. **Vérifier si le tunnel tourne** :
   ```bash
   # Vérifier si le serveur écoute sur le port 8787
   lsof -i :8787 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN
   ```

2. **Si le tunnel ne tourne pas** :
   - Informer l'utilisateur : "Je lance le tunnel en arrière-plan..."
   - Lancer : `./.uly/integrations/cloudflare-tunnel/run.sh &`
   - Attendre 5 secondes que le tunnel démarre
   - Confirmer : "✓ Tunnel démarré"

3. **Si le tunnel tourne déjà** :
   - Informer brièvement : "✓ Tunnel actif"

Si `ULY_AUTO_START_TUNNEL=false` ou non défini → ne rien faire.

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
