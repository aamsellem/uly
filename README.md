# ULY - Votre Chef de Cabinet IA

ULY est un assistant IA qui mémorise vos conversations, suit vos objectifs et vous aide à rester organisé. Comme avoir un chef de cabinet personnel qui n'oublie jamais rien.

---

## Pour Commencer

### 1. Télécharger ULY

Cliquez sur le bouton vert "Code" ci-dessus, puis "Download ZIP". Décompressez-le quelque part sur votre ordinateur (comme votre dossier Téléchargements).

Ou si vous utilisez git :
```
git clone https://github.com/SterlingChin/marvin-template.git uly
```

### 2. Ouvrir dans Claude Code

Ouvrez Claude Code et naviguez vers le dossier que vous avez téléchargé :
```
cd uly
claude
```

### 3. Demander à ULY de Vous Aider à Configurer

Dites simplement :
> "Aide-moi à configurer ULY"

ULY vous guidera étape par étape :
- Votre nom et rôle
- Vos objectifs (professionnels et personnels)
- Comment vous voulez que ULY communique
- Où créer votre espace de travail personnel (par défaut : ~/uly)
- Optionnel : Connecter Google Calendar, Gmail, Jira, etc.

C'est tout ! ULY s'occupe du reste.

---

## Comment Ça Marche

ULY crée un **espace de travail personnel** séparé de ce modèle :

```
~/uly/                       <- Votre espace (vos données vivent ici)
├── CLAUDE.md               # Votre profil et préférences
├── state/                  # Vos objectifs et priorités
├── sessions/               # Vos journaux de session quotidiens
└── ...

~/Downloads/uly-template/    <- Modèle (gardez-le pour les mises à jour !)
├── .uly/                   # Scripts de configuration et intégrations
└── ...
```

**Votre espace de travail** est où vivent toutes vos données personnelles. Il est à vous de le personnaliser.

**Le modèle** est d'où vous obtenez les mises à jour. Quand de nouvelles fonctionnalités sont ajoutées, lancez `/sync` pour les récupérer.

---

## Utilisation Quotidienne

Une fois configuré, naviguez vers votre espace de travail et démarrez ULY :
```
cd ~/uly
claude
```

Ou si vous avez configuré le raccourci pendant l'intégration, tapez simplement :
```
uly
```

### Commencer Votre Journée
```
/uly
```
ULY vous donne un briefing : vos priorités, échéances et progrès.

### Pendant la Journée
Parlez naturellement :
- "Ajoute une tâche : finir le rapport pour vendredi"
- "Sur quoi devrais-je me concentrer aujourd'hui ?"
- "J'ai terminé la présentation"
- "De quoi avons-nous parlé hier ?"

### Sauvegarder Votre Progrès
```
/update
```
Sauvegarde rapide sans terminer la session.

### Terminer Votre Journée
```
/end
```
ULY sauvegarde tout pour la prochaine fois.

---

## Commandes

| Commande | Ce Qu'elle Fait |
|----------|-----------------|
| `/uly` | Commencer votre journée avec un briefing |
| `/end` | Terminer la session et tout sauvegarder |
| `/update` | Point de contrôle rapide (sauvegarder le progrès) |
| `/report` | Générer un résumé hebdomadaire |
| `/commit` | Réviser et commiter les changements git |
| `/code` | Ouvrir dans votre IDE |
| `/sync` | Obtenir les mises à jour du modèle |
| `/help` | Afficher toutes les commandes et intégrations |

---

## Obtenir les Mises à Jour

Quand de nouvelles fonctionnalités sont ajoutées à ULY :

1. Mettez à jour votre dossier modèle (git pull ou re-télécharger)
2. Ouvrez votre espace de travail dans Claude Code
3. Lancez `/sync`

Vos données personnelles ne sont jamais écrasées. Seules les nouvelles commandes et compétences sont ajoutées.

---

## Migration depuis une Ancienne Version

Si vous utilisiez ULY avant la mise à jour de séparation d'espace de travail, lancez le script de migration pour passer à la nouvelle architecture sans perdre de données.

### 1. Obtenir le Dernier Modèle

```
git clone https://github.com/SterlingChin/marvin-template.git uly
```

Ou si vous l'avez déjà cloné, lancez `git pull` pour obtenir la dernière version.

### 2. Lancer le Script de Migration

```
cd uly
./.uly/migrate.sh
```

### 3. Suivre les Instructions

Le script vous demandera :
- Où se trouve votre installation ULY actuelle
- Où vous voulez votre nouvel espace de travail (par défaut : ~/uly)

Il copie automatiquement toutes vos données :
- Votre profil (CLAUDE.md)
- Objectifs et priorités (state/)
- Journaux de session (sessions/)
- Rapports et contenu
- Toutes les compétences personnalisées que vous avez créées

### 4. Vérifier et Nettoyer

Une fois que vous confirmez que tout fonctionne dans votre nouvel espace de travail, vous pouvez supprimer votre ancien dossier ULY.

---

## Que Peut Faire ULY ?

- **Se souvenir de tout** - Reprendre où vous en étiez, même des jours plus tard
- **Suivre vos objectifs** - Surveiller le progrès sur les objectifs professionnels et personnels
- **Gérer les tâches** - Garder une liste de tâches persistante
- **Faire des briefings** - Commencer chaque jour en sachant ce qui compte
- **Pousser à réfléchir** - ULY est un partenaire de réflexion, pas un béni-oui-oui
- **Se connecter à vos outils** - Intégrations pour Google, Microsoft, Atlassian, Telegram, et plus

---

## Intégrations

ULY peut se connecter à vos outils favoris :

| Intégration | Ce Qu'elle Fait | Configuration |
|-------------|-----------------|---------------|
| [Google Workspace](.uly/integrations/google-workspace/) | Gmail, Calendar, Drive | `/help` puis suivre les instructions |
| [Microsoft 365](.uly/integrations/ms365/) | Outlook, Calendar, OneDrive, Teams | `/help` puis suivre les instructions |
| [Atlassian](.uly/integrations/atlassian/) | Jira, Confluence | `/help` puis suivre les instructions |
| [Telegram](.uly/integrations/telegram/) | Discuter avec ULY depuis votre téléphone | Nécessite une configuration Python |
| [Parallel Search](.uly/integrations/parallel-search/) | Capacités de recherche web | `/help` puis suivre les instructions |

Plus d'intégrations à venir ! Consultez `.uly/integrations/` pour la liste complète et les instructions de configuration.

---

## Contribuer

ULY est ouvert aux contributions ! Que vous vouliez ajouter une nouvelle intégration, corriger un bug ou améliorer la documentation :

1. **Forkez le repo** et créez une branche
2. **Suivez les directives** dans [.uly/integrations/CLAUDE.md](.uly/integrations/CLAUDE.md)
3. **Soumettez une PR** - nous révisons toutes les contributions

Voir le [README des intégrations](.uly/integrations/README.md) pour les directives détaillées de contribution.

---

## Besoin d'Aide ?

Demandez simplement à ULY ! Dites des choses comme :
- "Comment j'ajoute Google Calendar ?"
- "Comment je crée une nouvelle compétence ?"
- "Quelles commandes sont disponibles ?"

Ou tapez `/help` pour une référence rapide.

---

## À Propos

Créé avec le modèle MARVIN par [Sterling Chin](https://sterlingchin.com). Parce que tout le monde mérite un chef de cabinet.
