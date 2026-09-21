@echo off
REM genmv_3.bat - Etape 3 : gestion des arguments L / N / S / D / A
REM Usage : genmv_3 L | N nom | S nom | D nom | A nom

set "PATH=%PATH%;C:\Program Files\Oracle\VirtualBox"

REM --- Parametres modifiables ---
set RAM=4096
set DISK=65536

set "ACTION=%~1"
set "NOM=%~2"

REM --- Controle des arguments ---
if "%ACTION%"=="" goto usage
if /I "%ACTION%"=="L" goto lister
if /I not "%ACTION%"=="N" if /I not "%ACTION%"=="S" if /I not "%ACTION%"=="D" if /I not "%ACTION%"=="A" goto usage
if "%NOM%"=="" goto usage

if /I "%ACTION%"=="N" goto nouvelle
if /I "%ACTION%"=="S" goto supprimer
if /I "%ACTION%"=="D" goto demarrer
if /I "%ACTION%"=="A" goto arreter
goto usage

:usage
echo Usage : genmv_3 L ^| N nom ^| S nom ^| D nom ^| A nom
echo   L : lister les VM
echo   N : creer une nouvelle VM
echo   S : supprimer une VM
echo   D : demarrer une VM
echo   A : arreter une VM
exit /b 1

:lister
VBoxManage list vms
goto :eof

:nouvelle
REM Refus si une VM du meme nom existe deja
VBoxManage showvminfo "%NOM%" >nul 2>&1
if not ERRORLEVEL 1 (
    echo Erreur : la VM %NOM% existe deja
    exit /b 2
)

set "VMDIR=%USERPROFILE%\VirtualBox VMs\%NOM%"

VBoxManage createvm --name "%NOM%" --ostype Debian_64 --register
if ERRORLEVEL 1 goto echec_creation

VBoxManage modifyvm "%NOM%" --memory %RAM% --nic1 nat
if ERRORLEVEL 1 goto echec_creation

VBoxManage createmedium disk --filename "%VMDIR%\%NOM%.vdi" --size %DISK%
if ERRORLEVEL 1 goto echec_creation

VBoxManage storagectl "%NOM%" --name "SATA" --add sata
if ERRORLEVEL 1 goto echec_creation

VBoxManage storageattach "%NOM%" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%VMDIR%\%NOM%.vdi"
if ERRORLEVEL 1 goto echec_creation

echo VM %NOM% creee avec succes.
goto :eof

:echec_creation
echo Echec de la creation de la VM %NOM%, verifiez le nom
exit /b 3

:supprimer
VBoxManage unregistervm "%NOM%" --delete
if ERRORLEVEL 1 (
    echo Echec de la suppression de la VM %NOM%, verifiez qu'elle existe et qu'elle est eteinte
    exit /b 4
)
echo VM %NOM% supprimee.
goto :eof

:demarrer
VBoxManage startvm "%NOM%"
if ERRORLEVEL 1 (
    echo Echec du demarrage de la VM %NOM%, verifiez qu'elle existe
    exit /b 5
)
goto :eof

:arreter
REM poweroff = arret brutal (VM sans OS installe). Avec un OS : acpipowerbutton
VBoxManage controlvm "%NOM%" poweroff
if ERRORLEVEL 1 (
    echo Echec de l'arret de la VM %NOM%, verifiez qu'elle est en fonction
    exit /b 6
)
REM Pause pour laisser VirtualBox liberer la VM avant une eventuelle suppression
timeout /t 3 /nobreak >nul
echo VM %NOM% arretee.
goto :eof