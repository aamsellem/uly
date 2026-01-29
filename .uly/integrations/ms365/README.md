# Intégration Microsoft 365

Connectez Claude Code à Microsoft 365 (Outlook, Calendar, OneDrive, Teams, SharePoint, etc.)

## Ce Que Ça Fait

- **Outlook** - Lire, envoyer et gérer les emails
- **Calendar** - Voir et créer des événements
- **OneDrive** - Accéder et gérer les fichiers
- **Teams** - Lire les canaux et messages
- **SharePoint** - Accéder aux sites et documents
- **To Do** - Gérer les tâches
- **OneNote** - Accéder aux carnets de notes
- **Planner** - Voir et gérer les plans

## Pour Qui C'est

Toute personne utilisant Microsoft 365 pour le travail ou la productivité personnelle qui veut que Claude aide à gérer les emails, le calendrier et les fichiers.

## Prérequis

- Un compte Microsoft (personnel ou professionnel/scolaire)
- Node.js installé (`npx` disponible)
- Pour les comptes professionnels/scolaires : Votre organisation peut nécessiter le consentement admin (voir Dépannage)

## Configuration

```bash
./.uly/integrations/ms365/setup.sh
```

Le script de configuration demandera :
- **Portée** — portée utilisateur (tous les projets) ou portée projet
- **Type de compte** — professionnel/scolaire ou personnel uniquement
- **Preset d'outils** — tous les outils ou essentiels (mail, calendrier, fichiers)

## Authentification

Utilise l'authentification par flux d'appareil de Microsoft :
1. Lancez `claude mcp` et sélectionnez 'ms365'
2. Choisissez 'Authenticate'
3. Visitez l'URL affichée et entrez le code d'appareil
4. Connectez-vous avec votre compte Microsoft
5. Les tokens sont mis en cache pour les sessions futures

Pas de clés API ou secrets client requis.

## Types de Compte

Le flag `--org-mode` active les deux :
- Comptes Professionnels/Scolaires (Microsoft 365 Business)
- Comptes Microsoft Personnels (outlook.com, hotmail.com)

## Essayez

Après la configuration, essayez ceci dans Claude :

- "Qu'est-ce que j'ai dans mon calendrier Outlook aujourd'hui ?"
- "Montre mes emails récents"
- "Quels fichiers sont dans mon OneDrive ?"

## Zone de Danger

Cette intégration peut effectuer des actions qui affectent les autres ou ne peuvent pas être facilement annulées :

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Envoyer des emails | Élevé | Les destinataires voient immédiatement |
| Supprimer des emails | Élevé | Peut être irrécupérable |
| Créer/modifier des événements de calendrier | Moyen | Les autres participants notifiés |
| Supprimer des fichiers | Élevé | La perte de données peut être permanente |
| Lire emails/fichiers | Faible | Pas d'impact externe |

ULY confirmera toujours avant d'effectuer des actions à haut risque.

## Dépannage

**Erreur "Failed to connect" :**
- Lancez `claude mcp remove ms365 -s user` et relancez la configuration
- Assurez-vous que Node.js est installé

**Problèmes d'authentification / bloqué dans une boucle :**
1. Lancez `claude mcp` dans votre terminal
2. Trouvez 'ms365' dans la liste et sélectionnez-le
3. Choisissez 'Authenticate'
4. Complétez le flux d'appareil dans votre navigateur

Si ça ne fonctionne pas, effacez les tokens en cache : `rm -rf ~/.ms365-mcp/`

**Erreur "Need admin approval" (Comptes Professionnels/Scolaires) :**

Ce MCP demande des permissions larges incluant Teams, SharePoint, et l'accès au répertoire. Beaucoup d'organisations nécessitent le consentement admin pour ces scopes.

Vos options :
1. **Obtenir le consentement admin** - Demandez à votre admin IT d'approuver l'application, ou accordez-vous les droits admin si vous êtes admin
2. **Utiliser un compte Microsoft personnel** - Les comptes personnels (outlook.com, hotmail.com) ne nécessitent pas de consentement admin
3. **Attendre une version à scopes minimaux** - Un fork avec des permissions réduites pour juste Mail, Calendar, et OneDrive est envisagé

Scopes qui nécessitent typiquement un consentement admin :
- `User.Read.All`, `Sites.Read.All`, `Files.Read.All`
- Tous les scopes Teams/Chat (`Team.ReadBasic.All`, `Channel.ReadBasic.All`, etc.)

## Configuration Manuelle

Si vous préférez configurer manuellement :

```bash
# Compte professionnel/scolaire, tous les outils
claude mcp add ms365 -s user -- npx -y @softeria/ms-365-mcp-server --org-mode

# Compte professionnel/scolaire, essentiels uniquement (peut éviter le consentement admin)
claude mcp add ms365 -s user -- npx -y @softeria/ms-365-mcp-server --org-mode --preset mail,calendar,files

# Compte personnel uniquement
claude mcp add ms365 -s user -- npx -y @softeria/ms-365-mcp-server
```

Flags disponibles (lancez `--help` pour la liste complète) :
- `--org-mode` — activer les comptes professionnels/scolaires
- `--preset <tools>` — limiter à des outils spécifiques (mail, calendar, files, teams, etc.)
- `--read-only` — désactiver les opérations d'écriture

## Plus d'Infos

- **GitHub :** [softeria-eu/ms-365-mcp-server](https://github.com/softeria-eu/ms-365-mcp-server) — consultez ici pour les derniers flags et options
- **npm :** [@softeria/ms-365-mcp-server](https://www.npmjs.com/package/@softeria/ms-365-mcp-server)

Pour voir toutes les options disponibles :
```bash
npx -y @softeria/ms-365-mcp-server --help
```

---

*Contribué par Deepak Ramachandran*
