# Gift Rush

Mon prototype Roblox autour de cadeaux à ouvrir et de compagnons à collectionner, à partir de Presents Simulator de Jumpathy.

J’ai ajouté un parcours guidé, un calendrier de récompenses sur sept jours, une collection et des courses de deux minutes.

## Le code

- `src/shared/Rewards.luau` : calendrier, progression et bonus de retour.
- `src/server/Service.luau` : collection, premières étapes et courses côté serveur.
- `src/client/Guide.client.luau` : guide joueur et menus.
- `src/server/Daily.server.luau` : ancien raccord au calendrier de la base, facultatif.

Les scripts s’intègrent à la base : ce dépôt ne contient pas une carte jouable seule. Voir [l’installation](docs/INSTALLATION.md).

## Tests

Avec [Lune](https://github.com/lune-org/lune) installé, depuis la racine :

```sh
lune run tests/rewards.spec.luau
```

Les 13 vérifications des récompenses passent. Les courses, le multijoueur et les sauvegardes restent à revalider dans Studio.

## Crédits

Base : **Presents Simulator, Jumpathy / tyler2021**, [partagée par son auteur](https://devforum.roblox.com/t/3-free-open-source-fully-functional-games/2768554). Sa carte, ses scripts et ses modèles ne sont pas redistribués ici. Les noms de compagnons et références d’icônes servent à l’intégration avec cette base.

Les assets de la version locale gardent leurs crédits dans [CREDITS.md](docs/CREDITS.md).
