<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-Powered-blueviolet?style=for-the-badge&logo=anthropic" alt="Claude Code Powered">
  <img src="https://img.shields.io/badge/100%25-Local-green?style=for-the-badge" alt="100% Local">
  <img src="https://img.shields.io/badge/Privacy-First-blue?style=for-the-badge" alt="Privacy First">
</p>

<h1 align="center">ULY</h1>

<p align="center">
  <strong>L'assistant IA qui vous connaît vraiment.</strong><br>
  <em>Mémoire persistante • Personnalités uniques • Automatisations puissantes</em>
</p>

<p align="center">
  <a href="#-démarrage-en-30-secondes">Démarrage rapide</a> •
  <a href="#-personnalités">Personnalités</a> •
  <a href="#-automatisations">Automatisations</a> •
  <a href="#-intégrations">Intégrations</a>
</p>

---

## Le problème

Vous utilisez ChatGPT, Claude, ou d'autres IA. Chaque conversation repart de zéro. Vous répétez sans cesse le contexte. L'IA ne sait pas qui vous êtes, ce que vous faites, vos objectifs.

**C'est épuisant.**

## La solution : ULY

ULY est un assistant IA qui **ne vous oublie jamais**.

- 🧠 **Mémoire persistante** — Il se souvient de tout, session après session
- 🎭 **Personnalité au choix** — Du pote sarcastique au butler british, choisissez votre style
- 🎯 **Suivi d'objectifs** — Il track vos progrès et vous rappelle ce qui compte
- 🔌 **Automatisable** — Connectez-le à N8N, Make, Zapier via une API sécurisée
- 🏠 **100% local** — Vos données restent chez vous, pas sur un cloud

---

## ⚡ Démarrage en 30 secondes

```bash
# 1. Cloner
git clone https://github.com/aamsellem/uly.git && cd uly

# 2. Lancer Claude Code
claude

# 3. Dire bonjour
> Aide-moi à configurer ULY
```

**C'est tout.** ULY vous guide pour le reste.

---

## 🎭 Personnalités

À l'onboarding, choisissez la personnalité qui vous correspond :

| Personnalité | Style | Exemple |
|-------------|-------|---------|
| 🍻 **Le Pote Sarcastique** | Loyal mais moqueur, te chambre gentiment | *"Ah, cette tâche est en retard depuis 6 jours. Tu attends qu'elle se fasse toute seule ?"* |
| 🎩 **Le Butler British** | Pince-sans-rire, politesse exagérée | *"Monsieur a 12 tâches en retard. Dois-je préparer un communiqué de crise ?"* |
| 🏈 **Le Coach Sportif** | Motivateur à fond, énergie permanente | *"ALLEZ ! 3 tâches ce matin, t'es chaud ? On démolit ça !"* |
| 🤖 **Le Robot Émotif** | Curieux, naïf, essaie de comprendre | *"Tu repousses cette tâche depuis 4 jours. Est-ce ce que vous appelez... procrastiner ?"* |
| 📋 **Le Stagiaire Enthousiaste** | Veut bien faire, maladroit, attachant | *"J'ai trouvé 7 trucs urgents ! Enfin je crois. C'est bien ça urgent ? Désolé."* |
| 🧙 **Le Vieux Sage** | Blasé mais bienveillant, a tout vu | *"Encore une urgence de dernière minute. Le monde ne change pas."* |
| 🔮 **La Sorcière Sage Fatiguée** | Mystique blasée, lit dans les deadlines | *"Les astres avaient prévenu que cette deadline arrivait... Mercure rétrograde n'excuse pas tout."* |
| ⚔️ **Le Narrateur Épique** | Transforme ton quotidien en aventure | *"Le héros fait face à son destin : 4 tâches l'attendent. Saura-t-il triompher ?"* |
| 🐱 **Le Chat d'Internet** | Capricieux, condescendant | *"Tu veux un rappel ? ...Bon, d'accord. Mais c'est bien parce que c'est toi."* |

**La personnalité change le ton, pas l'utilité.** ULY reste efficace quel que soit le style.

---

## 🔄 Automatisations

### ULY accessible depuis n'importe où

Exposez ULY via un tunnel Cloudflare sécurisé :

```bash
./.uly/integrations/cloudflare-tunnel/setup.sh
```

Vous obtenez une **URL HTTPS publique** pour appeler ULY depuis :
- **N8N** — Intégrez ULY dans vos workflows
- **Make/Zapier** — Automatisez avec vos apps préférées
- **Votre téléphone** — Shortcuts iOS, Tasker Android
- **Slack/Discord** — Créez un bot qui appelle ULY

### Exemple N8N

```
[Webhook] → [HTTP Request: POST /ask] → [Slack: Envoyer réponse]
                    ↓
            ULY répond avec tout
            son contexte et sa
            personnalité
```

### API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /ask` | Envoyer un message à ULY |
| `GET /pending` | Tâches actives en attente de retour (idéal pour N8N) |
| `POST /command/{cmd}` | Exécuter une commande (`/uly`, `/update`, `/commit`...) |
| `POST /raw` | Envoyer une commande brute |
| `GET /health` | Vérifier que le service tourne |

**Sécurisé par défaut** : Token d'authentification + IP whitelist optionnelle.

### Relances automatiques

ULY peut vous relancer sur vos projets en cours via `/pending` :

```
state/current.md
└── ## En Attente de Retour
    ├── ### Actif      ← Relance automatique
    └── ### En pause   ← Pas de relance
```

Configurez un workflow N8N : `Schedule → GET /pending → if has_pending → Slack/Telegram`

---

## 📅 Workflow quotidien

```
☀️ Matin                    🌤️ Journée                   🌙 Soir
   │                            │                           │
   └─→ /uly                     └─→ Parlez naturellement    └─→ /end
       "Briefing du jour"           "Ajoute une tâche..."       "Résumé + sauvegarde"
       Priorités, deadlines         "Sur quoi me concentrer?"
       Progrès sur objectifs        /update (sauvegarde rapide)
```

---

## 🔗 Intégrations

Connectez ULY à vos outils en une commande :

| Service | Capacités | Setup |
|---------|-----------|-------|
| **Google Workspace** | Gmail, Calendar, Drive | `./.uly/integrations/google-workspace/setup.sh` |
| **Microsoft 365** | Outlook, Teams, OneDrive | `./.uly/integrations/ms365/setup.sh` |
| **Atlassian** | Jira, Confluence | `./.uly/integrations/atlassian/setup.sh` |
| **Notion** | Pages, bases de données | `./.uly/integrations/notion/setup.sh` |
| **Slack** | Messages, recherche | `./.uly/integrations/slack/setup.sh` |
| **Cloudflare Tunnel** | API externe sécurisée | `./.uly/integrations/cloudflare-tunnel/setup.sh` |

---

## 🗂️ Structure

```
~/uly/
├── CLAUDE.md        # Votre profil, personnalité, préférences
├── state/
│   ├── current.md   # Priorités actuelles
│   └── goals.md     # Objectifs pro & perso
├── sessions/        # Historique des conversations
├── content/         # Notes, idées, contenus
├── skills/          # Capacités ULY
└── .uly/
    ├── commands/    # Commandes slash
    └── integrations/# Connexions aux services
```

**Tout est local. Tout est en Markdown. Tout vous appartient.**

---

## 💡 Ce qui rend ULY différent

### 1. Il ne dit pas oui à tout

ULY est un **partenaire de réflexion**, pas un béni-oui-oui :
- Il pose les bonnes questions
- Il challenge vos hypothèses
- Il identifie les angles morts
- Il vous aide à prendre de meilleures décisions

### 2. Il a de la personnalité

Les autres IA sont génériques. ULY a du caractère. Choisissez un style qui vous motive (ou vous fait rire).

### 3. Il s'intègre partout

Pas juste un chatbot. Une **API complète** que vous pouvez appeler depuis vos workflows, vos scripts, vos automatisations.

### 4. Vos données restent vôtres

Pas de cloud, pas de compte, pas de tracking. Tout tourne en local avec Claude Code.

---

## 🚀 Cas d'usage

**Freelance / Entrepreneur**
> ULY track mes projets clients, me rappelle les deadlines, et me fait un debrief hebdo automatique.

**Développeur**
> J'ai connecté ULY à mon N8N. Quand je reçois un email important, ULY l'analyse et crée une tâche Jira.

**Manager**
> ULY m'aide à préparer mes 1:1, se souvient du contexte de chaque personne de mon équipe.

**Créatif**
> Je balance mes idées à ULY toute la journée. Il organise, fait des connexions, et me ressort les bonnes idées au bon moment.

---

## 📖 Commandes

| Commande | Action |
|----------|--------|
| `/uly` | Démarrer avec un briefing personnalisé |
| `/end` | Terminer la session et tout sauvegarder |
| `/update` | Sauvegarde rapide en cours de session |
| `/pending` | Relancer sur les projets actifs (N8N) |
| `/report` | Générer un résumé hebdomadaire |
| `/commit` | Commiter les changements dans git |
| `/sync` | Mettre à jour ULY depuis le template |
| `/help` | Voir toutes les options disponibles |

---

## 🤝 Contribuer

Les contributions sont les bienvenues !

- **Nouvelles intégrations** → Voir `.uly/integrations/CLAUDE.md`
- **Nouvelles personnalités** → Proposez les vôtres
- **Améliorations** → Issues et PRs bienvenues

---

## 📜 Crédits

Inspiré par [MARVIN](https://github.com/SterlingChin/marvin-template) de Sterling Chin.

---

<p align="center">
  <strong>Prêt à avoir un assistant qui vous connaît vraiment ?</strong>
</p>

<p align="center">
  <code>git clone https://github.com/aamsellem/uly.git && cd uly && claude</code>
</p>

<p align="center">
  <em>ULY — Ultimate Lazy You</em>
</p>
