# Casino Brainrot

Casino social Roblox — Chips, machine à sous, Crash, et (bientôt) Plinko et plus.

## Structure du projet

Ce repo est synchronisé avec Roblox Studio via [Rojo](https://rojo.space/).

```
src/
  ReplicatedStorage/
    RemoteEvents/       -- Communication client <-> serveur
    Shared/              -- Config partagée (symboles, mises min/max, UIBuilder)
  ServerScriptService/
    Economy/             -- Système de Chips (solde, leaderstats, DataStore)
    Games/
      SlotMachine/        -- Logique serveur (autoritaire) de la machine à sous
      Crash/              -- Manche partagée : multiplicateur qui monte, cash out avant l'explosion
  StarterPlayerScripts/
    SlotMachine/          -- UI + API client de la machine à sous
    Crash/                -- UI client de Crash
```

Le monde 3D (les salles, les bornes physiques) reste dans le fichier `.rbxl`
de Studio et n'est pas versionné ici — seul le code l'est. Chaque jeu se pose
automatiquement dans le monde via une Part marqueur qu'on place à la main :

- Machine à sous : place une Part nommée exactement `SlotMachineSpawn`.
- Crash : place une Part nommée exactement `CrashSpawn`.

La position/rotation de la Part définit où la borne apparaît ; elle est
remplacée par la borne complète au démarrage du serveur.

## Installer Rojo

1. Installe le [plugin Rojo](https://create.roblox.com/store/asset/13916111004/Rojo) dans Roblox Studio.
2. Installe la CLI Rojo (via [Aftman](https://github.com/LPGhatguy/aftman), ou en téléchargeant le binaire depuis les [GitHub Releases](https://github.com/rojo-rbx/rojo/releases)).

## Lancer la synchronisation

Dans ce dossier :

```
rojo serve
```

Puis dans Studio, ouvre le plugin Rojo et clique sur **Connect**.

## Machine à sous

Borne 3x3, mise réglable (MIN/-/+/MAX), rouleaux qui glissent, jackpot sur 💎💎💎.
Tout le code (économie + UI + construction de la borne) est déjà branché —
il suffit de placer une Part `SlotMachineSpawn` dans le monde.

## Crash

Manche partagée par tous les joueurs connectés : un multiplicateur grimpe à
partir de 1.00x, chacun mise avant le décollage puis encaisse (Cash Out)
quand il veut avant l'explosion. Ne pas encaisser à temps = mise perdue.
Réglages dans `ReplicatedStorage/Shared/CrashConfig.lua` (durée de mise,
vitesse de montée, avantage de la maison).
