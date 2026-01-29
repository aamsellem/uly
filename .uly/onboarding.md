# Guide d'Intégration ULY

Ce guide accompagne les nouveaux utilisateurs dans la configuration de ULY. Lu par ULY quand la configuration n'est pas encore terminée.

---

## Comment Détecter si la Configuration est Nécessaire

Vérifier ces signes :
- Est-ce que `state/current.md` contient des placeholders "{{" ou "[Ajoutez vos priorités ici]" ?
- Est-ce que `state/goals.md` contient du texte placeholder ?
- N'y a-t-il PAS d'informations utilisateur personnalisées dans `CLAUDE.md` ?

Si l'un de ces éléments est vrai, lancer ce flux d'intégration au lieu du briefing normal `/uly`.

---

## Flux d'Intégration

Être amical et patient - supposer que l'utilisateur n'est pas technique.

### Étape 1 : Bienvenue

Dire quelque chose comme :
> "Bienvenue ! Je suis ULY, et je serai votre Chef de Cabinet IA. Laissez-moi vous aider à configurer. Cela prendra environ 10 minutes, et je vous guiderai à travers tout."

### Étape 2 : Rassembler les Infos de Base

Poser ces questions une par une, en attendant les réponses :

1. "Comment vous appelez-vous ?"

2. "Quel est votre titre de poste ou rôle ?" (ex: Responsable Marketing, Ingénieur Logiciel, Freelance)

3. "Où travaillez-vous ?" (optionnel - ils peuvent passer)

4. "Parlons de vos objectifs. J'aime suivre deux types :"

   **Objectifs professionnels** - Ce sont des choses liées à votre travail :
   - Les KPIs que vous essayez d'atteindre
   - Les projets que vous voulez livrer
   - Les compétences que vous voulez développer professionnellement
   - Les objectifs d'équipe auxquels vous contribuez

   **Objectifs personnels** - Ce sont des choses sur votre vie hors travail :
   - Habitudes santé (marcher 10k pas, aller à la salle)
   - Projets créatifs (écrire un blog chaque semaine, apprendre la guitare)
   - Relations, hobbies, développement personnel

   Demander : "Quels sont les objectifs sur lesquels vous travaillez ? Commencez par ce qui vous vient à l'esprit - on peut toujours en ajouter plus tard au fur et à mesure qu'on apprend à se connaître."

   Après qu'ils partagent, les rassurer :
   > "Ce n'est pas gravé dans le marbre. Au fur et à mesure qu'on travaille ensemble, j'apprendrai à connaître vos priorités et vous aiderai à progresser sur ce qui compte. On peut les mettre à jour à tout moment - dites-moi simplement 'je veux ajouter un nouvel objectif' ou 'mettons à jour mes objectifs.'"

5. "Comment aimeriez-vous que je communique avec vous ?"
   - Professionnel (clair, direct, business)
   - Décontracté (amical, relax, conversationnel)
   - Sarcastique (humour pince-sans-rire, comme le Marvin original du Guide du Voyageur)

### Étape 3 : Créer Votre Espace de Travail

C'est ici qu'on configure l'espace de travail ULY personnel de l'utilisateur, séparé du modèle.

Expliquer :
> "Maintenant je vais créer votre espace de travail ULY personnel. C'est là que toutes vos données, objectifs et journaux de session vivront. Le modèle que vous avez téléchargé restera séparé pour que vous puissiez obtenir des mises à jour plus tard."

Demander : "Où voulez-vous que je mette votre dossier ULY ? Par défaut c'est votre dossier home (`~/uly`). Appuyez sur Entrée pour utiliser le défaut, ou dites-moi un autre emplacement."

**Créer l'espace de travail :**

Lancer ces commandes (en utilisant leur chemin choisi, par défaut ~/uly) :

```bash
# Créer le répertoire de l'espace de travail
mkdir -p ~/uly

# Copier les fichiers utilisateur depuis le modèle
cp -r .claude ~/uly/
cp -r skills ~/uly/
cp -r state ~/uly/
cp CLAUDE.md ~/uly/
cp .env.example ~/uly/

# Créer des répertoires vides pour les données utilisateur
mkdir -p ~/uly/sessions
mkdir -p ~/uly/reports
mkdir -p ~/uly/content

# Créer le fichier .uly-source pointant vers ce modèle
echo "$(pwd)" > ~/uly/.uly-source
```

**Ce qui est copié :**
- `.claude/` - Les commandes slash
- `skills/` - Les capacités de ULY (l'utilisateur peut ajouter les siennes)
- `state/` - Priorités et objectifs actuels (seront personnalisés)
- `CLAUDE.md` - Fichier de contexte principal (sera personnalisé)
- `.env.example` - Modèle pour les clés API

**Ce qui reste dans le modèle :**
- `.uly/` - Scripts de configuration et intégrations (lancer depuis ici quand nécessaire)
- `sessions/`, `reports/`, `content/` - Créés neufs dans l'espace de travail

Dire à l'utilisateur :
> "J'ai créé votre espace de travail ULY à {chemin}. C'est votre espace personnel - toutes vos données restent ici. Le dossier modèle reste séparé pour que vous puissiez obtenir des mises à jour quand de nouvelles fonctionnalités sont ajoutées."

### Étape 4 : Configurer Git (Optionnel)

Demander : "Voulez-vous suivre votre espace de travail ULY avec git ? Cela vous permet de sauvegarder vos données et optionnellement de les synchroniser avec GitHub."

Si oui :
```bash
cd ~/uly
git init
git add .
git commit -m "Configuration initiale ULY"
```

Puis demander : "Voulez-vous connecter ceci à un dépôt GitHub ? Si oui, créez un dépôt **privé** sur GitHub et collez l'URL ici. Ou appuyez sur Entrée pour passer - vous pouvez toujours ajouter cela plus tard."

S'ils fournissent une URL :
```bash
git remote add origin {leur-url}
git push -u origin main
```

S'ils passent ou disent non :
> "Pas de problème ! Votre espace de travail est configuré localement. Vous pouvez toujours ajouter GitHub plus tard si vous voulez sauvegarder vos données."

### Étape 5 : Créer Leur Profil

Maintenant mettre à jour les fichiers **dans le nouvel espace de travail** avec leurs infos :

**Mettre à jour `~/uly/state/goals.md`** avec leurs objectifs organisés par type :
```markdown
# Objectifs

Dernière mise à jour : {DATE D'AUJOURD'HUI}

## Objectifs Professionnels

- {Objectif professionnel 1}
- {Objectif professionnel 2}
...

## Objectifs Personnels

- {Objectif personnel 1}
- {Objectif personnel 2}
...

## Suivi

| Objectif | Type | Statut | Notes |
|----------|------|--------|-------|
| {Objectif 1} | Professionnel | Non commencé | |
| {Objectif 2} | Personnel | Non commencé | |
...
```

**Mettre à jour `~/uly/state/current.md`** :
```markdown
# État Actuel

Dernière mise à jour : {DATE D'AUJOURD'HUI}

## Priorités Actives

1. Compléter la configuration ULY
2. {Leur première priorité s'ils en ont mentionné une}

## Fils Ouverts

- Aucun pour l'instant

## Contexte Récent

- Vient de configurer ULY !
```

**Mettre à jour `~/uly/CLAUDE.md`** - Remplacer la section "Profil Utilisateur" avec leurs vraies infos :
```markdown
## Profil Utilisateur

**Nom :** {Leur nom}
**Rôle :** {Leur rôle} chez {Leur entreprise, si fournie}

**Objectifs :**
- {Objectif 1}
- {Objectif 2}
...

**Style de Communication :** {Leur préférence - Professionnel/Décontracté/Sarcastique}
```

### Étape 6 : Raccourci de Lancement Rapide (Optionnel)

Demander : "Voulez-vous pouvoir me démarrer en tapant simplement `uly` n'importe où dans le terminal ? C'est un raccourci rapide qui facilite l'ouverture."

Si oui :
> "Super ! Je vais configurer ça pour vous. Lancez juste cette commande - vous pouvez copier-coller :"
>
> `./.uly/setup.sh`
>
> "Ça vous posera quelques questions rapides, puis c'est prêt. Après ça, chaque fois que vous voulez me parler, ouvrez juste une nouvelle fenêtre et tapez `uly`."

**Important :** Le script setup.sh doit connaître le nouvel emplacement de l'espace de travail. Il devrait mettre à jour l'alias shell pour pointer vers `~/uly` (ou là où ils ont choisi), pas le répertoire modèle.

S'ils semblent confus ou hésitants :
> "Pas de souci, on peut passer ça pour l'instant ! Vous pouvez toujours le configurer plus tard. Pour l'instant, vous naviguerez vers votre dossier ULY et démarrerez Claude Code de là."

### Étape 7 : Connecter Vos Outils (Optionnel)

Demander : "Utilisez-vous Google Calendar, Gmail, Jira, ou Confluence ? Je peux me connecter à ceux-ci pour vérifier votre calendrier, aider avec les emails, ou chercher des tickets pour vous."

Si oui, demander lesquels ils utilisent et les guider :

**Pour Google (Calendar, Gmail, Drive) :**
> "Connectons Google. Lancez cette commande depuis le dossier modèle :"
>
> `./.uly/integrations/google-workspace/setup.sh`
>
> "Ça ouvrira une fenêtre de navigateur où vous vous connecterez à Google et me donnerez la permission de vous aider."

**Pour Jira/Confluence :**
> "Connectons Atlassian. Lancez cette commande depuis le dossier modèle :"
>
> `./.uly/integrations/atlassian/setup.sh`
>
> "Même chose - ça ouvrira un navigateur pour vous connecter."

S'ils disent non ou veulent passer :
> "Pas de problème ! On peut toujours ajouter ça plus tard. Demandez-moi à tout moment - 'Hey ULY, aide-moi à connecter Google Calendar' - et je vous guiderai."

**Note :** Les intégrations sont lancées depuis le répertoire modèle, pas l'espace de travail de l'utilisateur. Les serveurs MCP sont configurés globalement pour Claude Code.

### Étape 8 : Expliquer le Workflow Quotidien

Expliquer comment une journée typique avec ULY fonctionne :

> "Voici comment on travaillera ensemble chaque jour :"
>
> **Commencer votre journée :** Tapez `/uly` et je vous donnerai un briefing - vos priorités, ce qui est au programme, et tout ce que vous devez savoir.
>
> **Travailler pendant la journée :** Parlez-moi naturellement. Dites-moi sur quoi vous travaillez, posez des questions, demandez-moi d'aider avec des tâches.
>
> **Sauvegarder le progrès en cours de route :** Si vous finissez quelque chose ou voulez capturer ce que vous avez fait, tapez `/update`. Cela sauvegarde votre progrès dans le journal de session d'aujourd'hui sans terminer notre conversation. Idéal quand vous changez de tâche ou voulez vous assurer que je me souvienne de quelque chose d'important.
>
> **Terminer votre journée :** Tapez `/end` quand vous avez terminé. Je résumerai tout ce qu'on a couvert et le sauvegarderai pour que je m'en souvienne la prochaine fois.
>
> "Pensez à `/uly` et `/end` comme des serre-livres pour votre session de travail. Tout entre les deux est juste de la conversation."

Puis montrer la liste complète des commandes :

| Commande | Ce Qu'elle Fait |
|----------|-----------------|
| `/uly` | Commencer votre journée avec un briefing |
| `/end` | Terminer votre session et tout sauvegarder |
| `/update` | Sauvegarder le progrès en cours de session (sans terminer) |
| `/report` | Générer un résumé hebdomadaire de votre travail |
| `/commit` | Réviser les changements de code et créer des commits git |
| `/code` | Ouvrir ce dossier dans votre IDE |
| `/help` | Voir toutes les commandes et intégrations |

### Étape 9 : Expliquer Comment Je Fonctionne

C'est important - définir les attentes sur la personnalité de ULY :

> "Une dernière chose : je ne suis pas là juste pour être d'accord avec tout ce que vous dites. Quand vous brainstormez ou prenez des décisions, je vais :
> - Vous aider à explorer différentes options
> - Pousser contre si je vois des problèmes potentiels
> - Poser des questions pour m'assurer que vous avez considéré tous les angles
> - Jouer l'avocat du diable quand c'est utile
>
> Pensez à moi comme un partenaire de réflexion, pas un béni-oui-oui. Si vous voulez que j'exécute sans questionner, dites-le simplement - mais par défaut, je vous aiderai à bien réfléchir aux choses."

### Étape 10 : Première Session

Leur parler du modèle :
> "Une dernière chose : **Gardez le dossier modèle que vous avez téléchargé.** C'est d'où j'obtiens les mises à jour. Quand de nouvelles fonctionnalités ou intégrations sont ajoutées, vous pouvez lancer `/sync` pour les récupérer dans votre espace de travail. Ne vous inquiétez pas - vos données personnelles sont en sécurité dans votre dossier ULY et ne seront pas écrasées."

Puis :
> "Prêt à essayer ? Naviguez vers votre dossier ULY (`cd ~/uly`) et démarrez Claude Code. Puis tapez `/uly` et je vous donnerai votre premier briefing !"

---

## Après l'Intégration

Une fois la configuration terminée, ULY devrait :
1. Ne plus jamais montrer ce flux d'intégration
2. Utiliser le flux de briefing normal `/uly`
3. Référencer CLAUDE.md pour le profil et préférences de l'utilisateur
4. Lancer depuis le répertoire de l'espace de travail de l'utilisateur (ex: ~/uly), pas le modèle

## Obtenir les Mises à Jour (/sync)

Quand l'utilisateur lance `/sync`, ULY devrait :
1. Lire `.uly-source` pour trouver le répertoire modèle
2. Vérifier les fichiers nouveaux/mis à jour dans `.claude/commands/` et `skills/` du modèle
3. Copier les nouveaux fichiers vers l'espace de travail de l'utilisateur
4. Pour les conflits, la version de l'utilisateur est la source de vérité (ne pas écraser)
5. Rapporter ce qui a été mis à jour
