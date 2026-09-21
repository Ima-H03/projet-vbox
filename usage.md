# Automatisation de la création de machines VirtualBox (SAE 51)

**Auteurs :** Algor Zoubabela, Imabith Houngbo  
**Date de mise à jour :** 21/09/2026

## 1. Présentation

Ce projet automatise la création et la gestion de machines virtuelles VirtualBox à l'aide de `VBoxManage`.

Après plusieurs essais, l'équipe a retenu **Bash sous Linux** comme solution principale. Les tests réalisés ont été plus concluants dans l'environnement utilisé pour le projet, notamment pour l'utilisation de `VBoxManage` et la configuration du démarrage réseau PXE.

Les scripts ont été développés progressivement afin d'ajouter les fonctionnalités demandées.

## 2. Prérequis

L'environnement de test utilisé pour la solution Bash comprend :

- Linux ;
- Bash ;
- VirtualBox ;
- la commande `VBoxManage` disponible dans le PATH ;
- un accès Internet pour préparer les fichiers Debian nécessaires au PXE.

## 3. Fichiers

Les scripts principaux sont :

```text
genmv_1.sh
genmv_2.sh
genmv_3.sh
genmv_4.sh
genmv_5.sh
setup-pxe.sh
```

Les fichiers Markdown associés sont :

```text
README.md
usage.md
suivi_projet.md
```

## 4. Utilisation des versions

### Version 1

```bash
./genmv_1.sh
```

Cette version réalise la première automatisation de création d'une machine Debian.

### Version 2

```bash
./genmv_2.sh
```

Cette version ajoute la gestion d'une machine portant déjà le même nom.

### Version 3

La version 3 fonctionne avec les arguments suivants :

```text
L : liste des VM
N : nouvelle VM
S : suppression
D : démarrage
A : arrêt
```

Exemples :

```bash
./genmv_3.sh L
./genmv_3.sh N serveur1
./genmv_3.sh D serveur1
./genmv_3.sh A serveur1
./genmv_3.sh S serveur1
```

Pour les opérations `N`, `S`, `D` et `A`, le nom de la VM doit être fourni.

### Version 4

La version 4 ajoute les métadonnées de la VM.

Les métadonnées enregistrées sont :

- la date de création ;
- l'utilisateur ayant créé la VM.

Exemple :

```bash
./genmv_4.sh L
```

La liste affiche les informations disponibles pour les VM créées avec cette version.

### Version 5

La version 5 reprend les fonctionnalités précédentes et ajoute le démarrage réseau PXE.

Exemple :

```bash
./genmv_5.sh N test-vbox
```

La configuration testée est :

```text
RAM       : 4096 MiB
Disque    : 64 GiB
Réseau    : NAT
Boot 1    : Network
Boot 2    : HardDisk
Boot 3    : DVD
TFTP NAT  : 10.0.2.2
Fichier   : pxelinux.0
```

## 5. Préparation du PXE

Avant d'utiliser `genmv_5.sh` pour un démarrage PXE, préparer les fichiers TFTP :

```bash
chmod +x setup-pxe.sh
./setup-pxe.sh
```

Le répertoire utilisé est :

```text
~/.config/VirtualBox/TFTP
```

Les fichiers nécessaires comprennent notamment :

```text
pxelinux.0
pxelinux.cfg/default
debian-installer/amd64/linux
debian-installer/amd64/initrd.gz
```

Le script de préparation permet d'éviter de dépendre de fichiers présents uniquement sur la machine ayant servi aux premiers tests.

## 6. Scénario complet

Une utilisation complète de la version 5 est :

```bash
cd ~/projet-vbox
chmod +x setup-pxe.sh
./setup-pxe.sh
./genmv_5.sh N test-vbox
./genmv_5.sh D test-vbox
```

Pour lister les machines :

```bash
./genmv_5.sh L
```

Pour arrêter :

```bash
./genmv_5.sh A test-vbox
```

Pour supprimer :

```bash
./genmv_5.sh S test-vbox
```

## 7. Vérification du PXE

Pendant les tests, la VM a demandé au serveur TFTP les éléments suivants :

```text
test-vbox.pxe
ldlinux.c32
pxelinux.cfg/default
debian-installer/amd64/linux
debian-installer/amd64/initrd.gz
```

Le transfert TFTP a été observé dans une capture réseau.

La VM a ensuite affiché l'installateur Debian, ce qui valide le démarrage PXE dans l'environnement de test.

## 8. Gestion des erreurs

Les scripts contrôlent les arguments et les résultats des opérations `VBoxManage`.

Exemple :

```text
ERREUR: La VM 'test-vbox' n'existe pas.
```

Les scripts retournent également des codes de sortie permettant d'identifier les principales erreurs.

## 9. Paramètres de la machine virtuelle

Les valeurs utilisées pour les tests sont définies dans les scripts :

```text
RAM    : 4096 MiB
Disque : 64 GiB
Réseau : NAT
```

## 10. Reproductibilité

Le scénario recommandé pour un autre environnement est :

```text
setup-pxe.sh
      |
      v
Préparation des fichiers TFTP Debian
      |
      v
genmv_5.sh N <nom>
      |
      v
Configuration de la VM VirtualBox
      |
      v
Boot réseau PXE
      |
      v
PXELINUX
      |
      v
linux + initrd.gz
      |
      v
Installateur Debian
```

Le fonctionnement PXE dépend de la version et de la configuration de VirtualBox ainsi que des fichiers préparés dans le répertoire TFTP. Le script `setup-pxe.sh` permet de préparer cet environnement avant la création de la VM.

## 11. Limites

- Le démarrage PXE nécessite que les fichiers TFTP soient correctement préparés.
- Le comportement du réseau NAT et du TFTP dépend de la configuration VirtualBox utilisée.
- Le scénario PXE a été validé dans l'environnement de test du projet.
