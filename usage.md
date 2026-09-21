# Automatisation de la création de machines VirtualBox (SAE 51)

**Auteurs :** Algor Zoubabela, Imabith Houngbo
**Date :** 21/09/2026

## Résumé

Ce document décrit les scripts Windows `genmv_X.bat` qui pilotent VirtualBox avec la commande `VBoxManage` pour créer, lister, démarrer, arrêter et supprimer des machines virtuelles Debian sans interface graphique. Le travail est fait par versions successives, chacune reprenant la précédente. Le document explique l'utilisation, les choix faits, les limites et les problèmes rencontrés.

## Prérequis

- Windows avec VirtualBox installé dans `C:\Program Files\Oracle\VirtualBox` (le script ajoute ce dossier au PATH)
- Paramètres modifiables en tête de script : `RAM=4096` (Mo) et `DISK=65536` (Mo, soit 64 Gio)

## Versions

| Version | Contenu | État |
|---|---|---|
| genmv_1.bat | Création de `Debian1` (Debian 64 bits, 4096 Mo, disque 64 Gio, NAT), pause, suppression | Testé |
| genmv_2.bat | Vérification qu'une VM du même nom n'existe pas déjà (suppression puis recréation) | Testé |
| genmv_3.bat | Arguments L / N / S / D / A, messages d'erreur et codes de sortie | Testé |

## Utilisation

```bat
genmv_3.bat L            :: liste les VM
genmv_3.bat N serveur1   :: crée la VM serveur1
genmv_3.bat D serveur1   :: démarre serveur1
genmv_3.bat A serveur1   :: arrête serveur1
genmv_3.bat S serveur1   :: supprime serveur1
```

Codes de sortie : 0 = succès, 1 = mauvais arguments, 2 = VM déjà existante, 3 = échec de création, 4 = échec de suppression, 5 = échec de démarrage, 6 = échec d'arrêt.

## Choix techniques

- `unregistervm --delete` supprime la VM, son disque et son fichier `.vbox`.
- La taille du disque est en Mo pour `createmedium` (64 Gio = 65536).
- Les codes retournés par `VBoxManage` sont testés avec `ERRORLEVEL`.
- Dans genmv_3, si le nom existe déjà, la création est refusée (au lieu de supprimer la VM existante comme dans genmv_2), pour éviter d'effacer une VM par erreur.

## Limites

- Les noms de VM ne doivent pas contenir d'espace.
- L'arrêt utilise `poweroff` (arrêt brutal), car les VM n'ont pas de système installé.

## Problèmes rencontrés

- **VM verrouillée à la suppression :** juste après `controlvm poweroff`, `unregistervm` échouait (« Cannot unregister the machine while it is locked »). Solution : une pause de 3 secondes (`timeout /t 3 /nobreak`) après l'arrêt.
- Message « Paramètre invalide détecté » dans les paramètres de la VM (aucun lecteur optique rattaché), sans impact sur le fonctionnement.

## Astuces

- Tester avec des noms de VM inventés (`test1`, `test2`) pour ne jamais toucher aux VM existantes.
- Vérifier avec `VBoxManage list vms` et le dossier `VirtualBox VMs` que