# Intégration Parallel Search

Connectez ULY au web avec des capacités de recherche rapide et parallèle.

## Ce Que Ça Fait

- **Recherche Web** - Rechercher sur le web et obtenir des résultats adaptés aux LLM
- **Web Fetch** - Extraire le contenu pertinent d'URLs spécifiques

## Pour Qui C'est

Toute personne qui veut que ULY ait accès aux informations actuelles du web.

## Prérequis

Aucun ! C'est un service MCP hébergé et gratuit.

## Configuration

```bash
./.uly/integrations/parallel-search/setup.sh
```

Le script va configurer le serveur MCP Parallel Search pour Claude Code.

## Essayez

Après la configuration, essayez ces commandes avec ULY :

- "Cherche sur le web la dernière documentation React"
- "Quoi de neuf dans Python 3.12 ?"
- "Trouve les dernières nouvelles sur les développements de l'IA"
- "Cherche le prix actuel du Bitcoin"

## Outils Disponibles

### web_search_preview
Rechercher sur le web avec des requêtes en langage naturel. Retourne des résultats optimisés pour les LLM.

### web_fetch
Récupérer et extraire le contenu pertinent d'URLs spécifiques. Idéal pour explorer les résultats de recherche en profondeur.

## Zone de Danger

Cette intégration est **en lecture seule** et ne peut pas modifier de données externes.

| Action | Niveau de Risque | Qui Est Affecté |
|--------|-----------------|-----------------|
| Recherche web | Faible | Pas d'impact externe |
| Récupérer le contenu d'URL | Faible | Pas d'impact externe |

Pas de confirmation nécessaire - cette intégration lit uniquement du contenu web public.

## Dépannage

**La recherche ne retourne pas de résultats**
Essayez de reformuler votre requête ou d'être plus spécifique.

**Erreurs de timeout**
Le service peut être temporairement occupé. Attendez un moment et réessayez.

---

*Créé par Sterling Chin*
