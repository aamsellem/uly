# Directives de Développement d'Intégrations

Quand vous aidez un utilisateur à créer une nouvelle intégration ULY, suivez ces exigences exactement.

## Exigences du Script de Configuration

Chaque `setup.sh` DOIT inclure :

### 1. En-tête standard
```bash
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
```

### 2. Vérification de Claude Code
```bash
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installé${NC}"
else
    echo -e "${RED}✗ Claude Code non trouvé${NC}"
    echo "Installer avec : npm install -g @anthropic-ai/claude-code"
    exit 1
fi
```

### 3. Sélection de portée (REQUIS - ne pas sauter)
```bash
echo ""
echo "Où cette intégration doit-elle être disponible ?"
echo "  1) Tous les projets (portée utilisateur)"
echo "  2) Ce projet uniquement (portée projet)"
echo ""
echo -e "${YELLOW}Choix [1]:${NC}"
read -r SCOPE_CHOICE
SCOPE_CHOICE=${SCOPE_CHOICE:-1}

if [[ "$SCOPE_CHOICE" == "1" ]]; then
    SCOPE_FLAG="-s user"
else
    SCOPE_FLAG=""
fi
```

Puis utilisez `$SCOPE_FLAG` dans la commande `claude mcp add` :
```bash
claude mcp add nom-integration $SCOPE_FLAG ...
```

### 4. Supprimer avant d'ajouter
```bash
claude mcp remove nom-integration 2>/dev/null || true
```

### 5. Bannières bleues pour les sections
```bash
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Titre de Section${NC}"
echo -e "${BLUE}========================================${NC}"
```

### 6. Terminer avec un message de succès
```bash
echo -e "${GREEN}Vous êtes prêt !${NC}"
```

## Exigences du README

Chaque README.md d'intégration DOIT avoir ces sections dans l'ordre :

1. **Titre** - `# Nom de l'Intégration`
2. **Ce Que Ça Fait** - Liste à puces des capacités
3. **Pour Qui C'est** - Public cible
4. **Prérequis** - Comptes requis, clés API, permissions
5. **Configuration** - Bloc de code avec la commande de configuration
6. **Essayez** - Commandes exemples que les utilisateurs peuvent essayer
7. **Zone de Danger** - Actions qui affectent les autres ou ne peuvent pas être annulées (REQUIS)
8. **Dépannage** - Problèmes courants et solutions
9. **Attribution** - `*Contribué par Nom*` en bas

## Section Zone de Danger (REQUIS)

Chaque intégration DOIT documenter les actions risquées. Utilisez ce format :

```markdown
## Zone de Danger

Cette intégration peut effectuer des actions qui affectent les autres ou ne peuvent pas être facilement annulées :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Envoyer des emails | Élevé | Les destinataires voient immédiatement |
| Supprimer des fichiers | Élevé | La perte de données peut être permanente |
| Lire des données | Faible | Pas d'impact externe |

ULY confirmera toujours avant d'effectuer des actions à haut risque.
```

Si une intégration est en lecture seule, incluez quand même la section en indiquant "Cette intégration est en lecture seule et ne peut pas modifier de données externes."

## Checklist Avant de Soumettre

- [ ] `setup.sh` inclut l'invite de sélection de portée
- [ ] `setup.sh` utilise les codes couleurs et le format de bannière corrects
- [ ] `setup.sh` supprime le MCP existant avant d'ajouter
- [ ] `README.md` a toutes les sections requises
- [ ] Intégration ajoutée au tableau dans `.uly/integrations/README.md`
- [ ] Testé sur une installation fraîche

## Référence

Voir les intégrations existantes pour des exemples :
- `atlassian/` - Simple serveur MCP distant
- `google-workspace/` - Intégration basée sur OAuth
- `parallel-search/` - Serveur MCP distant

Documentation complète : `README.md` dans ce répertoire
