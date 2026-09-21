@echo off
REM genmv_2.bat - Etape 2 : creation de Debian1 avec verification d'existence

set "PATH=%PATH%;C:\Program Files\Oracle\VirtualBox"

set NOM=Debian1
set RAM=4096
set DISK=65536
set "VMDIR=%USERPROFILE%\VirtualBox VMs\%NOM%"

REM Verification : une VM du meme nom existe-t-elle deja ?
VBoxManage showvminfo %NOM% >nul 2>&1
if ERRORLEVEL 1 goto creation

echo La VM %NOM% existe deja, suppression...
VBoxManage unregistervm %NOM% --delete
if ERRORLEVEL 1 goto erreur_suppression

:creation
REM Creation et enregistrement de la VM
VBoxManage createvm --name %NOM% --ostype Debian_64 --register
if ERRORLEVEL 1 goto erreur

REM RAM 4096 Mo + carte reseau en NAT
VBoxManage modifyvm %NOM% --memory %RAM% --nic1 nat
if ERRORLEVEL 1 goto erreur

REM Disque dur de 64 Gio (la taille est en Mo)
VBoxManage createmedium disk --filename "%VMDIR%\%NOM%.vdi" --size %DISK%
if ERRORLEVEL 1 goto erreur

REM Controleur SATA + rattachement du disque
VBoxManage storagectl %NOM% --name "SATA" --add sata
if ERRORLEVEL 1 goto erreur
VBoxManage storageattach %NOM% --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%VMDIR%\%NOM%.vdi"
if ERRORLEVEL 1 goto erreur

echo VM %NOM% creee avec succes.
goto :eof

:erreur_suppression
echo Erreur : impossible de supprimer la VM existante %NOM%
exit /b 2

:erreur
echo Erreur pendant la creation de %NOM%
exit /b 1