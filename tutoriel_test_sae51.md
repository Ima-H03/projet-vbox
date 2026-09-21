# Tutoriel de test - SAE 51

## 1. Objectif

Ce tutoriel explique étape par étape comment récupérer le projet, préparer l'environnement PXE, tester les scripts Bash et vérifier le fonctionnement de la version finale avec VirtualBox.

La solution retenue pour le projet est Bash sous Linux.

## 2. Prérequis

La machine de test doit disposer de :

- Linux
- Bash
- VirtualBox
- `VBoxManage`
- un accès Internet pour télécharger les fichiers Debian nécessaires au PXE

Vérifier la présence des commandes :

```bash
bash --version
VBoxManage --version
git --version
```

## 3. Récupérer le projet

Cloner le dépôt :

```bash
git clone https://github.com/Ima-H03/projet-vbox.git
```

Entrer dans le projet :

```bash
cd projet-vbox
```

Vérifier les fichiers :

```bash
ls
```

Les fichiers principaux sont :

```text
README.md
genmv_1.sh
genmv_2.sh
genmv_3.sh
genmv_4.sh
genmv_5.sh
setup-pxe.sh
suivi_projet.md
usage.md
```

## 4. Donner les droits d'exécution

Rendre les scripts exécutables :

```bash
chmod +x genmv_1.sh
chmod +x genmv_2.sh
chmod +x genmv_3.sh
chmod +x genmv_4.sh
chmod +x genmv_5.sh
chmod +x setup-pxe.sh
```

Vérifier :

```bash
ls -l *.sh
```

Les scripts doivent être exécutables.

## 5. Vérifier la syntaxe des scripts

Avant de les exécuter, vérifier leur syntaxe :

```bash
bash -n genmv_1.sh
bash -n genmv_2.sh
bash -n genmv_3.sh
bash -n genmv_4.sh
bash -n genmv_5.sh
bash -n setup-pxe.sh
```

Aucune sortie indique qu'aucune erreur de syntaxe Bash n'a été détectée.

## 6. Préparer l'environnement PXE

La version 5 nécessite les fichiers TFTP utilisés pour le démarrage PXE.

Lancer :

```bash
./setup-pxe.sh
```

Le script prépare le répertoire :

```text
~/.config/VirtualBox/TFTP
```

Vérifier le contenu principal :

```bash
test -f ~/.config/VirtualBox/TFTP/pxelinux.0 && echo "pxelinux.0 OK"
test -f ~/.config/VirtualBox/TFTP/pxelinux.cfg/default && echo "default OK"
test -f ~/.config/VirtualBox/TFTP/debian-installer/amd64/linux && echo "linux OK"
test -f ~/.config/VirtualBox/TFTP/debian-installer/amd64/initrd.gz && echo "initrd.gz OK"
```

Le résultat attendu est :

```text
pxelinux.0 OK
default OK
linux OK
initrd.gz OK
```

## 7. Vérifier la configuration PXE

Afficher la configuration PXELINUX :

```bash
cat ~/.config/VirtualBox/TFTP/pxelinux.cfg/default
```

Vérifier également le serveur TFTP utilisé par la version 5 :

```bash
grep 'PXE_TFTP_SERVER' genmv_5.sh
```

Dans l'environnement de test du projet, la valeur validée est :

```text
PXE_TFTP_SERVER="10.0.2.2"
```

## 8. Tester la version 3

La version 3 utilise les opérations suivantes :

```text
L : liste des VM
N : création
D : démarrage
A : arrêt
S : suppression
```

Lister les machines :

```bash
./genmv_3.sh L
```

Créer une machine de test :

```bash
./genmv_3.sh N test-vbox
```

Vérifier son existence :

```bash
VBoxManage list vms
```

Puis supprimer la machine :

```bash
./genmv_3.sh S test-vbox
```

Vérifier :

```bash
VBoxManage list vms
```

## 9. Tester la version 4

Créer une machine avec la version 4 :

```bash
./genmv_4.sh N test-vbox
```

Afficher les machines :

```bash
./genmv_4.sh L
```

La liste doit afficher les informations de métadonnées enregistrées par le script, notamment la date de création et l'utilisateur.

Les valeurs peuvent également être vérifiées directement avec :

```bash
VBoxManage getextradata test-vbox "SAE51/metadata/creation_date"
VBoxManage getextradata test-vbox "SAE51/metadata/creator"
```

Après le test, supprimer la machine :

```bash
./genmv_4.sh S test-vbox
```

## 10. Tester la version finale

### 10.1 Vérifier qu'une ancienne VM de test n'existe plus

```bash
VBoxManage list vms
```

Si `test-vbox` existe encore, la supprimer :

```bash
./genmv_5.sh S test-vbox
```

### 10.2 Créer la machine

```bash
./genmv_5.sh N test-vbox
```

Le script configure notamment :

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

### 10.3 Vérifier la configuration VirtualBox

```bash
VBoxManage showvminfo test-vbox | grep -E "Boot Device|NIC 1|TFTP"
```

Vérifier que :

```text
Boot Device 1: Network
Attachment: NAT
EnableTFTP: 1
```

## 11. Démarrer la VM

Démarrer la VM :

```bash
./genmv_5.sh D test-vbox
```

Ou directement avec VirtualBox :

```bash
VBoxManage startvm test-vbox
```

Attendre quelques secondes :

```bash
sleep 30
```

## 12. Vérifier l'écran de la VM

Créer une capture :

```bash
VBoxManage controlvm test-vbox screenshotpng ~/pxe-screen-test.png
```

Vérifier que le fichier existe :

```bash
ls -lh ~/pxe-screen-test.png
```

Ouvrir ensuite l'image.

Dans le test réalisé pour le projet, l'écran affichait l'installateur Debian après le démarrage PXE.

## 13. Vérifier les échanges PXE/TFTP

Pour réaliser une capture réseau avec la trace de la carte réseau VirtualBox :

```bash
VBoxManage modifyvm test-vbox   --nic-trace1 on   --nic-trace-file1 "$HOME/pxe-test-final.pcap"
```

Redémarrer la VM après avoir activé la trace, puis attendre le démarrage PXE.

Analyser les requêtes TFTP :

```bash
tcpdump -vvv -nn -r ~/pxe-test-final.pcap 'udp port 69' | grep 'RRQ'
```

Vérifier particulièrement :

```bash
tcpdump -vvv -nn -r ~/pxe-test-final.pcap 'udp port 69' | grep -E 'RRQ.*(linux|initrd)'
```

Dans le test validé du projet, les requêtes suivantes ont été observées :

```text
test-vbox.pxe
ldlinux.c32
pxelinux.cfg/default
debian-installer/amd64/linux
debian-installer/amd64/initrd.gz
```

La présence de `linux` et `initrd.gz` montre que la VM demande bien le noyau et l'image initrd de l'installateur Debian via TFTP.

## 14. Tester l'arrêt

Arrêter la machine :

```bash
./genmv_5.sh A test-vbox
```

Vérifier :

```bash
VBoxManage showvminfo test-vbox | grep "State:"
```

## 15. Tester la suppression

Supprimer la machine :

```bash
./genmv_5.sh S test-vbox
```

Vérifier :

```bash
VBoxManage list vms
```

`test-vbox` ne doit plus être enregistrée dans VirtualBox.

## 16. Test complet recommandé

Pour refaire le scénario final depuis le début :

```bash
cd ~/projet-vbox
chmod +x *.sh
./setup-pxe.sh
./genmv_5.sh S test-vbox
./genmv_5.sh N test-vbox
./genmv_5.sh D test-vbox
sleep 30
VBoxManage controlvm test-vbox screenshotpng ~/pxe-screen-final.png
```

Puis vérifier la capture réseau et l'écran de la VM.

À la fin :

```bash
./genmv_5.sh A test-vbox
./genmv_5.sh S test-vbox
```

## 17. Vérification finale du projet

Vérifier le dépôt :

```bash
git status
```

Pour un dépôt propre :

```text
nothing to commit, working tree clean
```

Vérifier les derniers commits :

```bash
git log --oneline -5
```

## 18. Problème rencontré pendant les tests du projet

Lors des premiers essais PXE, la configuration du serveur TFTP NAT avec `10.0.2.4` n'a pas permis d'obtenir le fonctionnement PXE attendu.

La configuration utilisant :

```text
10.0.2.2
```

a ensuite été testée et validée dans l'environnement VirtualBox utilisé pour le projet.

## 19. Résultat attendu

Le test est considéré comme réussi lorsque les éléments suivants sont validés :

```text
Préparation PXE
      ↓
Fichiers TFTP présents
      ↓
Création de la VM
      ↓
Réseau NAT
      ↓
Boot réseau
      ↓
PXE / TFTP
      ↓
Chargement de linux
      ↓
Chargement de initrd.gz
      ↓
Installateur Debian affiché
```

Ce document complète `usage.md` : `usage.md` présente l'utilisation des scripts et leurs fonctionnalités, tandis que ce tutoriel détaille le déroulement pratique du test.
