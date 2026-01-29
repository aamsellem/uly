# Intégrations ULY

Ce répertoire contient les intégrations qui étendent les capacités de ULY. Chaque intégration connecte ULY à des outils et services externes.

---

## Intégrations Disponibles

| Intégration | Description | Configuration |
|-------------|-------------|---------------|
| [Google Workspace](./google-workspace/) | Gmail, Calendar, Drive | `./.uly/integrations/google-workspace/setup.sh` |
| [Atlassian](./atlassian/) | Jira, Confluence | `./.uly/integrations/atlassian/setup.sh` |
| [Parallel Search](./parallel-search/) | Recherche web | `./.uly/integrations/parallel-search/setup.sh` |
| [Slack](./slack/) | Messagerie d'équipe, recherche | `./.uly/integrations/slack/setup.sh` |
| [Telegram](./telegram/) | Assistant IA mobile via Telegram | `./.uly/integrations/telegram/setup.sh` |

---

## Comment Installer une Intégration

1. Parcourez les dossiers dans ce répertoire (`.uly/integrations/`)
2. Lisez le README de l'intégration pour voir ce qu'elle fait
3. Lancez son script de configuration : `./.uly/integrations/<nom>/setup.sh`
4. Redémarrez ULY et c'est parti !

Ou demandez simplement à ULY : *"Aide-moi à configurer l'intégration Notion"*

---

## Demander une Intégration

Vous voulez que ULY se connecte à un outil qui n'est pas encore là ?

**Option 1 :** Ouvrez une issue sur GitHub décrivant ce que vous aimeriez

**Option 2 :** Ajoutez-le à `.uly/integrations/REQUESTS.md` et soumettez une PR

**Option 3 :** Construisez-le vous-même ! Voir "Contribuer" ci-dessous.

---

## Contribuer une Intégration

Nous adorons les contributions de la communauté ! Si vous avez configuré ULY avec un outil que vous aimez, partagez-le avec les autres.

### Structure d'Intégration

Chaque intégration doit avoir son propre dossier :

```
.uly/integrations/
└── votre-integration/
    ├── README.md      # Documentation (sections requises ci-dessous)
    ├── setup.sh       # Script de configuration (patterns requis ci-dessous)
    └── ...            # Tous fichiers supplémentaires nécessaires
```

### Exigences du Script de Configuration

Votre `setup.sh` doit suivre ces patterns pour la cohérence :

**1. En-tête standard et couleurs :**
```bash
#!/bin/bash
# Script de Configuration MCP de Votre Intégration
# Brève description

set -e

# Couleurs pour la sortie (utilisez ces définitions exactes)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Pas de Couleur
```

**2. Format de bannière :**
```bash
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuration Votre Intégration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
```

**3. Vérifier Claude Code :**
```bash
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installé${NC}"
else
    echo -e "${RED}✗ Claude Code non trouvé${NC}"
    echo "Installer avec : npm install -g @anthropic-ai/claude-code"
    exit 1
fi
```

**4. Sélection de portée (REQUIS) :**

Les utilisateurs doivent choisir si le MCP est disponible globalement ou par projet :

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

Puis utilisez `$SCOPE_FLAG` dans votre commande `claude mcp add` :
```bash
claude mcp add votre-integration $SCOPE_FLAG ...
```

**5. Supprimer l'existant avant d'ajouter :**
```bash
claude mcp remove votre-integration 2>/dev/null || true
```

**6. Terminer avec une bannière "Configuration Terminée" et des commandes exemples :**
```bash
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Configuration Terminée !${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Essayez ces commandes avec ULY :"
echo -e "  ${YELLOW}\"Commande exemple 1\"${NC}"
echo -e "  ${YELLOW}\"Commande exemple 2\"${NC}"
echo ""
echo -e "${GREEN}Vous êtes prêt !${NC}"
echo ""
```

### Exigences du README

Votre README.md doit inclure ces sections :

| Section | Description |
|---------|-------------|
| **Ce Que Ça Fait** | Liste à puces des capacités |
| **Pour Qui C'est** | Public cible |
| **Prérequis** | Comptes requis, permissions, etc. |
| **Configuration** | Bloc de code avec la commande de configuration |
| **Essayez** | Commandes exemples à tester |
| **Zone de Danger** | Quelles actions peuvent affecter les autres ou ne peuvent pas être annulées (voir ci-dessous) |
| **Dépannage** | Problèmes courants et solutions |

Terminer avec une ligne d'attribution : `*Contribué par Votre Nom*`

### Section Zone de Danger (Requis)

Chaque README d'intégration doit inclure une section "Zone de Danger" qui documente clairement :
- **Quelles actions d'écriture/envoi/suppression sont possibles**
- **Qui pourrait être affecté** (membres de l'équipe, contacts externes, etc.)
- **Ce qui ne peut pas être annulé**

Cela aide les utilisateurs à comprendre les risques avant d'activer une intégration.

**Exemple de section Zone de Danger :**

```markdown
## Zone de Danger

Cette intégration peut effectuer des actions qui affectent les autres ou ne peuvent pas être facilement annulées :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Envoyer des emails | Élevé | Les destinataires le voient immédiatement |
| Supprimer des fichiers | Élevé | La perte de données peut être permanente |
| Modifier le calendrier | Moyen | Les autres participants sont notifiés |
| Lire des messages | Faible | Pas d'impact externe |

ULY confirmera toujours avant d'effectuer des actions à haut risque.
```

### Exemple de README.md

```markdown
# Intégration Notion

Connectez ULY à votre espace de travail Notion.

## Ce Que Ça Fait

- **Rechercher** - Trouver des pages et bases de données
- **Lire** - Voir le contenu des pages
- **Créer** - Faire de nouvelles pages
- **Mettre à jour** - Éditer des pages existantes

## Pour Qui C'est

Toute personne qui utilise Notion pour les notes, wikis, ou gestion de projet.

## Prérequis

- Un compte Notion
- Un token d'intégration Notion (le script de configuration vous guidera)

## Configuration

\`\`\`bash
./.uly/integrations/notion/setup.sh
\`\`\`

## Essayez

Après la configuration, essayez ces commandes avec ULY :

- "Cherche dans mon Notion les notes de réunion"
- "Qu'est-ce qu'il y a dans mon tracker de projet ?"
- "Crée une nouvelle page appelée 'Idées'"

## Dépannage

**Impossible de trouver des pages**
Assurez-vous d'avoir partagé les pages avec votre intégration Notion.

**Erreurs de token**
Relancez le script de configuration et copiez un nouveau token.

---

*Contribué par Votre Nom*
```

### Autres Directives

1. **Rendez-le facile** - Supposez que l'utilisateur n'est pas technique. Utilisez des couleurs, des invites claires, et des messages d'erreur utiles.

2. **Soyez sûr** - Ne stockez jamais d'identifiants en texte clair. Utilisez des variables d'environnement ou la config MCP de Claude.

3. **Testez-le** - Assurez-vous que ça fonctionne sur une installation fraîche.

4. **Mettez à jour le tableau** - Ajoutez votre intégration au tableau "Intégrations Disponibles" en haut de ce fichier.

---

## Idées d'Intégrations

Voici quelques intégrations que nous aimerions voir :

- **Notion** - Notes, wikis, bases de données
- **Linear** - Suivi des issues
- **Figma** - Fichiers de design
- **Airtable** - Feuilles de calcul et bases de données
- **HubSpot** - CRM
- **Todoist** - Gestion de tâches
- **Obsidian** - Notes markdown locales
- **Raycast** - Actions rapides
- **Granola** - Notes de réunion

Vous voulez en construire une ? Choisissez dans la liste ou ajoutez la vôtre !

---

*Ce répertoire d'intégrations fait partie de [ULY](https://github.com/SterlingChin/marvin-template), le modèle de Chef de Cabinet IA.*
