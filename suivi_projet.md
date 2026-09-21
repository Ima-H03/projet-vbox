# Journal de bord

SAE 51 - Automatisation de la creation de machines  
CHEF DE PROJET : Algor Zoubabela  
AUTRE MEMBRE EQUIPE : Imabith Houngbo  
DATE DEBUT : 16/09/2026  

## Séance n° 1

date - heure : 16/09/2026 de 08h30 à 11h30

Travail effectué : Documentation du projet et prise en compte du sujet.

Difficultés rencontrées : Aucune difficulté particulière.

Remarques sur la séance : Mon binôme était indisposé et est allé chez le médecin.

## Séance n° 2

date - heure : 21/09/2026 de 09h30 à 11h30

Travail effectué : Travail en binôme sur les premières versions de l'automatisation. Algor a travaillé sur l'implémentation en PowerShell. De mon côté, j'ai travaillé sur l'implémentation Bash sous Linux avec `VBoxManage`. Mise en place et tests des versions 1, 2 et 3 avec création, suppression, gestion des noms de VM, arguments `L/N/S/D/A`, vérification des erreurs et configuration de base des machines virtuelles avec 4096 MiB de RAM, disque de 64 GiB et réseau NAT.

Difficultés rencontrées : Suppression impossible juste après l'arrêt d'une VM à cause du verrouillage temporaire de VirtualBox. Le script a été adapté pour attendre l'extinction de la VM et effectuer un arrêt forcé si nécessaire.

Remarques sur la séance : Répartition du travail entre PowerShell et Bash/Linux dans le cadre du travail en binôme.

## Séance n° 3

date - heure : 21/09/2026 de 16h00 à 17h30

Travail effectué : Finalisation du projet et des scripts Bash. Ajout et validation des métadonnées VirtualBox dans `genmv_4.sh` avec la date de création et l'utilisateur. Finalisation de `genmv_5.sh` avec la configuration du démarrage réseau PXE et du TFTP NAT intégré à VirtualBox. Mise en place de `setup-pxe.sh` pour automatiser la préparation de l'environnement TFTP et permettre la reproductibilité du projet sur une autre machine.

Travail PXE : Téléchargement du netboot Debian stable, préparation du répertoire `~/.config/VirtualBox/TFTP`, installation de `pxelinux.0`, `ldlinux.c32`, du fichier `pxelinux.cfg/default`, ainsi que des fichiers `linux` et `initrd.gz`. Tests de création et de recréation de `test-vbox`, démarrage réseau et analyse de captures TFTP.

Résultats des tests : Les requêtes TFTP vers `pxelinux.0`, `ldlinux.c32`, `pxelinux.cfg/default`, `debian-installer/amd64/linux` et `debian-installer/amd64/initrd.gz` ont été observées. Une capture d'écran a permis de vérifier l'affichage de l'installateur Debian.

Reproductibilité : Suppression de l'ancien répertoire TFTP, exécution de `setup-pxe.sh` sur un environnement propre, recréation automatique des fichiers nécessaires puis nouveau test de `genmv_5.sh`. Le démarrage PXE a ensuite été validé.

Documentation : Mise à jour de `README.md` et `usage.md` afin de documenter les versions du projet, les prérequis, l'utilisation des scripts et la préparation PXE.

Difficultés rencontrées : La première configuration avec le serveur TFTP NAT `10.0.2.4` n'a pas permis d'obtenir le fonctionnement PXE attendu. Après analyse, la configuration `10.0.2.2` a été utilisée et validée dans l'environnement VirtualBox de test.

Remarques sur la séance : Dernière séance de travail du projet. Travail réalisé en binôme avec une répartition PowerShell pour Algor et Bash/Linux pour Imabith.
