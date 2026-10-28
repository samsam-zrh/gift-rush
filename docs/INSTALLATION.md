# Intégration dans Studio

Ces modules sont prévus pour une copie de Presents Simulator de Jumpathy, disponible dans [son annonce](https://devforum.roblox.com/t/3-free-open-source-fully-functional-games/2768554). Ils dépendent de son système de profils, de sa boutique et de ses objets. La base ancienne demande aussi des corrections de compatibilité ; copier les modules ne suffit pas à tout installer.

Travailler sur une copie locale dans Studio, sans utiliser les sauvegardes d’une expérience en production.

## Placer les scripts

| Fichier | Type et emplacement dans Studio |
| --- | --- |
| `src/shared/Rewards.luau` | ModuleScript `ReplicatedStorage.GiftRush.Rewards` (créer le dossier `GiftRush`) |
| `src/server/Service.luau` | ModuleScript `ServerScriptService.GiftRushService` |
| `src/client/Guide.client.luau` | LocalScript `StarterPlayer.StarterPlayerScripts.MysteryGuide` |

Charger `GiftRushService` depuis le serveur, une fois les modules de la base initialisés. Le service crée les remotes `Request` et `Changed` dans `ReplicatedStorage.GiftRush`.

## Raccorder la base

- Garder les modules `ServerScriptService.game.data`, `game.stats` et `ReplicatedStorage.shared.network`. Le service écoute `Data.profileLoaded` et conserve sa progression dans `profile.giftRush`.
- Appeler `Service.Opened(player)` après une ouverture réellement récompensée, et `Service.Sold(player, coins)` après une vente réussie, avec le gain réel de cette vente.
- Appliquer l’attribut `GiftRushCollectionBonus` au calcul serveur des jouets gagnés. Conserver les compagnons possédés et `profile.giftRush` lors du prestige.
- Prévoir un premier sac de 50 places et un `Backpack2` à 80 pièces avec 200 places, dans la configuration et les objets de boutique. Le guide utilise ces valeurs.
- Désactiver l’ancien tutoriel et le calendrier automatique de la base pour éviter deux interfaces. Le guide propose son propre calendrier ; `Daily.server.luau` est uniquement un raccord facultatif aux anciens événements `nextRewards` et `dailyRewardTransmitter`.

Le guide attend l’interface native `PlayerGui.UI`. Le service utilise `ServerStorage.pets`, `workspace.gifts`, les zones de vente et boutique de `workspace.areas.area1`, le spawn et `workspace.stores.backpack.models`. Les positions de la course sont définies dans `Service.luau` : les adapter si la carte change.

## Vérifier

Tester dans Studio : ouverture → vente → achat du sac, compagnon de départ, calendrier, collection, course seul puis à deux joueurs. Vérifier aussi les profils pleins, départs en course et sauvegardes. Les tests Lune couvrent seulement la logique des récompenses, pas ces interactions moteur.
