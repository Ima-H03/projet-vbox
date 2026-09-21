@echo off
REM genmv_1.bat - Etape 1 : creation puis suppression de la VM Debian1

set "PATH=%PATH%;C:\Program Files\Oracle\VirtualBox"

set NOM=Debian1
set RAM=4096
set DISK=65536
set "VMDIR=%USERPROFILE%\VirtualBox VMs\%NOM%"

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

echo.
echo VM %NOM% creee. Verifie dans la GUI de VirtualBox.
pause

REM Suppression de la VM (et de ses fichiers)
VBoxManage unregistervm %NOM% --delete
goto :eof

:erreur
echo Erreur pendant la creation de %NOM%
exit /b 1