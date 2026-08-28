# Casino Brainrot

Casino social Roblox — Chips, machine à sous, et (bientôt) Plinko, Crash, et plus.

## Structure du projet

Ce repo est synchronisé avec Roblox Studio via [Rojo](https://rojo.space/).

```
src/
  ReplicatedStorage/
    RemoteEvents/       -- Communication client <-> serveur
    Shared/              -- Config partagée (symboles, mises min/max)
  ServerScriptService/
    Economy/             -- Système de Chips (solde, leaderstats, DataStore)
    Games/
      SlotMachine/        -- Logique serveur (autoritaire) de la machine à sous
  StarterPlayerScripts/
    SlotMachine/          -- API client de la machine à sous
```

Le monde 3D (les salles, la machine à sous physique, l'UI) reste dans le fichier
`.rbxl` de Studio et n'est pas versionné ici — seul le code l'est.

## Installer Rojo

1. Installe le [plugin Rojo](https://create.roblox.com/store/asset/13916111004/Rojo) dans Roblox Studio.
2. Installe la CLI Rojo (via [Aftman](https://github.com/LPGhatguy/aftman), ou en téléchargeant le binaire depuis les [GitHub Releases](https://github.com/rojo-rbx/rojo/releases)).

## Lancer la synchronisation

Dans ce dossier :

```
rojo serve
```

Puis dans Studio, ouvre le plugin Rojo et clique sur **Connect**.

## Brancher l'UI de la machine à sous

`SlotMachineClient` (dans `StarterPlayerScripts/SlotMachine`) expose :

- `SlotMachineClient.Spin(bet)` — à appeler quand le joueur clique sur Spin.
- `SlotMachineClient.OnResult(callback)` — pour recevoir le résultat (symboles, gain, nouveau solde) et mettre à jour l'affichage.

Relie ça à tes boutons et à ton UI existants dans Studio.
