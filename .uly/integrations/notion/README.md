# Intégration Notion

Connectez ULY à votre espace de travail Notion.

## Ce Que Ça Fait

- **Rechercher** - Trouvez des pages et bases de données en un instant
- **Lire** - Accédez au contenu de vos pages
- **Créer** - Générez de nouvelles pages dans vos bases de données
- **Mettre à jour** - Modifiez des pages existantes

ULY peut naviguer dans votre Notion comme vous le feriez, mais en langage naturel.

## Pour Qui C'est

Toute personne qui utilise Notion pour :
- Notes et documentation
- Wikis d'équipe
- Bases de données et trackers de projet
- Second cerveau / PKM

## Prérequis

- Un compte Notion
- La permission de créer des intégrations dans votre espace de travail
- Un token d'intégration Notion (le script de configuration vous guidera)

## Configuration

```bash
./.uly/integrations/notion/setup.sh
```

Le script vous guidera à travers :
1. La création d'une intégration Notion
2. L'obtention de votre token d'intégration
3. Le partage des pages avec votre intégration
4. La configuration du serveur MCP

## Essayez

Après la configuration, essayez ces commandes avec ULY :

- "Cherche dans mon Notion les notes de réunion"
- "Qu'est-ce qu'il y a dans ma base de données Projets ?"
- "Crée une nouvelle page dans mon wiki appelée 'Architecture API'"
- "Mets à jour ma page Tasks avec les notes de la réunion"
- "Liste toutes mes bases de données Notion"
- "Trouve les pages modifiées cette semaine"

## Zone de Danger

Cette intégration peut effectuer des actions qui affectent votre espace de travail :

| Action | Niveau de Risque | Impact |
|--------|-----------------|--------|
| Créer des pages | **Moyen** | Ajoute du contenu à vos bases de données |
| Modifier des pages | **Moyen** | Change le contenu existant |
| Rechercher, lire des pages | Faible | Pas d'impact externe |

**ULY confirmera toujours avant de créer ou modifier des pages.**

Note importante : L'intégration ne peut accéder qu'aux pages que vous avez explicitement partagées avec elle. Vos autres pages restent privées.

## Partager des Pages avec l'Intégration

Pour que ULY puisse accéder à une page ou base de données :

1. Ouvrez la page dans Notion
2. Cliquez sur **"..."** (menu) en haut à droite
3. Cliquez sur **"Connexions"** ou **"Add connections"**
4. Sélectionnez votre intégration (ex: "ULY")
5. Confirmez l'accès

**Astuce :** Partagez une page parent pour donner accès à toutes ses sous-pages.

## Dépannage

**"Impossible de trouver des pages"**

L'intégration ne voit que les pages partagées avec elle. Assurez-vous d'avoir :
1. Partagé les pages via le menu "Connexions"
2. Vérifié que l'intégration apparaît bien dans la liste

**"Token invalide" ou erreurs d'authentification**

- Vérifiez que le token commence par `ntn_` ou `secret_`
- Assurez-vous d'avoir copié le token complet
- Relancez le script de configuration pour un nouveau token

**"Accès refusé" à une page**

La page n'a pas été partagée avec l'intégration. Voir la section "Partager des Pages" ci-dessus.

**Les modifications ne s'appliquent pas**

- Vérifiez que l'intégration a les permissions d'écriture
- Dans les paramètres de l'intégration Notion, assurez-vous que "Insert content" et "Update content" sont cochés

**Le serveur ne démarre pas**

- Vérifiez que Node.js est installé : `node --version`
- Relancez la configuration : `./.uly/integrations/notion/setup.sh`

## Serveur MCP

Cette intégration utilise le [serveur MCP officiel Notion](https://github.com/makenotion/notion-mcp-server) développé par Notion.

---

*Créé par la communauté ULY*
