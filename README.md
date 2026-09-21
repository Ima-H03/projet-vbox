# SAE 51 - Automatisation de la création de machines VirtualBox

Projet réalisé dans le cadre du BUT3 Réseaux & Télécommunications à l'IUT de Rouen.

## Membres

- **Chef de projet :** Algor Zoubabela
- **Membre de l'équipe :** Imabith Houngbo

## Objectif du projet

L'objectif de la SAE 51 est d'automatiser la création et la gestion de machines virtuelles VirtualBox à l'aide de `VBoxManage`.

Le projet a été développé progressivement sous forme de versions successives afin d'ajouter les fonctionnalités demandées tout en conservant une utilisation en ligne de commande.

## Choix de l'implémentation

Plusieurs solutions ont été envisagées et testées au cours du projet.

Après les essais réalisés dans notre environnement de travail, l'équipe a retenu **Bash sous Linux** comme implémentation principale. Cette solution s'est révélée plus concluante pour l'utilisation de `VBoxManage`, l'automatisation des opérations sur les machines virtuelles et la configuration du démarrage réseau PXE.

Le dépôt final contient donc les scripts Bash utilisés pour les différentes étapes du projet.

## Versions

### `genmv_1.sh`

Première version :

- création d'une machine virtuelle Debian 64 bits ;
- 4096 MiB de RAM ;
- disque virtuel de 64 GiB ;
- réseau en NAT ;
- suppression de la machine après le test.

### `genmv_2.sh`

Ajout de la gestion d'une machine portant déjà le même nom afin de rendre les tests plus reproductibles.

### `genmv_3.sh`

Ajout des opérations par arguments :

```text
L : lister les VM
N : créer une VM
S : supprimer une VM
D : démarrer une VM
A : arrêter une VM
```

Exemples :

```bash
./genmv_3.sh L
./genmv_3.sh N serveur1
./genmv_3.sh D serveur1
./genmv_3.sh A serveur1
./genmv_3.sh S serveur1
```

### `genmv_4.sh`

Ajout des métadonnées enregistrées dans VirtualBox :

- date de création ;
- utilisateur ayant créé la VM.

La commande `L` permet d'afficher ces informations.

### `genmv_5.sh`

Ajout de la configuration du démarrage réseau PXE avec le serveur TFTP interne de VirtualBox.

La version testée configure notamment :

- le réseau NAT ;
- le démarrage réseau en première position ;
- le serveur TFTP NAT ;
- le fichier PXE ;
- le répertoire TFTP.

Configuration utilisée pendant les tests :

```text
Serveur TFTP NAT : 10.0.2.2
Fichier PXE      : pxelinux.0
Répertoire TFTP  : ~/.config/VirtualBox/TFTP
```

Les tests réseau ont montré les demandes suivantes :

```text
test-vbox.pxe
ldlinux.c32
pxelinux.cfg/default
debian-installer/amd64/linux
debian-installer/amd64/initrd.gz
```

Une capture d'écran a également permis de vérifier que la VM atteignait l'installateur Debian.

## Préparation PXE

Le dépôt contient le script :

```text
setup-pxe.sh
```

Son objectif est de préparer l'environnement TFTP utilisé par le démarrage PXE.

Utilisation :

```bash
chmod +x setup-pxe.sh
./setup-pxe.sh
```

Les fichiers sont préparés dans :

```text
~/.config/VirtualBox/TFTP
```

Les principaux éléments utilisés par le démarrage PXE sont notamment :

```text
pxelinux.0
pxelinux.cfg/default
debian-installer/amd64/linux
debian-installer/amd64/initrd.gz
```

Après la préparation PXE, la machine peut être créée avec :

```bash
./genmv_5.sh N test-vbox
```

Puis démarrée avec :

```bash
./genmv_5.sh D test-vbox
```

## Organisation du dépôt

```text
genmv_1.sh
genmv_2.sh
genmv_3.sh
genmv_4.sh
genmv_5.sh
setup-pxe.sh
README.md
usage.md
suivi_projet.md
```

## Documentation

Le fichier [`usage.md`](usage.md) contient les prérequis et les commandes d'utilisation.

Le fichier [`suivi_projet.md`](suivi_projet.md) contient le journal de bord du développement.
