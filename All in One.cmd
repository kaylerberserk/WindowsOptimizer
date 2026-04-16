@echo off
setlocal EnableDelayedExpansion

:: Activer les sequences d'echappement ANSI pour les couleurs
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Definir le titre de la console
title Script d'Optimisation Windows - All in One

:: Verifier PowerShell
where powershell >nul 2>&1 || (echo [ERREUR] PowerShell absent. && pause && exit /B 1)

:: Definition du caractere ESC (ASCII 27)
for /f "delims=" %%a in ('powershell -NoProfile -Command "$([char]27)"') do set "ESC=%%a"

:: Couleurs et Styles
set "COLOR_GREEN=!ESC![32m" & set "COLOR_YELLOW=!ESC![33m" & set "COLOR_RED=!ESC![31m"
set "COLOR_CYAN=!ESC![36m"  & set "COLOR_WHITE=!ESC![37m"  & set "COLOR_BLUE=!ESC![34m"
set "COLOR_MAGENTA=!ESC![35m" & set "COLOR_RESET=!ESC![0m" & set "STYLE_BOLD=!ESC![1m"

:: ===========================================================================
:: INITIALISATION DES VARIABLES GLOBALES
:: ===========================================================================
set "HAS_INTERNET=0"
set "IS_LAPTOP=0"
set "HAS_NVIDIA=0"
set "DESACTIVER_SECURITE=0"
set "DESACTIVER_DEFENDER=0"
set "DESACTIVER_ANIMATIONS=0"
set "DESACTIVER_IA=0"
set "DESACTIVER_UAC=0"
set "SKIP_PAUSE=0"

:: Variables Hardware
set "HW_OS=Detection..."
set "HW_CPU=Detection..."
set "HW_GPU=Detection..."
set "HW_RAM=Detection..."

:: ===========================================================================
:: CONVENTION DES INDICATEURS ET COULEURS
:: ===========================================================================
:: [*]       JAUNE   = Action en cours d'execution
:: [OK]      VERT    = Action terminee avec succes
:: [TERMINE] VERT    = Section completee
:: [INFO]    JAUNE   = Information / Conseil
:: [^!]       JAUNE   = Avertissement (attention requise)
:: [-]       ROUGE   = Suppression / Action negative
:: [ERREUR]  ROUGE   = Erreur critique / Echec
:: [ATTENTION] ROUGE = Risque de securite
:: ===========================================================================


:: CHARGEMENT DU SCRIPT (Mode Pro)
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%             INITIALISATION DU SCRIPT D'OPTIMISATION              %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

set /a "LOAD_TOTAL=5"
set /a "LOAD_STEP=0"

:: Etape 1 : Privileges
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification des privileges administrateur"
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Ce script necessite des privileges administrateur.
    pause
    exit /B 1
)

:: Etape 2 : PowerShell (deja verifie au lancement)
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification de PowerShell"

:: Etape 3 : Internet
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification de la connexion Internet"
call :REFRESH_INTERNET_STATUS

:: Etape 4 : Materiel Core
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Analyse des composants systeme"
call :DETECT_HARDWARE

:: Etape 5 : Finalisation
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Preparation de l'interface"
timeout /t 1 /nobreak >nul

goto :MENU_PRINCIPAL

:PROGRESS_BAR
set "PCURRENT=%~1"
set "PTOTAL=%~2"
set "PDESC=%~3"

set /a "PCALC=0"
set /a "PFILL=0"
if not "%PTOTAL%"=="" if not "%PTOTAL%"=="0" (
    set /a "PCALC=%PCURRENT%*100/%PTOTAL%" 2>nul
)
set /a "PFILL=PCALC*20/100" 2>nul

set "PBAR="
for /l %%i in (1,1,20) do (
    if %%i LEQ %PFILL% set "PBAR=!PBAR!#"
    if %%i GTR %PFILL% set "PBAR=!PBAR!."
)

<nul set /p ="!ESC![2K!ESC![1G!COLOR_CYAN![!PBAR!] !COLOR_YELLOW!!PCALC!%% !COLOR_CYAN!!PCURRENT!/!PTOTAL! !COLOR_WHITE!!PDESC!!COLOR_RESET!"
exit /b



:DETECT_HARDWARE
set "HW_OS=Windows" & set "HW_CPU=Inconnu" & set "HW_GPU=Inconnu" & set "HW_RAM=?" & set "IS_LAPTOP=0" & set "HAS_NVIDIA=0"
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor; $v=Get-CimInstance Win32_VideoController; $m=Get-CimInstance Win32_PhysicalMemory; if(-not $m){$m=Get-CimInstance Win32_ComputerSystem}; $b=0; if(Get-CimInstance Win32_Battery){$b=1}; $res=@(); $cap=$o.Caption; if(-not $cap){$pn=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName; if($pn){$cap=$pn}else{$cap='Windows'}}; $res+='OS:'+$cap+' ('+$o.Version+')'; if($c){$res+='CPU:'+$c.Name.Trim()}; if($v){$g=($v|foreach{$_.Name}) -join ' / '; $res+='GPU:'+$g}; if($m.Capacity){$t=($m|Measure-Object Capacity -Sum).Sum; $res+='RAM:'+[math]::Round($t/1GB,0)}else{if($m.TotalPhysicalMemory){$res+='RAM:'+[math]::Round($m.TotalPhysicalMemory/1GB,0)}}; $res+='BAT:'+$b; [System.IO.File]::WriteAllLines(\"$env:TEMP\hw_info.tmp\", $res)" >nul 2>&1
if exist "%TEMP%\hw_info.tmp" (
    for /f "usebackq tokens=1* delims=:" %%a in ("%TEMP%\hw_info.tmp") do (
        if /i "%%a"=="OS" set "HW_OS=%%b"
        if /i "%%a"=="CPU" set "HW_CPU=%%b"
        if /i "%%a"=="GPU" set "HW_GPU=%%b"
        if /i "%%a"=="RAM" set "HW_RAM=%%b"
        if /i "%%a"=="BAT" set "IS_LAPTOP=%%b"
    )
    del "%TEMP%\hw_info.tmp" >nul 2>&1
)
echo "%HW_GPU%" | findstr /i "NVIDIA" >nul && set "HAS_NVIDIA=1"
if /i "%HW_OS%"=="Windows" for /f "tokens=2 delims=[]" %%i in ('ver') do set "HW_OS=%%i"
exit /b

:: ===========================================================================
:: UTILS
:: ===========================================================================


:REFRESH_INTERNET_STATUS
set "HAS_INTERNET=0"
ping -n 1 -w 1500 1.1.1.1 >nul 2>&1
if not errorlevel 1 (
    set "HAS_INTERNET=1"
    exit /b
)
:: Repli si ICMP est bloque (entreprise, pare-feu) : test HTTP leger (service Microsoft)
powershell -NoProfile -Command "try { $c=(Invoke-WebRequest -Uri \"https://www.msftconnecttest.com/connecttest.txt\" -UseBasicParsing -TimeoutSec 5).Content; if ($c -match \"Microsoft\") { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 set "HAS_INTERNET=1"
exit /b

:MENU_PRINCIPAL
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%Script d'Optimisation Windows - All in One%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Affichage des informations systeme
echo %STYLE_BOLD%%COLOR_WHITE% SYSTEME :%COLOR_RESET% %COLOR_CYAN%%HW_OS%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CPU     :%COLOR_RESET% %COLOR_CYAN%%HW_CPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GPU     :%COLOR_RESET% %COLOR_CYAN%%HW_GPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% RAM     :%COLOR_RESET% %COLOR_CYAN%%HW_RAM% Go%COLOR_RESET%
if "%IS_LAPTOP%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE% TYPE    :%COLOR_RESET% %COLOR_CYAN%PC PORTABLE%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% TYPE    :%COLOR_RESET% %COLOR_CYAN%PC FIXE%COLOR_RESET%
)
if "%HAS_INTERNET%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE% INTERNET:%COLOR_RESET% %COLOR_GREEN%Connecte%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% INTERNET:%COLOR_RESET% %COLOR_YELLOW%Hors ligne ou filtre ^(ICMP / HTTP^)%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS GENERALES ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[0]%COLOR_RESET% %COLOR_RED%Nettoyer tweaks obsoletes (legacy cleanup)%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Optimisations Systeme%COLOR_RESET%   %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Optimisations Memoire%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Optimisations Disques%COLOR_RESET%   %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Optimisations GPU%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Optimisations Reseau%COLOR_RESET%    %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_GREEN%Optimisations Clavier/Souris%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- PC DE BUREAU UNIQUEMENT ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_RED%Gerer Economies d'Energie (Activer/Restaurer)%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Gerer Protections Securite (Desactiver/Restaurer)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_WHITE%Optimiser tout (PC de Bureau)%COLOR_RESET%
echo %COLOR_YELLOW%[L]%COLOR_RESET% %COLOR_WHITE%Optimiser tout (PC Portable)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[N]%COLOR_RESET% %COLOR_CYAN%Nettoyage Avance de Windows%COLOR_RESET%
echo %COLOR_YELLOW%[R]%COLOR_RESET% %COLOR_CYAN%Creer un Point de Restauration%COLOR_RESET%
echo %COLOR_YELLOW%[G]%COLOR_RESET% %COLOR_MAGENTA%Gestion Windows (Defender, UAC, Edge, OneDrive...)%COLOR_RESET%
echo %COLOR_YELLOW%[W]%COLOR_RESET% %COLOR_MAGENTA%Outil activation Windows / Office (MAS)%COLOR_RESET%
echo %COLOR_YELLOW%[T]%COLOR_RESET% %COLOR_MAGENTA%Outil Chris Titus Tech (WinUtil)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[Q]%COLOR_RESET% %STYLE_BOLD%%COLOR_RED%Quitter le script%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 012345678DLNRGWTQ /N /M "%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [0-8, D, L, N, R, G, W, T, Q]: %COLOR_RESET%"

:: Gestion des choix (EQU = egalite stricte, ordre sans importance)
if %errorlevel% EQU 17 goto :END_SCRIPT
if %errorlevel% EQU 16 goto :OUTIL_CHRIS_TITUS
if %errorlevel% EQU 15 goto :OUTIL_ACTIVATION
if %errorlevel% EQU 14 goto :MENU_GESTION_WINDOWS
if %errorlevel% EQU 13 goto :CREER_POINT_RESTAURATION
if %errorlevel% EQU 12 goto :NETTOYAGE_AVANCE_WINDOWS
if %errorlevel% EQU 11 goto :TOUT_OPTIMISER_LAPTOP
if %errorlevel% EQU 10 goto :TOUT_OPTIMISER_DESKTOP
if %errorlevel% EQU 9  goto :TOGGLE_PROTECTIONS_SECURITE
if %errorlevel% EQU 8  goto :TOGGLE_ECONOMIES_ENERGIE
if %errorlevel% EQU 7  goto :OPTIMISATIONS_PERIPHERIQUES
if %errorlevel% EQU 6  goto :OPTIMISATIONS_RESEAU
if %errorlevel% EQU 5  goto :OPTIMISATIONS_GPU
if %errorlevel% EQU 4  goto :OPTIMISATIONS_DISQUES
if %errorlevel% EQU 3  goto :OPTIMISATIONS_MEMOIRE
if %errorlevel% EQU 2  goto :OPTIMISATIONS_SYSTEME
if %errorlevel% EQU 1  goto :CLEANUP_OLD_TWEAKS
goto :MENU_PRINCIPAL

:MENU_GESTION_WINDOWS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES COMPOSANTS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Ce menu regroupe les options pour gerer les fonctionnalites%COLOR_RESET%
echo %COLOR_WHITE%et composants systeme (securite, interface, applications).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_BLUE%--- SECURITE ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Gerer Windows Defender%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Gerer UAC (Controle de Compte Utilisateur)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- INTERFACE ---%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Gerer les Animations Windows%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Gerer Copilot / Widgets / Recall (Windows 11)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS MICROSOFT ---%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_RED%Desinstaller OneDrive Completement%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desinstaller Edge Completement%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- RUNTIMES ET DEPENDANCES ---%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_GREEN%Installer Runtimes (Visual C++ + DirectX June 2010)%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 1234567M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-7, M]: %COLOR_RESET%"
:: Gestion des choix (EQU = egalite stricte, ordre sans importance)
if %errorlevel% EQU 8 goto :MENU_PRINCIPAL
if %errorlevel% EQU 7 goto :INSTALLER_VISUAL_REDIST
if %errorlevel% EQU 6 goto :DESINSTALLER_EDGE
if %errorlevel% EQU 5 goto :DESINSTALLER_ONEDRIVE
if %errorlevel% EQU 4 goto :TOGGLE_COPILOT
if %errorlevel% EQU 3 goto :TOGGLE_ANIMATIONS
if %errorlevel% EQU 2 goto :TOGGLE_UAC
if %errorlevel% EQU 1 goto :TOGGLE_DEFENDER
goto :MENU_GESTION_WINDOWS

:TOUT_OPTIMISER_DESKTOP
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_WHITE% Application de toutes les optimisations (Desktop)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette option va appliquer toutes les optimisations pour Desktop.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre plusieurs minutes.
echo.

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les protections de securite (Spectre/Meltdown) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : mitigations CPU/noyau contre fuites laterales ; desactiver%COLOR_RESET%
echo %COLOR_WHITE%peut reduire latence CPU mais augmente le risque sur machine multi-utilisateurs ou exposee.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Reduit la latence systeme et l'overhead CPU
echo       %COLOR_YELLOW%Expose le systeme a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les protections (recommande)
echo.
set "DESACTIVER_SECURITE=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :DESKTOP_SECURITE_NON
if errorlevel 1 set "DESACTIVER_SECURITE=1"
:DESKTOP_SECURITE_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : sans antivirus integre, moins de charge disque/CPU mais%COLOR_RESET%
echo %COLOR_WHITE%aucune analyse temps reel des telechargements ; a combiner avec un autre AV si besoin.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en desactivant l'antivirus
echo       %COLOR_YELLOW%Expose le systeme aux virus et logiciels malveillants%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver Windows Defender (recommande)
echo.
set "DESACTIVER_DEFENDER=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :DESKTOP_DEFENDER_NON
if errorlevel 1 set "DESACTIVER_DEFENDER=1"
:DESKTOP_DEFENDER_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les animations Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : effets DWM, menus et demarrage ; utile sur PC limite,%COLOR_RESET%
echo %COLOR_WHITE%un peu plus brut visuellement ; reversible via le menu Activer les animations.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en supprimant les animations
echo       %COLOR_YELLOW%L'interface sera moins fluide visuellement%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les animations (recommande)
echo.
set "DESACTIVER_ANIMATIONS=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver les animations Windows ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :DESKTOP_ANIMATIONS_NON
if errorlevel 1 set "DESACTIVER_ANIMATIONS=1"
:DESKTOP_ANIMATIONS_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les fonctionnalites IA de Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Copilot, widgets, Recall consomment CPU/reseau et%COLOR_RESET%
echo %COLOR_WHITE%envoient des donnees vers Microsoft ; couper tout ameliore confidentialite et perf.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Desactive Copilot, Recall, widgets et autres fonctionnalites IA
echo       %COLOR_YELLOW%Ameliore les performances et la confidentialite%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les fonctionnalites IA
echo.
set "DESACTIVER_IA=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces fonctionnalites IA ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :DESKTOP_IA_NON
if errorlevel 1 set "DESACTIVER_IA=1"
:DESKTOP_IA_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver le Controle de Compte Utilisateur (UAC) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : sans UAC, les programmes peuvent obtenir des droits admin%COLOR_RESET%
echo %COLOR_WHITE%sans votre accord explicite ; ce script coupe aussi des avertissements lies.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ne plus demander de confirmation (Oui/Non) pour les actions admin
echo       %COLOR_YELLOW%Reduit la securite en permettant aux applis de s'executer sans alerte%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver l'UAC (recommande)
echo.
set "DESACTIVER_UAC=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :DESKTOP_UAC_NON
if errorlevel 1 set "DESACTIVER_UAC=1"
:DESKTOP_UAC_NON


cls
set "SKIP_PAUSE=1"
call :INSTALLER_VISUAL_REDIST
call :OPTIMISATIONS_SYSTEME
call :OPTIMISATIONS_MEMOIRE
call :OPTIMISATIONS_DISQUES
call :OPTIMISATIONS_GPU
call :OPTIMISATIONS_RESEAU
call :OPTIMISATIONS_PERIPHERIQUES
call :DESACTIVER_ECONOMIES_ENERGIE
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE
if "%DESACTIVER_DEFENDER%"=="1" call :DESACTIVER_DEFENDER_SECTION
if "%DESACTIVER_ANIMATIONS%"=="1" call :DESACTIVER_ANIMATIONS_SECTION
if "%DESACTIVER_IA%"=="1" call :DESACTIVER_TOUT_COPILOT
if "%DESACTIVER_UAC%"=="1" call :DESACTIVER_UAC_SECTION
set "SKIP_PAUSE=0"
call :AFFICHER_RESUME_OPTIMISATION DESKTOP
goto :MENU_PRINCIPAL

:TOUT_OPTIMISER_LAPTOP
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_WHITE% Application de toutes les optimisations (Laptop)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette option va appliquer toutes les optimisations pour Laptop.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Certaines economies d'energie seront conservees pour la batterie.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre plusieurs minutes.
echo.

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les protections de securite (Spectre/Meltdown) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : mitigations CPU/noyau contre fuites laterales ; desactiver%COLOR_RESET%
echo %COLOR_WHITE%peut reduire latence CPU mais augmente le risque sur machine multi-utilisateurs ou exposee.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Reduit la latence systeme et l'overhead CPU
echo       %COLOR_YELLOW%Expose le systeme a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les protections (recommande)
echo.
set "DESACTIVER_SECURITE=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :LAPTOP_SECURITE_NON
if errorlevel 1 set "DESACTIVER_SECURITE=1"
:LAPTOP_SECURITE_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : sans antivirus integre, moins de charge disque/CPU mais%COLOR_RESET%
echo %COLOR_WHITE%aucune analyse temps reel des telechargements ; a combiner avec un autre AV si besoin.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en desactivant l'antivirus
echo       %COLOR_YELLOW%Expose le systeme aux virus et logiciels malveillants%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver Windows Defender (recommande)
echo.
set "DESACTIVER_DEFENDER=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :LAPTOP_DEFENDER_NON
if errorlevel 1 set "DESACTIVER_DEFENDER=1"
:LAPTOP_DEFENDER_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les animations Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : effets DWM, menus et demarrage ; utile sur PC limite,%COLOR_RESET%
echo %COLOR_WHITE%un peu plus brut visuellement ; reversible via le menu Activer les animations.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en supprimant les animations
echo       %COLOR_YELLOW%L'interface sera moins fluide visuellement%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les animations (recommande)
echo.
set "DESACTIVER_ANIMATIONS=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver les animations Windows ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :LAPTOP_ANIMATIONS_NON
if errorlevel 1 set "DESACTIVER_ANIMATIONS=1"
:LAPTOP_ANIMATIONS_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les fonctionnalites IA de Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Copilot, widgets, Recall consomment CPU/reseau et%COLOR_RESET%
echo %COLOR_WHITE%envoient des donnees vers Microsoft ; couper tout ameliore confidentialite et perf.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Desactive Copilot, Recall, widgets et autres fonctionnalites IA
echo       %COLOR_YELLOW%Ameliore les performances et la confidentialite%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les fonctionnalites IA
echo.
set "DESACTIVER_IA=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces fonctionnalites IA ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :LAPTOP_IA_NON
if errorlevel 1 set "DESACTIVER_IA=1"
:LAPTOP_IA_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver le Controle de Compte Utilisateur (UAC) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : sans UAC, les programmes peuvent obtenir des droits admin%COLOR_RESET%
echo %COLOR_WHITE%sans votre accord explicite ; ce script coupe aussi des avertissements lies.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ne plus demander de confirmation (Oui/Non) pour les actions admin
echo       %COLOR_YELLOW%Reduit la securite en permettant aux applis de s'executer sans alerte%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver l'UAC (recommande)
echo.
set "DESACTIVER_UAC=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :LAPTOP_UAC_NON
if errorlevel 1 set "DESACTIVER_UAC=1"
:LAPTOP_UAC_NON


cls
set "SKIP_PAUSE=1"
call :INSTALLER_VISUAL_REDIST
call :OPTIMISATIONS_SYSTEME
call :OPTIMISATIONS_MEMOIRE
call :OPTIMISATIONS_DISQUES
call :OPTIMISATIONS_GPU
call :OPTIMISATIONS_RESEAU
call :OPTIMISATIONS_PERIPHERIQUES
:: Note: DESACTIVER_ECONOMIES_ENERGIE NON appele pour Laptop (preserve la batterie)
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE
if "%DESACTIVER_DEFENDER%"=="1" call :DESACTIVER_DEFENDER_SECTION
if "%DESACTIVER_ANIMATIONS%"=="1" call :DESACTIVER_ANIMATIONS_SECTION
if "%DESACTIVER_IA%"=="1" call :DESACTIVER_TOUT_COPILOT
if "%DESACTIVER_UAC%"=="1" call :DESACTIVER_UAC_SECTION
set "SKIP_PAUSE=0"
call :AFFICHER_RESUME_OPTIMISATION LAPTOP
goto :MENU_PRINCIPAL

:AFFICHER_RESUME_OPTIMISATION
:: Parametres: %~1 = mode ("DESKTOP" ou "LAPTOP")
set "MODE=%~1"
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
if "%MODE%"=="DESKTOP" (
    echo %STYLE_BOLD%%COLOR_WHITE% OPTIMISATION DESKTOP TERMINEE AVEC SUCCES%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% OPTIMISATION LAPTOP TERMINEE AVEC SUCCES%COLOR_RESET%
)
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Toutes les optimisations ont ete appliquees.%COLOR_RESET%
if "%MODE%"=="DESKTOP" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan de performances "Ultimate Performance" active.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[#]%COLOR_RESET% %COLOR_WHITE%Les economies d'energie ont ete preservees pour la batterie.%COLOR_RESET%
)
echo %COLOR_CYAN%[#]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme, memoire, GPU et disques terminees.%COLOR_RESET%
echo.
set "SUM_TAG=[INFO]"
if "%DESACTIVER_SECURITE%"=="1" (
  echo %COLOR_RED%!SUM_TAG!%COLOR_RESET% %COLOR_WHITE%Les protections de securite ont ete desactivees.%COLOR_RESET%
)
if "%DESACTIVER_DEFENDER%"=="1" (
  echo %COLOR_RED%!SUM_TAG!%COLOR_RESET% %COLOR_WHITE%Windows Defender a ete desactive.%COLOR_RESET%
)
if "%DESACTIVER_ANIMATIONS%"=="1" (
  echo %COLOR_RED%!SUM_TAG!%COLOR_RESET% %COLOR_WHITE%Les animations Windows ont ete desactivees.%COLOR_RESET%
)
if "%DESACTIVER_IA%"=="1" (
  echo %COLOR_RED%!SUM_TAG!%COLOR_RESET% %COLOR_WHITE%Les fonctionnalites IA de Windows ont ete desactivees.%COLOR_RESET%
)
if "%DESACTIVER_UAC%"=="1" (
  echo %COLOR_RED%!SUM_TAG!%COLOR_RESET% %COLOR_WHITE%Le Controle de Compte Utilisateur ^(UAC^) a ete desactive.%COLOR_RESET%
)
echo.
echo %COLOR_RED%!SUM_TAG!%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer toutes les modifications.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous redemarrer votre PC maintenant ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 exit /b
if errorlevel 1 shutdown /r /t 5 /c "Redemarrage pour appliquer les optimisations"
exit /b

:CLEANUP_OLD_TWEAKS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 0 : NETTOYAGE DES TWEAKS OBSOLETES%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Suppression des tweaks legacy qui peuvent causer des problemes.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 0.1 - Kernel legacy tweaks
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks kernel...
for %%V in (MaximumSharedReadyQueueSize SplitLargeCaches EnableIdleThreadBalancing DisablePreemptionThreshold EnableIdlePerformanceState AmdCpuBackoffTime XMMIZeroingEnable ConfigureSystem DebugPollTimeout DpcWatchdogProfilePeriod DynamicProcessorAffinity MaxDynamicTickDuration IdealDpcRate) do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v %%V /f >nul 2>&1
)
for %%V in (DpcTimeout DpcWatchdogPeriod MaximumDpcQueueDepth UnlimitDpcQueue ThreadDpcEnable SerializeTimerExpiration) do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v %%V /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks kernel nettoyes

:: 0.2 - Communications legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks communications...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Communications" /v NonDefaultCommsDevice /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks communications nettoyes

:: 0.3 - Desktop legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks desktop...
reg delete "HKCU\Control Panel\Desktop" /v ForegroundApplicationBoostLevel /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks desktop nettoyes

:: 0.4 - TCP legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks TCP...
for %%V in (GlobalMaxTcpWindowSize DefaultTTL SackOpts TcpMaxDupAcks MaxConnectionsPerServer MaxUserPort TcpTimedWaitDelay CongestionAlgorithm) do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v %%V /f >nul 2>&1
)
for %%V in (TimerResolution MaxOutstandingSends) do (
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v %%V /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks TCP nettoyes

:: 0.5 - BCD legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks BCD...
bcdedit /deletevalue useplatformtick >nul 2>&1
bcdedit /deletevalue useplatformclock >nul 2>&1
bcdedit /deletevalue x2apicpolicy >nul 2>&1
bcdedit /deletevalue uselegacyapicmode >nul 2>&1
bcdedit /deletevalue usephysicaldestination >nul 2>&1
bcdedit /deletevalue usefirmwarepcisettings >nul 2>&1
bcdedit /deletevalue configaccesspolicy >nul 2>&1
bcdedit /deletevalue tscsyncpolicy >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks BCD nettoyes

:: 0.6 - PCI legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks PCI...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\PnP\Pci" /v DeviceInterruptRoutingPolicy /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks PCI nettoyes

:: 0.7 - PriorityControl legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks PriorityControl...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ0Priority /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ8Priority /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ForegroundBoost /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ThreadBoostType /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks PriorityControl nettoyes

:: 0.8 - Memory Management legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks Memory Management...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks Memory Management nettoyes

:: 0.9 - MMCSS legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks MMCSS...
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NoLazyMode /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks MMCSS nettoyes

:: 0.10 - FileSystem legacy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des tweaks FileSystem...
reg delete "HKLM\System\CurrentControlSet\Control\FileSystem" /v "FUA" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Tweaks FileSystem nettoyes

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Nettoyage des tweaks obsoletes termine.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:OPTIMISATIONS_SYSTEME
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 1 : OPTIMISATIONS SYSTEME%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Optimise le noyau Windows, desactive la telemetrie et configure%COLOR_RESET%
echo %COLOR_WHITE%  l'interface pour de meilleures performances generales.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 1.1 - Priorites CPU et planification
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des priorites CPU...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEngCP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Priorites CPU configurees

:: 1.2 - Profil Gaming MMCSS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil gaming (MMCSS)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Profil gaming (MMCSS) configure

:: 1.3 - Interface Windows
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de l'interface Windows...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontPrettyPath" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DesktopLivePreviewHoverTime" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SeparateProcess" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v DesktopProcess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f >nul 2>&1


:: 1.4 - Telemetrie et vie privee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la telemetrie et des publicites...
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1

:: Optimiser le cache d'icones et miniatures
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_SZ /d "8192" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul 2>&1

:: Desactiver la compression des papiers peints
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Interface et privacy de base optimisees

:: 1.5 - Telemetrie systeme et vie privee approfondie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la telemetrie et des traceurs...
:: Registre : telemetrie et publicites
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowSluggishnessTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableConsumerAccountStateContent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableSoftLanding" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiences" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "ActivityHistoryEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v PeriodInNanoSeconds /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Feedback" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1

:: Content Delivery Manager
for %%V in (ContentDeliveryAllowed FeatureManagementEnabled OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled RemediationRequired RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled SilentInstalledAppsEnabled SoftLandingEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SubscribedContent-310093Enabled SubscribedContent-314563Enabled SubscribedContent-338380Enabled SubscribedContent-338381Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v %%V /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Recherche Windows - Bing OFF
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Wi-Fi Sense OFF
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v "Value" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v "Value" /t REG_DWORD /d 0 /f >nul 2>&1

:: Activity History OFF
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie et publicites desactivees

:: Taches planifiees de telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des taches planifiees de telemetrie...
for %%T in (
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "Microsoft\Windows\Application Experience\AitAgent"
    "Microsoft\Windows\Autochk\Proxy"
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "Microsoft\Windows\Customer Experience Improvement Program\Uploader"
    "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "Microsoft\Windows\Feedback\Siuf\DmClient"
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "Microsoft\Windows\PI\Sqm-Tasks"
    "Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "Microsoft\Windows\DiskFootprint\Diagnostics"
    "Microsoft\Windows\NetTrace\GatherNetworkInfo"
    "Microsoft\Windows\Shell\FamilySafetyMonitor"
    "Microsoft\Windows\Shell\FamilySafetyRefreshTask"
    "Microsoft\Windows\WDI\ResolutionHost"
    "Microsoft\Windows\SettingSync\BackgroundUploadTask"
    "Microsoft\Windows\SettingSync\NetworkStateChangeTask"
    "Microsoft\Windows\SkyDrive\Idle Sync Maintenance Task"
    "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization"
    "Microsoft\Windows\Work Folders\Work Folders Maintenance Work"
    "Microsoft\Windows\PushToInstall\Registration"
    "Microsoft\Windows\Subscription\EnableLicenseAcquisition"
) do schtasks /Change /TN "%%~T" /Disable >nul 2>&1

:: Autologgers de diagnostic OFF
for %%L in (AppModel Cellcore DiagLog SQMLogger Diagtrack-Listener) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~L" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" /v Start /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Taches de telemetrie desactivees

:: Blocage telemetrie via hosts
echo %COLOR_YELLOW%[*]%COLOR_RESET% Ajout des blocages telemetrie dans le fichier hosts...
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
attrib -r "%HOSTS%" >nul 2>&1

:: Supprimer TOUTES les anciennes entrees telemetrie (ancien format sans marqueurs + nouveau format avec marqueurs)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des anciennes entrees telemetrie dans hosts...
findstr /i /v /c:"telemetry" /c:"watson" /c:"vortex" /c:"v10.events" /c:"metaservices" /c:"choice.microsoft" /c:"settings-sandbox" /c:"statsfe" /c:"corpext" /c:"compatexchange" /c:"feedback" /c:"settings-win" /c:"self.events" /c:"onecollector" /c:"diagnostics.support" "%HOSTS%" > "%HOSTS%.tmp"
findstr /i /v /c:"storeedgefd" /c:"ds.microsoft.com" "%HOSTS%.tmp" > "%HOSTS%.clean"
copy /y "%HOSTS%.clean" "%HOSTS%" >nul
del "%HOSTS%.tmp" "%HOSTS%.clean" >nul 2>&1

:: Ajouter le nouveau bloc
echo.>> "%HOSTS%"
echo # Telemetry Block Start>> "%HOSTS%"
echo # --- Telemetry Block --->> "%HOSTS%"
echo 0.0.0.0 vortex.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 vortex-win.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 v10.vortex-win.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 v10.events.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 telecommand.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 oca.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 watson.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 watsonc.microsoft.com>> "%HOSTS%"
echo # --- End Telemetry Block --->> "%HOSTS%"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Domaines telemetrie bloques via hosts
attrib +r "%HOSTS%" >nul 2>&1

:: 1.6 - Services optimises
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation services

:: 1 - Services vitaux -> AUTOMATIQUE
for %%S in (
    W32Time
    WpnService
    SysMain
    defragsvc
) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
)
:: WpnUserService necessite powershell/wildcards car c'est un service par utilisateur
powershell -NoProfile -Command "Get-Service WpnUserService* | Set-Service -StartupType Automatic" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services vitaux et synchronisation en Automatique

:: 2 - Services occasionnels et utiles -> MANUEL (demand)
for %%S in (
    ALG
    AppVClient
    BDESVC
    CertPropSvc
    GraphicsPerfSvc
    icssvc
    IKEEXT
    MapsBroker
    MSDTC
    MSiSCSI
    NaturalAuthentication
    NcaSvc
    NcbService
    camsvc
    NgcSvc
    NgcCtnrSvc
    PeerDistSvc
    PhoneSvc
    PNRPAutoReg
    PNRPsvc
    RpcLocator
    SCardSvr
    ScDeviceEnum
    SstpSvc
    stisvc
    TroubleshootingSvc
    tzautoupdate
    WFDSConMgrSvc
    WiaRpc
    dmwappushservice
    SystemSuggestions
    uhssvc
    WerSvc
) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
)
:: CDPUserSvc est un service par utilisateur
powershell -NoProfile -Command "Get-Service CDPUserSvc* | Set-Service -StartupType Manual" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services utiles et occasionnels en mode Manuel

:: 3 - Services inutiles et telemetrie -> DESACTIVES
for %%S in (
    AJRouter
    AxInstSV
    CscService
    DiagTrack
    diagnosticshub.standardcollector.service
    DialogBlockingService
    Fax
    lfsvc
    lltdsvc
    NetTcpPortSharing
    RemoteAccess
    RemoteRegistry
    RetailDemo
    SEMgrSvc
    shpamsvc
    ssh-agent
    UevAgentService
    WalletService
    WMPNetworkSvc
) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services telemetrie et legacy desactives

:: Services critiques laisses intacts : Bluetooth, Hello, RDP, Spooler, PlugPlay
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services optimises (Bluetooth/VPN/Hello/RDP preserves)

:: 1.7 - Optimisations demarrage et systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisations systeme diverses...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f >nul 2>&1
bcdedit /set bootuxdisabled on >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "08" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "32" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t REG_DWORD /d 7 /f >nul 2>&1

:: Win8 Scaling (Visual Clarity) - Desktop Only
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du Scaling Windows ^(Win8 DPI Scaling^)...
    reg add "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Win8 Scaling active ^(Mode 1:1 force^)
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% Win8 Scaling ignore sur Laptop ^(conserve le scaling par defaut^)
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Optimisations demarrage et stockage terminees

:: MSI
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation des interruptions MSI sur tous les peripheriques compatibles...
powershell -NoLogo -NoProfile -Command "$devices=Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue; foreach($d in $devices){ $id=$d.InstanceId; if([string]::IsNullOrWhiteSpace($id)){ continue }; $paths=@('HKLM:\SYSTEM\CurrentControlSet\Enum\'+$id+'\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties','HKLM:\SYSTEM\ControlSet001\Enum\'+$id+'\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'); foreach($p in $paths){ if(Test-Path $p){ New-ItemProperty -Path $p -Name MSISupported -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Interruptions MSI activees

:: Desactivation des Co-installateurs tiers (Razer/Logitech Popup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Co-installateurs et recherche pilotes auto...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Popups Razer/Logitech bloques

:: Privacy Supplementaire
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des tweaks privacy supplementaires...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f >nul 2>&1

:: Privacy avancee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Privacy avancee...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DisableDeviceDiagnosticData /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v UploadPermission /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Handwriting" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v PreventHandwritingDataSharing /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PerfTrack" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\PerfTrack" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Privacy avancee appliquee

:: Pare-feu telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation pare-feu telemetrie...
netsh advfirewall firewall add rule name="Block MS Telemetry Out" dir=out action=block remoteip=20.42.65.0/24,51.104.0.0/16,52.108.0.0/16,104.43.0.0/16,13.107.0.0/16 protocol=any >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Pare-feu telemetrie actif (Update + Store preserves)

:: Batterie - Energy Saver
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: 1.8 - Navigateurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation navigateurs ...
:: Microsoft Edge
reg add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d secure /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v EdgeCollectionsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NetworkPredictionOptions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NewTabPagePrerenderEnabled /t REG_DWORD /d 1 /f >nul 2>&1

:: Google Chrome
reg add "HKCU\Software\Policies\Google\Chrome" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsMode /t REG_SZ /d secure /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Navigateurs optimises

:: 1.9 - Desactivation du stockage reserve
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du stockage reserve Windows...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v ShippedWithReserves /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v PassedPolicy /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Stockage reserve desactive ^(~7Go recuperes apres redemarrage^)

:: 1.10 - Affichage du code erreur BSoD
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de l'affichage des codes erreur BSoD...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DisplayParameters /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Codes erreur BSoD visibles (diagnostic facilite)

:: 1.11 - Desactivation de l'aide F1
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la touche F1 (aide Windows)...
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Touche F1 (aide) desactivee

:: 1.12 - Desactivation audio enhancements (latence audio)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des ameliorations audio...
powershell -NoProfile -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}'; Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p = $_.PSPath; Set-ItemProperty -Path $p -Name 'FxNonDestructiveSoftMixer' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'FxRender' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'DisableAudioEndpointDucking' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Optimisation des peripheriques de rendu audio (PowerShell)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Audio" /v DisableAudioEnhancement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v ImmersiveAudio /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Ameliorations audio desactivees - Latence reduite

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations systeme appliquees.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:OPTIMISATIONS_MEMOIRE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 2 : OPTIMISATIONS MEMOIRE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la gestion de la RAM et du fichier d'echange%COLOR_RESET%
echo %COLOR_WHITE%  pour ameliorer les performances en jeu et reduire la latence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 2.1 - Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la gestion memoire...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagefileEncryption" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemPages" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion memoire optimisee

:: 2.2 - Prefetch/SysMain
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du Prefetch et SuperFetch pour performance maximale...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1
:: Activer Superfetch et Prefetcher pour chargement ultra-rapide des applications
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Prefetch actif, SuperFetch optimise pour les jeux

:: 2.3 - FTH OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du tas tolerant aux pannes (FTH)...
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\FTH\State" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% FTH desactive - Performances memoire ameliorees

:: 2.4 - Desactiver la compression de la memoire
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la compression memoire (MMAgent)...
powershell -NoProfile -Command "try { Disable-MMAgent -mc -ErrorAction Stop } catch { Write-Warning 'MMAgent non supporte sur cette version' }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Compression memoire traitee

:: 2.5 - SvcHost - Valeur par defaut (3670016 KB)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration SvcHost valeur par defaut...
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 3670016 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% SvcHost configure valeur par defaut

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations memoire appliquees avec succes.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:OPTIMISATIONS_DISQUES
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 3 : OPTIMISATIONS DISQUES ET STOCKAGE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise les SSD/HDD pour des temps de chargement%COLOR_RESET%
echo %COLOR_WHITE%  reduits et une meilleure reactivite du systeme.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 3.1 - Configuration NTFS et TRIM
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres NTFS et activation du TRIM...
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set memoryusage 2 >nul 2>&1
fsutil behavior set mftzone 2 >nul 2>&1
fsutil behavior set disablecompression 1 >nul 2>&1
fsutil behavior set encryptpagingfile 0 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres NTFS optimises - TRIM actif, metadonnees reduites

:: 3.2 - Optimisations I/O NTFS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation I/O NTFS (NVMe)...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation des chemins longs (plus de 260 caracteres)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Support des chemins longs active

:: 3.3 - TRIM sur volumes SSD
echo %COLOR_YELLOW%[*]%COLOR_RESET% Execution du TRIM sur les disques SSD detectes...
echo %COLOR_CYAN%[INFO]%COLOR_RESET% Operation synchrone : le script attend la fin du TRIM avant de continuer.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ssd = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' }; if ($ssd) { $volumes = Get-Volume | Where-Object { $_.DriveLetter -and ($_.FileSystem -match 'NTFS|ReFS') }; foreach ($vol in $volumes) { Optimize-Volume -DriveLetter $vol.DriveLetter -ReTrim -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Commande TRIM executee sur les SSD

:: 3.4 - Optimisation pilote NVMe et DirectStorage
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation du boost NVMe et DirectStorage...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NativeNVMePerformance /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 156965516 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1853569164 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 735209102 /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Boost NVMe et DirectStorage actives

:: 3.5 - Write cache buffer flushing au niveau peripherique (SCSI + NVMe)
echo %COLOR_YELLOW%[*]%COLOR_RESET% CacheIsPowerProtected sur disques SCSI et NVMe (equiv. Write Cache Buffer Flushing Off)...
powershell -NoProfile -Command "Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI', 'HKLM:\SYSTEM\CurrentControlSet\Enum\NVMe' -ErrorAction SilentlyContinue | Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' } | ForEach-Object { $p = Join-Path -Path $_.PSPath -ChildPath 'Disk'; if((Test-Path -Path $p) -eq $false){ New-Item -Path $p -Force | Out-Null }; Set-ItemProperty -Path $p -Name 'CacheIsPowerProtected' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cle Device Parameters\Disk\CacheIsPowerProtected appliquee (SCSI + NVMe)

:: 3.6 - Defragmentation automatique geree par Windows (TRIM automatique)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification de la defragmentation automatique...
:: Windows 11 detecte automatiquement les SSD et effectue du TRIM au lieu de defragmentation
:: Il est important de NE PAS desactiver cette tache pour maintenir le TRIM automatique
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Defragmentation automatique preservee ^(TRIM automatique actif pour SSD^)

echo.
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations des disques appliquees avec succes.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:OPTIMISATIONS_GPU
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 4 : OPTIMISATIONS GPU%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise votre carte graphique pour reduire l'input lag%COLOR_RESET%
echo %COLOR_WHITE%  et maximiser les performances en jeu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 4.1 - GameDVR desactive - Game Mode ON
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'enregistrement automatique de gameplay...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "HistoricalCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_EFSEFeatureFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% GameDVR desactive - Game Mode conserve pour les performances

:: 4.2 - Preferences DirectX (Auto HDR, VRR desactive, Flip Model actif)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des preferences DirectX (Auto HDR, VRR OFF, Flip Model)...
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=1;VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DirectX : Auto HDR actif, VRR OFF, Flip Model (SwapEffectUpgrade) actif

:: 4.3 - Mode MSI (GPU) et P-State P0 (NVIDIA)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation MSI (GPU) et P0 State (Performance NVIDIA)...
powershell -NoProfile -Command "Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ Set-ItemProperty -Path $p -Name 'MSISupported' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mode MSI GPU et NVIDIA P0 optimises

:: 4.4 - Desactivation AMD telemetry
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la telemetrie AMD...
reg add "HKLM\SOFTWARE\AMD\CN" /v "CollectGIData" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ATI ACE\AUEPLauncher" /v "ReportProcessedEvents" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie AMD desactivee

:: 4.5 - NVIDIA Low Latency
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations Low Latency NVIDIA...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mode Low Latency active - Reduction de l'input lag

:: 4.6 - HAGS Enable
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la planification GPU acceleree (HAGS)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% HAGS active - Latence GPU reduite

:: 4.7 - Activation et raffinement de la preemption GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la preemption GPU (Hardware Scheduling)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Preemption GPU activee

:: 4.8 - NVIDIA Profile Inspector
:: Detection GPU NVIDIA pour Profile Inspector via PowerShell
if "!HAS_NVIDIA!"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% GPU NVIDIA detecte - Configuration NVIDIA Profile Inspector...
    set "NPI_DIR=!TEMP!\NvidiaProfileInspector"
    
    :: Creer le dossier temporaire
    if not exist "!NPI_DIR!" mkdir "!NPI_DIR!"
    
    :: Telecharger NVIDIA Profile Inspector
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe' -OutFile '!NPI_DIR!\nvidiaProfileInspector.exe' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if exist "!NPI_DIR!\nvidiaProfileInspector.exe" (
        for %%A in ("!NPI_DIR!\nvidiaProfileInspector.exe") do if %%~zA LSS 10000 (
            echo %COLOR_RED%[-]%COLOR_RESET% Erreur : Fichier NVIDIA Profile Inspector corrompu ou incomplet
            del "!NPI_DIR!\nvidiaProfileInspector.exe"
            goto :NPI_DONE
        )
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de NVIDIA Profile Inspector
        goto :NPI_DONE
    )
    
    :: Telecharger le profil optimise
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement du profil gaming optimise...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip' -OutFile '!NPI_DIR!\Kaylers_profile.nip' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if exist "!NPI_DIR!\Kaylers_profile.nip" (
        for %%A in ("!NPI_DIR!\Kaylers_profile.nip") do if %%~zA LSS 100 (
            echo %COLOR_RED%[-]%COLOR_RESET% Erreur : Profil NVIDIA corrompu ou incomplet
            del "!NPI_DIR!\Kaylers_profile.nip"
            goto :NPI_DONE
        )
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement du profil
        goto :NPI_DONE
    )
    
    :: Appliquer le profil
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Application du profil NVIDIA optimise...
    start "" "!NPI_DIR!\nvidiaProfileInspector.exe" "!NPI_DIR!\Kaylers_profile.nip"
    ping -n 2 127.0.0.1 >nul 2>&1
    taskkill /f /im nvidiaProfileInspector.exe >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Profil NVIDIA Profile Inspector applique
    
    :: Nettoyage
    del "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
    del "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
    rmdir "!NPI_DIR!" >nul 2>&1
) else (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% GPU NVIDIA non detecte - NVIDIA Profile Inspector ignore
)

:NPI_DONE
:: Fin des optimisations specifiques NVIDIA

:: 4.9 - Game Mode Windows 11 24H2/25H2
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation Game Mode Windows 11 24H2/25H2...
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Game Mode 24H2/25H2 optimise (auto-detection + overlay desactive)
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Toutes les optimisations GPU ont ete appliquees.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:OPTIMISATIONS_RESEAU
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la pile TCP/IP pour reduire le ping%COLOR_RESET%
echo %COLOR_WHITE%  et ameliorer la stabilite de la connexion en jeu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de la pile TCP/IP pour faible latence...
:: 5.1 - Optimisation du throttling reseau par MMCSS
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1

:: 5.2 - Pile TCP/UDP moderne CUBIC et BBR2
netsh int tcp set heuristics disabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
:: Correctif Loopback BBR2 (Windows 11 24H2)
netsh int ip set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
netsh int tcp set global rss=enabled rsc=disabled ecncapability=disabled >nul 2>&1
netsh int udp set global uso=enabled ero=disabled >nul 2>&1
netsh int ip set global taskoffload=disabled >nul 2>&1
netsh int ip set global sourceroutingbehavior=drop >nul 2>&1
netsh int ip set global icmpredirects=disabled >nul 2>&1
netsh int ipv6 set global neighborcachelimit=4096 >nul 2>&1
netsh int tcp set global fastopen=enabled fastopenfallback=enabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global netdma=disabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
powershell -NoProfile -NoLogo -Command "try{Set-NetTCPSetting -SettingName Internet -InitialRtoMs 2000}catch{}" >nul 2>&1

:: 5.3 - Optimisations TCP (Frequence ACK et NoDelay)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du delai ACK et NoDelay...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpDelAckTicks" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DisableTaskOffload" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1

:: 5.4 - BITS Optimization
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du service BITS (Telechargements)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "EnableBypassProxyForLocal" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOn-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOff-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Service BITS optimise

:: 5.5 - Priorites de resolution DNS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Priorite de la pile de resolution DNS...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "LocalPriority" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "HostsPriority" /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "DnsPriority" /t REG_DWORD /d 6 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Priorites DNS configurees

:: 5.6 - ISATAP/Teredo OFF
netsh int isatap set state disabled >nul 2>&1
netsh int teredo set state disabled >nul 2>&1

:: 5.7 - Nagle/DelACK OFF
powershell -NoLogo -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress } ; if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name DelayedAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name TcpDelAckTicks -PropertyType DWord -Value 0 -Force | Out-Null } }" >nul 2>&1

:: 5.8 - QoS Psched
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1

:: 5.9 - NIC RSS ON, RSC OFF, epuration bindings
powershell -NoProfile -NoLogo -Command "$adp=Get-NetAdapter|? Status -eq 'Up'; foreach($a in $adp){ try{Enable-NetAdapterRss -Name $a.Name -ErrorAction Stop}catch{}; try{Disable-NetAdapterRsc -Name $a.Name -ErrorAction Stop}catch{} }" >nul 2>&1
powershell -NoProfile -NoLogo -Command "Get-NetAdapter | ? Status -eq 'Up' | % { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lltdio' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_implat' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_rspndr' -ErrorAction SilentlyContinue }" >nul 2>&1

:: 5.10 - NIC latence faible
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration NIC pour faible latence...

:: LSO IPv4/IPv6 + RSC IPv4/IPv6 (desactiver avec gestion des noms FR/EN)
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $props = Get-NetAdapterAdvancedProperty -Name $adapter; $lsoProps = $props | Where-Object { $_.DisplayName -like '*Large Send*' -or $_.DisplayName -like '*Grand envoi*' }; foreach($prop in $lsoProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Disabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Desactive' -ErrorAction Stop } catch {} } }; $rscProps = $props | Where-Object { $_.DisplayName -like '*Recv Segment*' -or $_.DisplayName -like '*RSC*' }; foreach($prop in $rscProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Disabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Desactive' -ErrorAction Stop } catch {} } } }" >nul 2>&1

:: Ne pas forcer le pilote reseau a outrepasser l'auto-negociation du cable (evite le Packet Loss)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v "*WaitAutoNegComplete" /f >nul 2>&1
)

echo %COLOR_GREEN%[OK]%COLOR_RESET% NIC configuree - LSO/RSC off

:: 5.11 - QoS Fortnite DSCP 46
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de la QoS Fortnite (DSCP 46)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Version" /t REG_SZ /d "1.0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Application Name" /t REG_SZ /d "FortniteClient-Win64-Shipping.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Protocol" /t REG_SZ /d "17" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Local Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Remote Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Local IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Remote IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "DSCP Value" /t REG_SZ /d "46" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Version" /t REG_SZ /d "1.0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Application Name" /t REG_SZ /d "FortniteClient-Win64-Shipping.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Protocol" /t REG_SZ /d "6" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Local Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Remote Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Local IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Remote IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "DSCP Value" /t REG_SZ /d "46" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% QoS Fortnite activee

:: 5.12 - Desactivation NetBIOS over TCP/IP (WINS)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de NetBIOS over TCP/IP...
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s ^| findstr /i /r "\\Tcpip_.*$" 2^>nul') do (
  reg add "%%i" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% NetBIOS desactive

gpupdate /target:computer /force >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Pile reseau optimisee avec priorite gaming

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations reseau appliquees avec succes.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:OPTIMISATIONS_PERIPHERIQUES
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 6 : OPTIMISATIONS CLAVIER ET SOURIS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive l'acceleration souris et optimise%COLOR_RESET%
echo %COLOR_WHITE%  la reactivite des peripheriques d'entree.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 6.1 - Souris optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'acceleration souris et des delais...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseDelay" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "SnapToDefaultButton" /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Acceleration souris desactivee - Mouvement 1:1 actif
 
:: 6.2 - Clavier optimise
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la reactivite clavier...
reg add "HKCU\Control Panel\Keyboard" /v "KeyboardDelay" /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v "KeyboardSpeed" /t REG_SZ /d "31" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Clavier configure - Delai minimal et vitesse maximale

:: 6.3 - Accessibilite OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des raccourcis d'accessibilite...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourcis d'accessibilite desactives

:: 6.4 - DMA Remapping OFF
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PnP\Pci" /v DmaRemappingCompatible /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DMA Remapping desactive - Reduction de la latence

:: 6.5 - HID parse optimise
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableInputDelayOptimization" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableBufferedInput" /t REG_DWORD /d 0 /f >nul 2>&1

:: 6.6 - Priorites clavier/souris
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "ThreadPriority" /t REG_DWORD /d 15 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "ThreadPriority" /t REG_DWORD /d 15 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "ThreadPriority" /t REG_DWORD /d 15 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Priorites et files clavier/souris optimisees

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations des peripheriques appliquees avec succes.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:TOGGLE_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section permet de gerer les economies d'energie du systeme.%COLOR_RESET%
echo %COLOR_WHITE%  Les PC de bureau peuvent desactiver ces fonctions pour maximiser%COLOR_RESET%
echo %COLOR_WHITE%  les performances. Les PC portables peuvent les conserver.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver les economies d'energie (Performances maximales)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer les economies d'energie (Parametres par defaut)%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if %errorlevel% EQU 3 goto :MENU_PRINCIPAL
if %errorlevel% EQU 2 goto :RESTAURER_ECONOMIES_ENERGIE
if %errorlevel% EQU 1 goto :DESACTIVER_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DESACTIVER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : DESACTIVATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les fonctions d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  pour maintenir les performances maximales en permanence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 7.1 - Energie Systeme et GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des seuils d'economie d'energie...
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: GPU Power Management (ULPS & PowerMizer)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'ULPS (AMD) et configuration PowerMizer (NVIDIA)...
:: ULPS OFF - AMD
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v EnableUlps_NA /t REG_DWORD /d 0 /f >nul 2>&1
)
:: PowerMizer - NVIDIA (Applique a toutes les instances GPU)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PowerMizerEnable /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PerfLevelSrc /t REG_DWORD /d 2222 /f >nul 2>&1
  reg add "%%K" /v DisableDynamicPstate /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v RmDisableRegistryCaching /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% GPU Power Management optimise

:: 7.2 - NIC Energy Saving Ethernet et WiFi
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des economies d'energie reseau (NIC - Ethernet et WiFi)...
powershell -NoProfile -Command "Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p = $_.Name; reg add \"$p\" /v \"PnPCapabilities\" /t REG_DWORD /d 8 /f >$null; reg add \"$p\" /v \"AdvancedEEE\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*EEE\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"EEELinkAdvertisement\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"SipsEnabled\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"ULPMode\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"GigaLite\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"EnableGreenEthernet\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"PowerSavingMode\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"S5WakeOnLan\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*WakeOnMagicPacket\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*WakeOnPattern\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"WakeOnLink\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*ModernStandbyWoLMagicPacket\" /t REG_SZ /d \"0\" /f >$null }" >nul 2>&1
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $energyProps = @('Energy-Efficient Ethernet','Green Ethernet','Power Saving Mode','Gigabit Lite','Ethernet a economie d''energie','Ethernet vert','802.11 Power Save','Power Management','Allow the computer to turn off this device','Gestion de l''alimentation 802.11','Mode d''economie d''energie','Power Save Mode'); foreach($propName in $energyProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Disabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Desactive' -ErrorAction Stop } catch {} } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie NIC desactivees (Registre + Pilotes)


:: 7.3 - Activation du plan Ultimate Performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification du plan d'alimentation actif...

set "TARGET_GUID="

:: Etape 1 - Chercher par le GUID specifique d'origine
for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do (
    set "TARGET_GUID=%%G"
    set "TARGET_GUID=!TARGET_GUID: =!"
)

:: Etape 2 - Si non present, chercher le GUID duplique (cree precedemment par ce script)
if not defined TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "99999999-9999-9999-9999-999999999999"') do (
        set "TARGET_GUID=%%G"
        set "TARGET_GUID=!TARGET_GUID: =!"
    )
)

:: Etape 3 - Si non present, chercher par NOM ("Ultimate" ou "optimales") pour assurer la retrocompatibilite avec les anciennes versions du script
if not defined TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "Ultimate optimales"') do (
        set "TARGET_GUID=%%G"
        set "TARGET_GUID=!TARGET_GUID: =!"
    )
)

:: Si le plan existe (origine ou notre copie), verifier s'il est deja actif
if defined TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg /getactivescheme 2^>nul') do set "ACTIVE_GUID=%%G"
    set "ACTIVE_GUID=!ACTIVE_GUID: =!"
    if "!ACTIVE_GUID!"=="!TARGET_GUID!" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate/Optimal deja actif - aucune action requise
        goto :ULTIMATE_DONE
    )
    :: Le plan existe mais n'est pas actif
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Plan Ultimate/Optimal detecte - Activation...
    powercfg -setactive !TARGET_GUID! >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate/Optimal active
    goto :ULTIMATE_DONE
)

:: Le plan n'existe pas, on le cree avec notre GUID personnalise pour eviter les doublons futurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% Plan "Performances optimales" non present - Creation...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1
set "TARGET_GUID=99999999-9999-9999-9999-999999999999"

echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan "Performances optimales" cree et active
powercfg -setactive !TARGET_GUID! >nul 2>&1

:ULTIMATE_DONE

:: 7.4 - Parametres avances du plan d'alimentation (user standard)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration avancee du plan d'alimentation...


:: Disque dur : ne jamais eteindre
powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1


:: Diaporama arriere-plan : en pause (economise CPU)
powercfg /setacvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1


:: Adaptateur Wi-Fi : performances maximales (pas de bridage Wi-Fi silencieux)
powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1


:: Veille hybride : desactivee (inutile si hibernate est off)
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0 >nul 2>&1
:: Hibernation apres : jamais
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0 >nul 2>&1


:: Hub selective suspend timeout : 0ms
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0 >nul 2>&1
:: USB 3 link power management : desactive
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1


:: Etat processeur max : 100%
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
:: Politique de refroidissement : actif (ventilateur reactif)
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 >nul 2>&1


:: Extinction ecran apres 10 min (protection OLED + economie)
powercfg /setacvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 >nul 2>&1



:: Biais qualite lecture video : performance
powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 >nul 2>&1
:: Lecture video : qualite optimale
powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 >nul 2>&1


:: Intel Graphics : performances maximales
powercfg /setacvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2 >nul 2>&1
:: AMD power slider : meilleures performances
powercfg /setacvalueindex SCHEME_CURRENT c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 >nul 2>&1
:: ATI Powerplay : performances maximales
powercfg /setacvalueindex SCHEME_CURRENT f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1 >nul 2>&1
:: GPU hybride switchable : performances maximales
powercfg /setacvalueindex SCHEME_CURRENT e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3 >nul 2>&1


:: Appliquer le plan
powercfg /S SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres avances du plan d'alimentation appliques

:: 7.5 - Optimisations CPU (Intel Hybrid + AMD Core Parking)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisations CPU specifiques (Intel Hybrid / AMD Ryzen)...

:: Intel Hybrid CPUs (Alder Lake/Raptor Lake/Meteor Lake) - Scheduling Policy
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration Intel Thread Director (Hybrid CPUs)...
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Intel Thread Director configure (P-cores prioritaires)

:: AMD Ryzen - Desactivation Core Parking
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation Core Parking (AMD Ryzen)...
:: Appliquer immediatement : desactiver le core parking via powercfg sur le plan actif
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318584 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318584 0 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Core Parking desactive (AMD Ryzen optimise)

:: 7.6 - Desactivation economies d'energie Device Manager (ACPI/HID/PCI/USB)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de l'alimentation des peripheriques (Device Manager)...
powershell -NoProfile -Command "$p=@('ACPI','HID','PCI','USB','USBSTOR'); foreach($s in $p){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Enum\$s\" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' -or $_.PSChildName -eq 'WDF' } | ForEach-Object { $rp = $_.Name; if($_.PSChildName -eq 'Device Parameters'){ reg add \"$rp\" /v \"EnhancedPowerManagementEnabled\" /t REG_DWORD /d 0 /f >$null; reg add \"$rp\" /v \"SelectiveSuspendEnabled\" /t REG_BINARY /d \"00\" /f >$null; reg add \"$rp\" /v \"SelectiveSuspendOn\" /t REG_DWORD /d 0 /f >$null; reg add \"$rp\" /v \"WaitWakeEnabled\" /t REG_DWORD /d 0 /f >$null } else { reg add \"$rp\" /v \"IdleInWorkingState\" /t REG_DWORD /d 0 /f >$null } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie Device Manager desactivees (HID/PCI/USB)

:: 7.7 - MODE MSI GENERALISE (GPU, NETWORK, USB)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation du mode MSI partout (GPU, Reseau, USB)...
powershell -NoProfile -Command "Get-PnpDevice | Where-Object { $_.Class -match 'Display|USB|Net' } | ForEach-Object { $id = $_.InstanceId; reg add \"HKLM\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties\" /v \"MSISupported\" /t REG_DWORD /d 1 /f }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mode MSI active (Message Signaled Interrupts)

:: 7.8 - Desactivation des plans d'alimentation High Performance Overlay
:: Ces plans sont deja geres par le plan Ultimate Performance

:: 7.9 - Desactivation du demarrage rapide Fast Startup
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du demarrage rapide (Fast Startup)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Demarrage rapide desactive - Redemarrages propres

:: 7.10 - Desactivation de l'hibernation PC Bureau uniquement
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'hibernation ^(PC Bureau^)...
    powercfg /hibernate off >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Hibernation desactivee - Espace disque libere
) else (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% Hibernation conservee ^(PC Portable detecte^)
)

:: 7.11 - USB Selective Suspend (Optimisation latence)
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation USB - Desactivation de la mise en veille selective...
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    powercfg /S SCHEME_CURRENT >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% USB optimise - Latence minimale ^(Selective Suspend OFF^)
) else (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% USB Selective Suspend conserve ^(PC Portable detecte^)
)

:: 7.12 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du systeme d'alimentation...
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\SUB_ENERGYSAVER\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.13 - Desactivation des Timer Coalescing et DPC
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Timer Coalescing et optimisation DPC...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MinimumDpcRate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
bcdedit /set disabledynamictick yes >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\ModernSleep" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Timer Coalescing desactive - Latence reduite

:: 7.14 - Installation SetTimerResolution
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de SetTimerResolution...
set "STR_EXE=%SystemRoot%\SetTimerResolution.exe"
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"

:: Verifier si deja installe
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution deja installe dans %SystemRoot%
    goto :STR_SHORTCUT
)

:: Telecharger SetTimerResolution.exe
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe' -OutFile '%STR_EXE%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if exist "%STR_EXE%" (
    for %%A in ("%STR_EXE%") do if %%~zA LSS 5000 (
        echo %COLOR_RED%[-]%COLOR_RESET% Erreur : SetTimerResolution.exe corrompu ou incomplet
        del "%STR_EXE%"
        goto :STR_DONE
    )
    echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution installe dans %SystemRoot%
    goto :STR_SHORTCUT
) else (
    echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de SetTimerResolution
    goto :STR_DONE
)

:STR_SHORTCUT
:: Verifier si raccourci existe deja
if exist "%STR_STARTUP%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci de demarrage deja present
    goto :STR_DONE
)

:: Creer le raccourci de demarrage dynamiquement
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STR_STARTUP%'); $Shortcut.TargetPath = '%SystemRoot%\SetTimerResolution.exe'; $Shortcut.Arguments = '--no-console'; $Shortcut.WorkingDirectory = '%SystemRoot%'; $Shortcut.Description = 'SetTimerResolution - Optimizer'; $Shortcut.Save()" >nul 2>&1
if exist "%STR_STARTUP%" (
    for %%A in ("%STR_STARTUP%") do if %%~zA LSS 100 (
        echo %COLOR_RED%[-]%COLOR_RESET% Erreur : Raccourci SetTimerResolution invalide
        del "%STR_STARTUP%"
        goto :STR_DONE
    )
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci ajoute au demarrage automatique
) else (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% Impossible de creer le raccourci - creation manuelle recommandee
)

:STR_DONE

:: 7.15 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du Power Throttling (bridage CPU)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.16 - Gestion processeur equilibree
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil processeur (performances maximales)...
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1

:: 7.17 - Intel AMD Hybrid CPU Scheduling Visibility
echo %COLOR_YELLOW%[*]%COLOR_RESET% Deblocage des options de scheduling hybride (P-Cores/E-Cores)...
:: Heterogeneous thread scheduling policy
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
:: Core Parking (P-cores class 1)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
:: Core Parking (E-cores class 0)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1

:: 7.18 - Desactivation ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation ASPM sur le bus PCI Express...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.19 - Optimisations stockage et disques (DirectStorage haute consommation)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la mise en veille des disques et DirectStorage haute consommation...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /t REG_DWORD /d 1 /f >nul 2>&1
:: DirectStorage : mode haute consommation (NVMe perf max + decompression GPU)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "ForcedLowPowerMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDecompressionInGPU" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDirectStorage" /t REG_DWORD /d 1 /f >nul 2>&1
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Set-ItemProperty -Path $p -Name 'EnableHIPM' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'EnableDIPM' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'EnableHDDParking' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1

:: 7.20 - Optimisations avancees des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des limites de latence I/O...
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Set-ItemProperty -Path $p -Name 'IoLatencyCap' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Limites de latence stockage supprimees

:: 7.21 - GPU PreferMaxPerf
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration GPU en mode performances maximales...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% GPU configure en mode performances maximales

:: 7.22 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la mise en veille des peripheriques PCI...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "*WakeOnPattern" /t REG_DWORD /d 0 /f >nul 2>&1
)

:: 7.23 - Cartes reseau (aligne Ultimate 18 : toutes les instances + CurrentControlSet et ControlSet001)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des fonctions d'economie d'energie reseau...
powershell -NoProfile -Command "Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; $props=@{'*EEE'='0';'*SelectiveSuspend'='0';'*WakeOnMagicPacket'='0';'*ModernStandbyWoLMagicPacket'='0';'EnableGreenEthernet'='0';'ULPMode'='0';'*WakeOnPattern'='0';'*PMARPOffload'='0';'*PMNSOffload'='0';'EnablePME'='0';'PowerSavingMode'='0';'ReduceSpeedOnPowerDown'='0';'EnableDynamicPowerGating'='0';'AutoPowerSaveModeEnabled'='0';'AdvancedEEE'='0';'EEELinkAdvertisement'='0';'GigaLite'='0';'S5WakeOnLan'='0';'WakeOnLink'='0';'SipsEnabled'='0';'*FlowControl'='0';'*InterruptModeration'='1';'*InterruptModerationRate'='2';'ITR'='0';'EnableLLI'='1';'EnableDownShift'='0'}; foreach($n in $props.Keys){ Set-ItemProperty -Path $p -Name $n -Value $props[$n] -Force -ErrorAction SilentlyContinue }; Set-ItemProperty -Path $p -Name 'PnPCapabilities' -Value 24 -Type DWord -Force -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie et optimisations reseau appliquees sur toutes les cartes

:: 7.24 - Energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation gestion d'energie PCIe...
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie PCIe desactivee
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "DisableASPM" /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v "RMForcedMaxPerf" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% GPU optimise

:: 7.25 - Desactivation economies d'energie sur TOUS les devices (ACPI/HID/PCI/USB -- aligne Ultimate 17)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation economies d'energie sur TOUS les peripheriques (ACPI, HID, PCI, USB)...
powershell -NoProfile -Command "$bases=@('HKLM:\SYSTEM\CurrentControlSet\Enum\ACPI','HKLM:\SYSTEM\CurrentControlSet\Enum\HID','HKLM:\SYSTEM\CurrentControlSet\Enum\PCI','HKLM:\SYSTEM\CurrentControlSet\Enum\USB','HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR'); foreach($base in $bases){ if(Test-Path $base){ Get-ChildItem -Path $base -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' } | ForEach-Object { $p=$_.PSPath; Set-ItemProperty -Path $p -Name EnhancedPowerManagementEnabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name SelectiveSuspendEnabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name SelectiveSuspendOn -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name WaitWakeEnabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue }; Get-ChildItem -Path $base -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'WDF' } | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name IdleInWorkingState -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Power savings desactivees sur tous les devices ACPI, HID, PCI et USB
 
:: 7.26 - Bridage Energie (Power Throttling) deja traite en section 7.15
echo %COLOR_GREEN%[OK]%COLOR_RESET% Power Throttling (bridage CPU) deja configure

:: 7.27 - Desactivation Windows Platform Binary Table (WPBT)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation WPBT (anti bloatware OEM firmware)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% WPBT desactive
 
:: 7.28 - Nettoyage des protocoles reseau (Bindings)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protocoles reseau inutiles (Bindings)...
powershell -NoProfile -Command "$bindingIds = @('ms_lldp', 'ms_lltdio', 'ms_implat', 'ms_rspndr'); $nics = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }; foreach ($nic in $nics) { foreach ($id in $bindingIds) { Disable-NetAdapterBinding -Name $nic.Name -ComponentID $id -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Bindings reseau nettoyes (LLDP, LLTDIO, etc.)

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Economies d'energie desactivees - Performances maximales activees.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:RESTAURER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : RESTAURATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section restaure les parametres d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  aux valeurs par defaut de Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 7.4 - Plan d'alimentation par defaut (Equilibre)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration du plan d'alimentation par defaut...
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan d'alimentation "Equilibre" active

:: 7.5 - Demarrage rapide (Fast Startup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation du demarrage rapide (Fast Startup)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Demarrage rapide reactive

:: 7.6 - Hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de l'hibernation...
powercfg /hibernate on >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Hibernation reactive

:: 7.7 - USB Selective Suspend
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation USB Selective Suspend...
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% USB Selective Suspend reactive

:: 7.8 - Timer Coalescing
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des Timer Coalescing...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MinimumDpcRate /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /f >nul 2>&1
bcdedit /set disabledynamictick no >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\ModernSleep" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Timer Coalescing reactive

:: 7.9 - SetTimerResolution du demarrage
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression de SetTimerResolution du demarrage...
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
if exist "%STR_STARTUP%" (
    del "%STR_STARTUP%" /f /q >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci SetTimerResolution supprime du demarrage
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution n'etait pas dans le demarrage
)

:: 7.10 - Optimisations CPU (Intel Hybrid + AMD Core Parking)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des optimisations CPU...

:: Restaurer Intel Thread Director
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration Intel Thread Director...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Intel Thread Director restaure

:: Restaurer AMD Core Parking
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration Core Parking (AMD Ryzen)...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
:: Reactiver le core parking via powercfg
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318584 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318584 1 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Core Parking restaure

:: 7.11 - Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation du Power Throttling...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1

:: 7.12 - Seuils d'economie d'energie
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 20 >nul 2>&1

:: 7.13 - ULPS (AMD) et PowerMizer (Auto)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration de l'ULPS (AMD) et PowerMizer (Auto)...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v EnableUlps /f >nul 2>&1
  reg delete "%%K" /v EnableUlps_NA /f >nul 2>&1
  reg delete "%%K" /v PowerMizerEnable /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevel /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevelAC /f >nul 2>&1
  reg delete "%%K" /v PerfLevelSrc /f >nul 2>&1
  reg delete "%%K" /v DisableDynamicPstate /f >nul 2>&1
  reg delete "%%K" /v RmDisableRegistryCaching /f >nul 2>&1
)

:: 7.14 - Economies d'energie reseau (NIC)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des economies d'energie reseau (NIC)...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $energyProps = @('Energy-Efficient Ethernet','Green Ethernet','Power Saving Mode','Gigabit Lite','Ethernet a economie d''energie','Ethernet vert','802.11 Power Save','Power Management','Allow the computer to turn off this device','Gestion de l''alimentation 802.11','Mode d''economie d''energie','Power Save Mode'); foreach($propName in $energyProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Enabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Enabled' -ErrorAction Stop } catch {} } }; try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Interrupt Moderation' -DisplayValue 'Enabled' -ErrorAction SilentlyContinue } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Moderation interruption' -DisplayValue 'Active' -ErrorAction SilentlyContinue } catch {} }; try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Interrupt Moderation Rate' -DisplayValue 'Moderate' -ErrorAction SilentlyContinue } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Taux de moderation des interruptions' -DisplayValue 'Modere' -ErrorAction SilentlyContinue } catch {} }; try { Set-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword '*InterruptModeration' -RegistryValue 1 -ErrorAction SilentlyContinue } catch {}; try { Set-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword '*InterruptModerationRate' -RegistryValue 2 -ErrorAction SilentlyContinue } catch {} }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie NIC restaurees (Ethernet + WiFi)

:: 7.15 - Parametres processeur par defaut
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des parametres processeur par defaut...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 30 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 10 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres processeur restaures

:: 7.17 - ASPM (PCI Express)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation ASPM sur le bus PCI Express...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% ASPM reactive

:: 7.18 - Mise en veille des disques et DirectStorage
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de la mise en veille des disques et DirectStorage par defaut...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /f >nul 2>&1
:: Revert DirectStorage haute consommation
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "ForcedLowPowerMode" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDecompressionInGPU" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDirectStorage" /f >nul 2>&1
:: Supprimer HIPM/DIPM/HDDParking pour revenir aux valeurs par defaut systeme
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnableHIPM','EnableDIPM','EnableHDDParking' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mise en veille des disques reactivee

:: 7.19 - Limites de latence I/O
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des limites de latence I/O...
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IoLatencyCap' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Limites de latence I/O restaurees

:: 7.20 - Gestion d'energie GPU et DirectX
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration de la gestion d'energie GPU et preferences DirectX...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v PreferMaxPerf /f >nul 2>&1
)
:: Revert Auto HDR et DirectX UserGpuPreferences
reg delete "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie GPU et preferences DirectX restaurees
:: 7.21 - Gestion d'energie PCI
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de la gestion d'energie PCI...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v D3ColdSupported /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v "*WakeOnPattern" /f >nul 2>&1
)

:: 7.22 - Fonctions d'economie d'energie reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des fonctions d'economie d'energie reseau...
powershell -NoProfile -Command "Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI' -ErrorAction SilentlyContinue | ForEach-Object { Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object { $p = Join-Path -Path $_.PSPath -ChildPath 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ Set-ItemProperty -Path $p -Name 'MSISupported' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fonctions d'economie d'energie reseau reactivees

:: 7.23 - Systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration du systeme d'alimentation...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Systeme d'alimentation restaure

:: 7.24 - Peripheriques ACPI/HID/PCI/USB
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des parametres d'economie des peripheriques ACPI, HID, PCI et USB...
powershell -NoProfile -Command "$bases=@('HKLM:\SYSTEM\CurrentControlSet\Enum\ACPI','HKLM:\SYSTEM\CurrentControlSet\Enum\HID','HKLM:\SYSTEM\CurrentControlSet\Enum\PCI','HKLM:\SYSTEM\CurrentControlSet\Enum\USB','HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR'); foreach($b in $bases){ Get-ChildItem -Path $b -ErrorAction SilentlyContinue | ForEach-Object { $p = Join-Path -Path $_.PSPath -ChildPath 'Device Parameters'; if(Test-Path $p){ Remove-ItemProperty -Path $p -Name 'EnhancedPowerManagementEnabled','SelectiveSuspendEnabled','DeviceSelectiveSuspended' -ErrorAction SilentlyContinue } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres d'economie des peripheriques restaures

:: 7.25 - Gestion d'energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation gestion d'energie PCIe...
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie PCIe reactivee

:: 7.26 - Plans d'alimentation avances
echo %COLOR_YELLOW%[*]%COLOR_RESET% Masquage des plans d'alimentation avances...
powershell -NoProfile -Command "powercfg /attributes SUB_PROCESSOR 75b0ae3f-bce0-45a7-8c89-c9611c25e100 +ATTRIB_HIDE" >nul 2>&1
powershell -NoProfile -Command "powercfg /attributes SUB_PROCESSOR ea062031-0e34-4ff1-9b6d-eb1059334028 +ATTRIB_HIDE" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Plans d'alimentation avances masques

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Economies d'energie restaurees - Parametres par defaut actifs.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:TOGGLE_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section permet de desactiver ou restaurer les mitigations%COLOR_RESET%
echo %COLOR_WHITE%  de securite sensibles (Spectre/Meltdown, noyau, CI policy).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver Protections Securite (mode perf)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer Protections Securite (recommande)%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if %errorlevel% EQU 3 goto :MENU_PRINCIPAL
if %errorlevel% EQU 2 goto :RESTAURER_PROTECTIONS_SECURITE
if %errorlevel% EQU 1 goto :DESACTIVER_PROTECTIONS_SECURITE
goto :TOGGLE_PROTECTIONS_SECURITE

:DESACTIVER_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : DESACTIVATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% AVERTISSEMENT :
echo %COLOR_WHITE%  Cette section desactive les protections contre les vulnerabilites%COLOR_RESET%
echo %COLOR_WHITE%  materielles (Spectre, Meltdown) et certaines mitigations noyau.%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Avantages : Reduction de la latence systeme, moins d'overhead CPU%COLOR_RESET%
echo %COLOR_WHITE%  Risques   : Exposition a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "%SKIP_PAUSE%"=="0" (
echo.
echo %COLOR_WHITE%  Pourquoi demander une confirmation :%COLOR_RESET%
echo %COLOR_WHITE%  - Les mitigations Spectre/Meltdown et noyau limitent les fuites de donnees%COLOR_RESET%
echo %COLOR_WHITE%    via le CPU ; les desactiver peut ameliorer perfs/latence mais affaiblit la defense.%COLOR_RESET%
echo %COLOR_WHITE%  - La blocklist de pilotes vulnerables aide Windows a bloquer des drivers dangereux.%COLOR_RESET%
echo %COLOR_WHITE%  - Ces cles de registre sont sensibles : erreur = instabilite ou surface d'attaque.%COLOR_RESET%
echo %COLOR_WHITE%  - Indique surtout pour bench/jeux competitifs sur machine isolee et comprise.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :MENU_PRINCIPAL
)

:: 8.1 - Desactivation des protections Kernel SEHOP Exception Chain 
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protections noyau (SEHOP, Exception Chain)... 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections noyau desactivees 

:: 8.2 - Desactivation Spectre Meltdown Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protections Spectre/Meltdown...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCfg /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections Spectre/Meltdown desactivees

:: 8.3 - Desactivation des mitigations CPU avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des mitigations CPU (KVAS, STIBP, Retpoline)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mitigations CPU desactivees

:: 8.4 - HVCI et CFG conserves pour compatibilite anti-cheat
echo %COLOR_YELLOW%[*]%COLOR_RESET% Conservation du HVCI/CFG (requis pour Valorant, Fortnite, etc.)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
:: CFG doit rester ACTIVE pour Vanguard (Valorant)
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% HVCI/CFG conserves (compatibilite anti-cheat)
 
:: Vulnerable Driver Blocklist (WinSux)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation CI Policy (Driver Blocklist)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Blocklist de pilotes vulnerables desactivee
 
:: USB Polling / WHQL Settings
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Debridage du polling rate USB ^(WHQL Settings^)...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Debridage USB active ^(Desktop uniquement^)
)

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
:: 8.5 - Protection VBS / Core Isolation (HVCI) - Activee pour Valorant
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation du VBS / Core Isolation (Exigence Vanguard)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% VBS/HVCI active (Compatibilite Anti-cheat)

echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Protections de securite desactivees.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :TOGGLE_PROTECTIONS_SECURITE
)
exit /b

:RESTAURER_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : RESTAURATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
:: 8.1 - Protections noyau (SEHOP, Exception Chain)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des protections noyau (SEHOP, Exception Chain)...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections noyau restaurees
echo.
:: 8.2 - Mitigations Spectre/Meltdown et CPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des mitigations Spectre/Meltdown et CPU...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mitigations CPU restaurees
echo.
:: 8.3 - Blocklist de pilotes vulnerables (WinSux)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de la blocklist de pilotes vulnerables...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% CI policy restauree
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Protections de securite restaurees.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
    goto :TOGGLE_PROTECTIONS_SECURITE
)
exit /b

:TOGGLE_DEFENDER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Windows Defender (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Windows Defender (Non recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if %errorlevel% EQU 3 goto :MENU_GESTION_WINDOWS
if errorlevel 2 (
  call :DESACTIVER_DEFENDER_SECTION

  goto :TOGGLE_DEFENDER
)
call :ACTIVER_DEFENDER_SECTION
goto :TOGGLE_DEFENDER

:: ___DEFENDER_ULT_EMBEDDED_SUBS___
:ACTIVER_DEFENDER_SECTION
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %STYLE_BOLD%Reactivation de Windows Defender...%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 5 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des services Windows Defender...
sc config WinDefend start= auto >nul 2>&1
for %%S in (WdNisSvc Sense SecurityHealthService) do sc config %%S start= demand >nul 2>&1
for %%S in (WdBoot WdFilter) do sc config %%S start= boot >nul 2>&1
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService) do sc start %%S >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de la protection en temps reel...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScriptScanning /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v DisableAsyncScanOnOpen /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des politiques Windows Defender...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableBlockAtFirstSeen /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRoutinelyTakingAction /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v VerifiedAndReputableTrustModeEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v SmartLockerMode /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de SmartScreen...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /t REG_SZ /d "Warn" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Warn" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des taches planifiees...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Update" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Enable >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% Services Defender restaures
call :FINISH_ACTION "Windows Defender" "reactive"
exit /b

:DESACTIVER_DEFENDER_SECTION
if "%SKIP_PAUSE%"=="0" (
    cls
    echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
    echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER WINDOWS DEFENDER%COLOR_RESET%
    echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
    echo.
    echo %COLOR_RED%[INFO]%COLOR_RESET% ATTENTION: Desactiver Windows Defender expose votre systeme a des risques.
    choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N]: %COLOR_RESET%"
    if errorlevel 2 exit /b
)
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %STYLE_BOLD%Desactivation de Windows Defender...%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des services Windows Defender...
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService) do sc stop %%S >nul 2>&1
for %%S in (WinDefend WdNisSvc Sense WdBoot WdFilter WdNisDrv SecurityHealthService) do sc config %%S start= disabled >nul 2>&1
for %%S in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend SecurityHealthService) do reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la protection en temps reel...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScriptScanning" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v "DisableAsyncScanOnOpen" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des politiques Windows Defender...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "VerifiedAndReputableTrustModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "SmartLockerMode" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des taches planifiees (Defender/ExploitGuard)...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Update" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Disable >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de SmartScreen...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% Services Defender desactives
call :FINISH_ACTION "Windows Defender" "desactive"
exit /b

:TOGGLE_UAC
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER UAC (CONTROLE DE COMPTE UTILISATEUR)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC + Avertissements (Pour LAB)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if %errorlevel% EQU 3 goto :MENU_GESTION_WINDOWS
if errorlevel 2 (
  call :DESACTIVER_UAC_SECTION
  goto :TOGGLE_UAC
)
call :ACTIVER_UAC_SECTION
goto :TOGGLE_UAC

:ACTIVER_UAC_SECTION
cls
echo %COLOR_GREEN%[OK]%COLOR_RESET% Activation de l'UAC et des avertissements...
echo.

:: UAC normal
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1

:: SmartScreen Explorer par defaut
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Warn" /f >nul 2>&1

:: Reactiver le suivi de zone (fichiers telecharges marques comme Internet)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 2 /f >nul 2>&1
call :FINISH_ACTION "UAC" "active"
exit /b

:DESACTIVER_UAC_SECTION
if "%SKIP_PAUSE%"=="0" (
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une derniere confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- L'UAC demande une elevation explicite avant qu'un programme obtienne des droits admin.%COLOR_RESET%
echo %COLOR_WHITE%- La desactivation supprime ces invites : un malware peut agir sans boite de dialogue.%COLOR_RESET%
echo %COLOR_WHITE%- Ce script desactive aussi des avertissements SmartScreen / marquage zone Internet.%COLOR_RESET%
echo %COLOR_WHITE%- Reserve aux bancs de test ou utilisateurs conscients du risque.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% LAB UNIQUEMENT : plus aucun avertissement au lancement de fichiers.
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC et les avertissements lies ? [O/N]: %COLOR_RESET%"
if errorlevel 2 exit /b
)
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %STYLE_BOLD%Desactivation complete de l'UAC et des avertissements...%COLOR_RESET%
if "%SKIP_PAUSE%"=="1" echo %COLOR_YELLOW%[^!]%COLOR_RESET% LAB UNIQUEMENT : plus aucun avertissement au lancement de fichiers.
if "%SKIP_PAUSE%"=="1" echo.

:: UAC OFF = plus de demande Oui/Non
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactiver SmartScreen Explorer
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul 2>&1

:: Desactiver "Ce fichier provient d'Internet" (Zone.Identifier)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 1 /f >nul 2>&1
call :FINISH_ACTION "UAC" "desactive"
exit /b

:TOGGLE_ANIMATIONS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer les animations Windows (experience utilisateur standard)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver les animations Windows (pour optimiser les performances)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if %errorlevel% EQU 3 goto :MENU_GESTION_WINDOWS
if errorlevel 2 (
  call :DESACTIVER_ANIMATIONS_SECTION
  goto :TOGGLE_ANIMATIONS
)
call :ACTIVER_ANIMATIONS_SECTION
goto :TOGGLE_ANIMATIONS

:ACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_GREEN%[OK]%COLOR_RESET% Activation des animations Windows...
echo.

:: VisualFXSetting=3 (Personnalise) pour que Windows utilise uniquement les cles
:: individuelles ci-dessous sans recalculer tous les effets (ce qui reset le menu Demarrer)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v TooltipAnimation /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SelectionFade /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AnimateWindow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ComboboxAnimation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1

:: Activer les effets visuels supplementaires
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "1" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /f >nul 2>&1

:: Supprimer la politique DisableStartupAnimation
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /f >nul 2>&1

:: Reactiver l'animation de demarrage Windows
bcdedit /set bootuxdisabled off >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% Animations Windows activees.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% Un redemarrage est requis pour appliquer les modifications.
if "%SKIP_PAUSE%"=="0" pause
exit /b

:DESACTIVER_ANIMATIONS_SECTION
if "%SKIP_PAUSE%"=="0" (
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une derniere confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Les animations consomment un peu de GPU/CPU ; les couper peut fluidifier un PC faible.%COLOR_RESET%
echo %COLOR_WHITE%- Cela modifie le registre utilisateur et bcdedit ^(animation du logo au demarrage^).%COLOR_RESET%
echo %COLOR_WHITE%- L'interface parait plus ?? seche ?? ^(transparence, barres des taches, menus^).%COLOR_RESET%
echo %COLOR_WHITE%- Un redemarrage est necessaire pour tout voir ; reversible via le menu Activer.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver les animations Windows ? [O/N]: %COLOR_RESET%"
if errorlevel 2 exit /b
)
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des animations Windows...
echo.

:: VisualFXSetting=3 (Personnalise) pour que Windows utilise uniquement les cles
:: individuelles ci-dessous sans recalculer tous les effets (ce qui reset le menu Demarrer)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v TooltipAnimation /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SelectionFade /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AnimateWindow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ComboboxAnimation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1

:: Garder les options utiles actives (Police, Ombre icone, Drag content)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "0" /f >nul 2>&1

:: Animation demarrage OFF
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1

:: Desactivation de l'animation de demarrage Windows
bcdedit /set bootuxdisabled on >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% Animations Windows desactivees.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% Un redemarrage est requis pour appliquer les modifications.
if "%SKIP_PAUSE%"=="0" pause
exit /b

:TOGGLE_COPILOT
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER COPILOT / WIDGETS / RECALL (WINDOWS 11)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Ces fonctionnalites sont specifiques a Windows 11.%COLOR_RESET%
echo %COLOR_WHITE%Si vous etes sur Windows 10, ces options n'auront pas d'effet.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_BLUE%--- COPILOT ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Copilot%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Copilot%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- WIDGETS ---%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Activer les Widgets%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_RED%Desactiver les Widgets%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- RECALL (Windows 11 24H2) ---%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Activer Recall%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desactiver Recall%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_RED%Desactiver TOUT (Copilot + Widgets + Recall)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 123456DM /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-6, D, M]: %COLOR_RESET%"
if %errorlevel% EQU 8 goto :MENU_GESTION_WINDOWS
if errorlevel 7 (
  call :DESACTIVER_TOUT_COPILOT
  goto :TOGGLE_COPILOT
)
if errorlevel 6 (
  call :DESACTIVER_RECALL
  goto :TOGGLE_COPILOT
)
if errorlevel 5 (
  call :ACTIVER_RECALL
  goto :TOGGLE_COPILOT
)
if errorlevel 4 (
  call :DESACTIVER_WIDGETS
  goto :TOGGLE_COPILOT
)
if errorlevel 3 (
  call :ACTIVER_WIDGETS
  goto :TOGGLE_COPILOT
)
if errorlevel 2 (
  call :DESACTIVER_COPILOT
  goto :TOGGLE_COPILOT
)
call :ACTIVER_COPILOT
goto :TOGGLE_COPILOT

:ACTIVER_COPILOT
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour Copilot...%COLOR_RESET%
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /f >nul 2>&1
set "HOSTS=%windir%\System32\drivers\etc\hosts"
powershell -NoProfile -c "(Get-Content '%HOSTS%') | Where-Object { $_ -notmatch 'copilot\.microsoft\.com|windows\.ai\.microsoft\.com|copilot-telemetry\.microsoft\.com|Copilot Block' } | Set-Content '%HOSTS%'" >nul 2>&1
call :FINISH_IA_ACTION "Copilot" "active"
exit /b

:DESACTIVER_COPILOT
if "%SKIP_PAUSE%"=="0" (
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Copilot s'appuie sur des services cloud ; ce script applique des strategies et peut%COLOR_RESET%
echo %COLOR_WHITE%  ajouter des lignes au fichier hosts pour bloquer des endpoints lies.%COLOR_RESET%
echo %COLOR_WHITE%- Vous perdez l'assistant integre tant que les cles / hosts restent en place.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Copilot ? [O/N]: %COLOR_RESET%"
if errorlevel 2 exit /b
)
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions Copilot...%COLOR_RESET%
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /t REG_DWORD /d 1 /f >nul 2>&1
set "HOSTS=%windir%\System32\drivers\etc\hosts"
findstr /i "Copilot Block" "%HOSTS%" >nul 2>&1
if errorlevel 1 (
    echo.>> "%HOSTS%"
    echo # --- Copilot Block --->> "%HOSTS%"
    echo 0.0.0.0 msedge.api.cdp.microsoft.com>> "%HOSTS%"
    echo 0.0.0.0 edge.microsoft.com>> "%HOSTS%"
    echo # --- End Copilot Block --->> "%HOSTS%"
)
call :FINISH_IA_ACTION "Copilot" "desactive"
exit /b

:ACTIVER_WIDGETS
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour les Widgets...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 1 /f >nul 2>&1
call :FINISH_IA_ACTION "Widgets" "active"
exit /b

:DESACTIVER_WIDGETS
if "%SKIP_PAUSE%"=="0" (
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER LES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Les widgets ^(meteo, actus^) utilisent le panneau lateral et du reseau en arriere-plan.%COLOR_RESET%
echo %COLOR_WHITE%- La desactivation masque ce flux : utile pour perf / distraction, moins pour veille info.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver les Widgets ? [O/N]: %COLOR_RESET%"
if errorlevel 2 exit /b
)
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour les Widgets...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
call :FINISH_IA_ACTION "Widgets" "desactive"
exit /b

:ACTIVER_RECALL
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
:: IA.1 - Recall : Restauration
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour Recall...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v "DisableClickToDo" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v "InsightsEnabled" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall reactive
call :FINISH_IA_ACTION "Recall" "active"
exit /b

:DESACTIVER_RECALL
if "%SKIP_PAUSE%"=="0" (
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER RECALL / ANALYSE IA%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Recall peut enregistrer l'activite ecran pour recherche semantique ^(fort impact confidentialite^).%COLOR_RESET%
echo %COLOR_WHITE%- Desactiver coupe ces fonctions et des politiques IA associees ^(snapshots, insights^).%COLOR_RESET%
echo %COLOR_WHITE%- Indique si vous privilegiez la vie privee plutot que les outils de recherche integree.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Recall et restrictions IA liees ? [O/N]: %COLOR_RESET%"
if errorlevel 2 exit /b
)
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
:: IA.2 - Recall : Desactivation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour Recall et l'IA...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Recall" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Recall" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall desactive
call :FINISH_IA_ACTION "Recall" "desactive"
exit /b

:DESACTIVER_TOUT_COPILOT
if "%SKIP_PAUSE%"=="0" (
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : TOUT DESACTIVER ^(COPILOT + WIDGETS + RECALL / IA^)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Cette action cumule Copilot, barre lateral widgets, et politiques Recall / Windows AI.%COLOR_RESET%
echo %COLOR_WHITE%- Effet combine : moins de taches et de trafic reseau lies a ces fonctionnalites.%COLOR_RESET%
echo %COLOR_WHITE%- Vous perdez l'assistant, le flux actus et les outils bases sur l'analyse locale/cloud.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de tout desactiver ^(Copilot + Widgets + Recall/IA^) ? [O/N]: %COLOR_RESET%"
if errorlevel 2 exit /b
)
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION TOTALE IA / WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
:: IA.3 - Desactivation totale (Copilot + Widgets + Recall)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de Copilot...%COLOR_RESET%
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v "IsCopilotAvailable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v "CopilotDisabledReason" /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v "IsUserEligible" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des Widgets...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de Recall et fonctions IA...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1

call :FINISH_ACTION "Toutes les fonctions IA/Widgets" "desactivees"
exit /b

:FINISH_IA_ACTION
call :FINISH_ACTION "%~1" "%~2"
exit /b

:FINISH_ACTION
setlocal DisableDelayedExpansion
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Action terminee : %~1 %~2.%COLOR_RESET%
echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les changements.%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "%SKIP_PAUSE%"=="1" (
  endlocal
  exit /b
)
choice /C ON /N /M "%COLOR_YELLOW%Redemarrer maintenant ? [O/N]:%COLOR_RESET%"
if errorlevel 2 (
  endlocal
  exit /b
)
if errorlevel 1 shutdown /r /t 5 /c "Redemarrage apres modification"
endlocal
exit /b

:DESINSTALLER_ONEDRIVE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE ONEDRIVE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi demander confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- OneDrive synchronise Documents/Bureau/Images vers le cloud Microsoft.%COLOR_RESET%
echo %COLOR_WHITE%- Le desinstaller coupe la sync et les liens ?? nuage ?? ; Office peut perdre l'auto-save cloud.%COLOR_RESET%
echo %COLOR_WHITE%- Les chemins du dossier OneDrive ^(%USERPROFILE%\OneDrive^) seront supprimes si presents.%COLOR_RESET%
echo %COLOR_WHITE%- Pratique pour liberer ressources et vie privee ; gardez une copie locale avant de valider.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% La suite arretera OneDrive, nettoiera registre et raccourcis, puis desinstallera.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre quelques instants.
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desinstaller OneDrive ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :MENU_GESTION_WINDOWS

:: Arreter les processus OneDrive
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im OneDriveSetup.exe >nul 2>&1
taskkill /f /im FileCoAuth.exe >nul 2>&1
taskkill /f /im FileSyncHelper.exe >nul 2>&1
taskkill /f /im OneDriveStandaloneUpdater.exe >nul 2>&1
timeout /t 3 /nobreak >nul
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
timeout /t 3 /nobreak >nul

echo %COLOR_YELLOW%[*]%COLOR_RESET% Deconnexion des comptes OneDrive...
powershell -Command "try { Import-Module -Name Microsoft.PowerShell.Management -Force; Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1

:: Commande pour desinstaller OneDrive
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall
) else (
    "%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des cles de registre OneDrive...
reg delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f >nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\SkyDrive" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Classes\OneDrive" /f >nul 2>&1
reg delete "HKCU\Environment" /v OneDrive /f >nul 2>&1
reg delete "HKCU\Environment" /v OneDriveConsumer /f >nul 2>&1
reg delete "HKCU\Environment" /v OneDriveCommercial /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees OneDrive...
for /f "tokens=1 delims=," %%x in ('schtasks /query /fo csv 2^>nul ^| find "OneDrive"') do (
    set "TASKNAME=%%~x"
    set "TASKNAME=!TASKNAME:"=!"
    schtasks /delete /TN "!TASKNAME!" /f >nul 2>&1
)

echo %COLOR_GREEN%[OK]%COLOR_RESET% Desinstallation de OneDrive terminee (si installe).
echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des dossiers OneDrive restants...
if exist "%LocalAppData%\Microsoft\OneDrive" rd "%LocalAppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%AppData%\Microsoft\OneDrive" rd "%AppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%SystemDrive%\OneDriveTemp" rd "%SystemDrive%\OneDriveTemp" /q /s >nul 2>&1
for %%C in (
    "%LocalAppData%\Microsoft\OneDrive\logs"
    "%LocalAppData%\Microsoft\OneDrive\settings"
    "%LocalAppData%\Temp\OneDrive*"
    "%Temp%\OneDrive*"
) do (
    if exist "%%~C" (
        rd "%%~C" /q /s >nul 2>&1
        del "%%~C" /q /s /f >nul 2>&1
    )
)
if exist "%USERPROFILE%\OneDrive" (
    takeown /f "%USERPROFILE%\OneDrive" /r /d y >nul 2>&1
    rd "%USERPROFILE%\OneDrive" /s /q >nul 2>&1
)
if exist "%LOCALAPPDATA%\Microsoft\OneDrive" (
    takeown /f "%LOCALAPPDATA%\Microsoft\OneDrive" /r /d y >nul 2>&1
    rd "%LOCALAPPDATA%\Microsoft\OneDrive" /s /q >nul 2>&1
)
if exist "%PROGRAMDATA%\Microsoft OneDrive" (
    takeown /f "%PROGRAMDATA%\Microsoft OneDrive" /r /d y >nul 2>&1
    rd "%PROGRAMDATA%\Microsoft OneDrive" /s /q >nul 2>&1
)
if exist "%SystemDrive%\OneDriveTemp" (
    takeown /f "%SystemDrive%\OneDriveTemp" /r /d y >nul 2>&1
    rd "%SystemDrive%\OneDriveTemp" /s /q >nul 2>&1
)

:: Supprimer les raccourcis OneDrive du menu Demarrer
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nettoyage complet de OneDrive termine.%COLOR_RESET%
call :FINISH_ACTION "OneDrive" "desinstalle" "call"
goto :MENU_GESTION_WINDOWS

:DESINSTALLER_EDGE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE MICROSOFT EDGE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_WHITE%Pourquoi demander confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Edge est le moteur WebView2 pour nombre d'applis Windows ^(Widgets, Store, aide^).%COLOR_RESET%
echo %COLOR_WHITE%- Le retirer peut casser des applis qui s'appuient sur le runtime integre.%COLOR_RESET%
echo %COLOR_WHITE%- Windows Update peut tenter de reinstaller un navigateur de base ; comportement variable selon version.%COLOR_RESET%
echo %COLOR_WHITE%- Utile pour allegement / preference ; risque de compatibilite reel sur certaines configs.%COLOR_RESET%
echo.
echo %COLOR_RED%[^!] ATTENTION:%COLOR_RESET% La desinstallation de Microsoft Edge peut entrainer des problemes
echo %COLOR_RED%de compatibilite avec certaines applications Windows.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desinstaller Microsoft Edge ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :MENU_GESTION_WINDOWS
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_WHITE% SUPPRESSION DES DONNEES UTILISATEUR%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_WHITE%Pourquoi une question separee :%COLOR_RESET%
echo %COLOR_WHITE%- Sans suppression, profils et caches restent sur le disque ^(reinstall ou autre navigateur^).%COLOR_RESET%
echo %COLOR_WHITE%- Avec suppression, favoris et mots de passe locaux peuvent etre perdus sans recuperation facile.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Voulez-vous supprimer les donnees utilisateur d'Edge ?
echo %COLOR_WHITE%- Historique de navigation%COLOR_RESET%
echo %COLOR_WHITE%- Cookies et donnees de sites%COLOR_RESET%
echo %COLOR_WHITE%- Favoris/Signets%COLOR_RESET%
echo %COLOR_WHITE%- Mots de passe sauvegardes%COLOR_RESET%
echo %COLOR_WHITE%- Extensions et themes%COLOR_RESET%
echo %COLOR_WHITE%- Parametres et preferences%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de supprimer les donnees utilisateur Edge ? [O/N]: %COLOR_RESET%"
if errorlevel 2 (
    set "SUPPR_DATA=NON"
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Les donnees utilisateur seront preservees.
) else (
    set "SUPPR_DATA=OUI"
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% Les donnees utilisateur seront supprimees.
)

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Debut de la desinstallation...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Arret des processus Edge...
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression de l'icone Edge de la barre des taches...
:: Suppression ciblee des raccourcis Edge uniquement
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1
if exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" (
    for %%f in ("%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk") do (
        findstr /i "edge" "%%f" >nul && del "%%f" /f /q >nul 2>&1
    )
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci Edge supprime (les autres icones sont preservees)

:: Desinstallation de Microsoft Edge
echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de desinstallation de Microsoft Edge...
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" (
    set "EDGE_OLDDIR=%CD%"
    cd /d "%ProgramFiles(x86)%\Microsoft\Edge\Application"
    for /d %%i in (*) do (
        if exist "%%i\Installer\setup.exe" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% Execution setup.exe...
            "%%i\Installer\setup.exe" --uninstall --system-level --verbose-logging --force-uninstall
        )
    )
    cd /d "!EDGE_OLDDIR!"
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage force des dossiers programme...
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des cles de registre Edge...
reg delete "HKLM\Software\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees Edge...
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f >nul 2>&1

:: Gestion conditionnelle des donnees utilisateur
if "%SUPPR_DATA%"=="OUI" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des donnees utilisateur Edge...
    if exist "%LOCALAPPDATA%\Microsoft\Edge" rd "%LOCALAPPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    if exist "%APPDATA%\Microsoft\Edge" rd "%APPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Donnees utilisateur supprimees.
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Conservation des donnees utilisateur...
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\BrowserSwitcher" /f >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\PreferenceMACs" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Donnees utilisateur preservees.
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des donnees systeme communes...
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des raccourcis...
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des associations de fichiers...
reg delete "HKLM\SOFTWARE\Classes\MSEdgeHTM" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\MSEdgePDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\msedge.exe" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage de l'index de recherche Windows...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_http" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_https" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du menu demarrer...
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache d'icones Edge...
del "%LOCALAPPDATA%\IconCache.db" /f /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des references Edge dans MUI Cache...
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "C:\Program Files\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Blocage des reinstallations automatiques...
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "InstallDefault" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventFirstRunPage" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification finale...
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
) else (
    if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Microsoft Edge desinstalle avec succes !
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Icone supprimee de la barre des taches !
        if "%SUPPR_DATA%"=="OUI" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% Donnees utilisateur supprimees.
        ) else (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% Donnees utilisateur conservees.
        )
    )
)

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo  %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Microsoft Edge a ete desinstalle completement.%COLOR_RESET%
if "%SUPPR_DATA%"=="NON" (
    echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Vos favoris, mots de passe et historique ont ete preserves.%COLOR_RESET%
)
echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%L'icone Edge a ete supprimee de la barre des taches.%COLOR_RESET%
call :FINISH_ACTION "Microsoft Edge" "desinstalle" "call"
goto :MENU_GESTION_WINDOWS


:OUTIL_ACTIVATION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL D'ACTIVATION WINDOWS / OFFICE (MAS)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Lancement de l'outil d'activation...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Veuillez suivre les instructions a l'ecran.
powershell "irm https://get.activated.win | iex"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Outil d'activation termine.
pause
goto :MENU_PRINCIPAL

:OUTIL_CHRIS_TITUS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL CHRIS TITUS TECH (WINUTIL)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Lancement de l'outil Chris Titus Tech...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Veuillez suivre les instructions a l'ecran.
powershell "irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Outil Chris Titus Tech termine.
pause
goto :MENU_PRINCIPAL

:CREER_POINT_RESTAURATION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_WHITE% Creation d'un point de restauration%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification et activation de la restauration systeme si necessaire...
:: DisableSR + protection volume C: via WMI root\default SystemRestore.GetDiskList (paires: code lettre ASCII, 1=actif)
powershell -NoProfile -Command "try { $p = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -ErrorAction SilentlyContinue; if ($null -ne $p -and $p.DisableSR -eq 1) { exit 1 }; $sr = Get-WmiObject -Class SystemRestore -Namespace root\default -ErrorAction SilentlyContinue; if ($null -eq $sr) { exit 1 }; $r = $sr.GetDiskList(); if ($null -eq $r) { exit 1 }; if ($null -ne $r.ReturnValue -and [int]$r.ReturnValue -ne 0) { exit 1 }; $a = @($r.DiskList); if ($a.Count -lt 2) { exit 1 }; for ($i = 0; $i -lt $a.Count; $i += 2) { $d = $a[$i]; $st = if ($i + 1 -lt $a.Count) { [int]$a[$i + 1] } else { 0 }; if ($st -ne 1) { continue }; if ($d -eq 67) { exit 0 }; if ($d -is [string] -and $d -match '^C') { exit 0 } }; exit 1 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la restauration systeme...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /t REG_DWORD /d 1 /f >nul 2>&1
    powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive 'C:' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
    timeout /t 2 /nobreak >nul
)
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Creation d'un point de restauration en cours...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette operation peut prendre 30-60 secondes...
echo.

:: Creation du point de restauration (appel synchrone : plus fiable que Start-Job pour Checkpoint-Computer)
:: Horodatage independant de la locale Windows (evite dim.-22-03_... avec %%DATE%% en francais)
:: Ne pas entourer le format de quotes simples : le FOR / ('...') de CMD s'arrete a la premiere '
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "RP_TIMESTAMP=%%a"
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { $desc = 'Optimizations_%RP_TIMESTAMP%'; Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS'; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Point de restauration cree avec succes.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Nom : Optimizations_%RP_TIMESTAMP%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Echec de la creation du point de restauration.
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Raison possible : restauration desactivee, espace disque insuffisant ou strategie groupe.
)
set "RP_TIMESTAMP="
pause
goto :MENU_PRINCIPAL

:NETTOYAGE_AVANCE_WINDOWS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                 NETTOYAGE DE WINDOWS AVANCE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Analyse espace initial
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set space_before_mb=%%a
if not defined space_before_mb set "space_before_mb=0"

echo %COLOR_YELLOW%[^!] AVERTISSEMENT%COLOR_RESET%
echo %COLOR_WHITE%  Ce script va supprimer : fichiers temporaires, logs, caches,%COLOR_RESET%
echo %COLOR_WHITE%  rapports d'erreurs, corbeille, et anciens pilotes dupliques.%COLOR_RESET%
echo.
choice /C ON /N /M "%COLOR_YELLOW%Continuer ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :MENU_PRINCIPAL

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                 NETTOYAGE DE WINDOWS AVANCE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Initialiser la barre de progression (15 etapes)
set /a "CLEAN_TOTAL=15"
set /a "CLEAN_STEP=0"

:: ETAPE 1
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires utilisateur"
del /s /q /f "%temp%\*.*" >nul 2>&1
for /d %%d in ("%temp%\*") do rd /s /q "%%d" >nul 2>&1

:: ETAPE 2
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires Windows"
del /s /q /f "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >nul 2>&1

:: ETAPE 3
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs systeme"
del /s /q /f "%SystemRoot%\Logs\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Panther\*.log" >nul 2>&1

:: ETAPE 4
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers de crash"
del /s /q /f "%SystemRoot%\Minidump\*.*" >nul 2>&1
del /q /f "%SystemRoot%\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\memory.dmp" >nul 2>&1

:: ETAPE 5
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Rapports d'erreurs"
rd /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if not exist "%ProgramData%\Microsoft\Windows\WER" md "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1

:: ETAPE 6
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Update"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
timeout /t 2 /nobreak >nul
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

:: ETAPE 7
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Corbeille"
powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

:: ETAPE 8
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux CBS/DISM"
del /s /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1

:: ETAPE 9
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache de polices"
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
net start FontCache >nul 2>&1

:: ETAPE 10
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Store"
powershell -NoProfile -Command "Get-ChildItem -Path \"$env:LOCALAPPDATA\Packages\" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Edge|WebView|Microsoft\.Windows' } | ForEach-Object { Remove-Item -Path \"$($_.FullName)\AC\INetCache\*\" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"$($_.FullName)\AC\Temp\*\" -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1

:: ETAPE 11
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache DNS"
ipconfig /flushdns >nul 2>&1

:: ETAPE 12
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux Event Viewer"
for /f "tokens=*" %%G in ('wevtutil el 2^>nul') do wevtutil cl "%%G" >nul 2>&1

:: ETAPE 13
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Dossier Windows.old"
if exist "%SystemDrive%\Windows.old" (
    takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
    icacls "%SystemDrive%\Windows.old" /grant administrators:F /t >nul 2>&1
    rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
)

:: ETAPE 14
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation disque (TRIM/Defrag)"
defrag %SystemDrive% /O /H >nul 2>&1

:: ETAPE 15
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Nettoyage Windows Cleanmgr"
set "SAGEID=100"
for %%K in ("Active Setup Temp Folders" "BranchCache" "Content Indexer Cleaner" "Delivery Optimization Files" "Device Driver Packages" "Diagnostic Data Viewer database files" "Downloaded Program Files" "GameNewsFiles" "GameStatisticsFiles" "GameUpdateFiles" "Language Pack" "Memory Dump Files" "Offline Pages Files" "Old ChkDsk Files" "Previous Installations" "Recycle Bin" "RetailDemo Offline Content" "Service Pack Cleanup" "Setup Log Files" "System error memory dump files" "System error minidump files" "Temporary Files" "Temporary Setup Files" "Temporary Sync Files" "Thumbnail Cache" "Update Cleanup" "Upgrade Discarded Files" "User file versions" "Windows Defender" "Windows Error Reporting Archive Files" "Windows Error Reporting Files" "Windows Error Reporting Queue Files" "Windows Error Reporting System Archive Files" "Windows Error Reporting System Queue Files" "Windows Error Reporting Temp Files" "Windows ESD installation files" "Windows Upgrade Log Files") do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t REG_DWORD /d 2 /f >nul 2>&1
)
cleanmgr /sagerun:%SAGEID% /d C: >nul 2>&1
powershell -NoProfile -Command "$waitCount=0; while((Get-Process cleanmgr -ErrorAction SilentlyContinue) -and ($waitCount -lt 120)){ Start-Sleep -s 1; $waitCount++ }" >nul 2>&1

:: Calcul final (PowerShell pour la precision des decimales)
for /f "tokens=1-3" %%a in ('powershell -NoProfile -Command "$before=[long]%space_before_mb% * 1024 * 1024; $after=(Get-PSDrive C).Free; $freed=$after-$before; if($freed -lt 0){$freed=0}; $beforeGB=[math]::Round($before/1GB, 2); $afterGB=[math]::Round($after/1GB, 2); $freedGB=[math]::Round($freed/1GB, 2); Write-Output \"$beforeGB $afterGB $freedGB\""') do (
    set "space_before_gb=%%a"
    set "space_after_gb=%%b"
    set "space_freed_gb=%%c"
)

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Nettoyage de Windows termine.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo   %COLOR_WHITE%Espace avant :%COLOR_RESET% %COLOR_YELLOW%%space_before_gb% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace apres :%COLOR_RESET% %COLOR_GREEN%%space_after_gb% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace gagne :%COLOR_RESET% %COLOR_CYAN%%space_freed_gb% Go%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% Un redemarrage est recommande pour finaliser.
echo.
choice /C ON /N /M "%COLOR_YELLOW%Redemarrer maintenant ? [O/N]: %COLOR_RESET%"
if %errorlevel% EQU 2 goto :MENU_PRINCIPAL
shutdown /r /t 10 /c "Redemarrage pour finaliser le nettoyage"
goto :MENU_PRINCIPAL


:INSTALLER_VISUAL_REDIST
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DES RUNTIMES Visual C++%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Detection des versions installees (V14 - 2015-2022)...

:: Initialisation
set VC2015X86=0
set VC2015X64=0

:: Detection DLL
if exist "%SystemRoot%\System32\vcruntime140.dll" set VC2015X64=1
if exist "%SystemRoot%\SysWOW64\vcruntime140.dll" set VC2015X86=1

:: Fallback registry pour les versions manquantes
set "REG_DUMP=%TEMP%\vc_uninstall_dump.txt"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s > "%REG_DUMP%" 2>nul
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%REG_DUMP%" 2>nul

if %VC2015X64%==0 type "%REG_DUMP%" | findstr /I /C:"Visual C++" | findstr /I /C:"2015" /C:"2017" /C:"2019" /C:"2022" | findstr /I /C:"x64" /C:"X64" >nul 2>&1 && set VC2015X64=1
if %VC2015X86%==0 type "%REG_DUMP%" | findstr /I /C:"Visual C++" | findstr /I /C:"2015" /C:"2017" /C:"2019" /C:"2022" | findstr /I /C:"x86" /C:"X86" >nul 2>&1 && set VC2015X86=1

:: Compter combien sont deja installes
set /a "VCINSTALLED_COUNT=%VC2015X86%+%VC2015X64%"

echo.
echo %COLOR_WHITE%Versions detectees (V14):%COLOR_RESET% %COLOR_GREEN%%VCINSTALLED_COUNT%/2%COLOR_RESET%

:: Si tout est deja installe, afficher message et retourner
if %VCINSTALLED_COUNT%==2 (
    echo.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les versions V14 sont deja installees.
    if exist "%REG_DUMP%" del /f /q "%REG_DUMP%" >nul 2>&1
    if "%SKIP_PAUSE%"=="0" (
        echo.
        pause
        goto :MENU_PRINCIPAL
    )
    exit /b
)

:: Suite : installation des paquets VC++ manquants (flux sequentiel, pas de goto vers ce point)
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Installation des versions manquantes...
set /a "VC_TO_INSTALL=2-VCINSTALLED_COUNT"
echo %COLOR_WHITE%Packages a installer:%COLOR_RESET% %COLOR_YELLOW%%VC_TO_INSTALL%%COLOR_RESET%
echo.

:: Initialiser la barre de progression (2 packages au total)
set /a "VC_TOTAL=2"
set /a "VC_STEP=0"
set /a "VCINSTALL=0"

:: Creer un dossier temporaire pour les installations
set "VCREDIST_DIR=%TEMP%\VCRedistInstall"
if not exist "%VCREDIST_DIR%" mkdir "%VCREDIST_DIR%"

:: VC++ 2015-2022 x86
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "VC++ 2015-2022 x86"
if %VC2015X86%==0 (
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x86.exe' -OutFile '%VCREDIST_DIR%\vc2015x86.exe' -UseBasicParsing -ErrorAction Stop } catch {}" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2015x86.exe" start /wait "" "%VCREDIST_DIR%\vc2015x86.exe" /q /norestart >nul 2>&1
)

:: VC++ 2015-2022 x64
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "VC++ 2015-2022 x64"
if %VC2015X64%==0 (
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x64.exe' -OutFile '%VCREDIST_DIR%\vc2015x64.exe' -UseBasicParsing -ErrorAction Stop } catch {}" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2015x64.exe" start /wait "" "%VCREDIST_DIR%\vc2015x64.exe" /q /norestart >nul 2>&1
)
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification des installations...

:: Re-detection des DLLs apres installation
set VC2015X86_NEW=0
set VC2015X64_NEW=0

:: Verification DLL
if exist "%SystemRoot%\System32\vcruntime140.dll" set VC2015X64_NEW=1
if exist "%SystemRoot%\SysWOW64\vcruntime140.dll" set VC2015X86_NEW=1

:: Calculer les vrais comptes
set /a "VCINSTALL=%VC2015X86_NEW%+%VC2015X64_NEW%"

echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Verification terminee - %COLOR_GREEN%%VCINSTALL%/2%COLOR_RESET% versions presentes
timeout /t 3 /nobreak >nul

:: Nettoyage des fichiers temporaires
if exist "%VCREDIST_DIR%" rd /s /q "%VCREDIST_DIR%" >nul 2>&1
if exist "%REG_DUMP%" del /f /q "%REG_DUMP%" >nul 2>&1

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DE DIRECTX RUNTIME (JUNE 2010)%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :INSTALLER_DIRECTX

if "%SKIP_PAUSE%"=="0" (
    echo.
    pause
    goto :MENU_PRINCIPAL
)
exit /b

:INSTALLER_DIRECTX
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification de l'installation de DirectX...

:: Detection de DirectX June 2010 (XAudio2_7.dll est un bon indicateur)
set "DX_INSTALLED=0"
if exist "%SystemRoot%\System32\XAudio2_7.dll" set "DX_INSTALLED=1"

if "%DX_INSTALLED%"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% DirectX June 2010 est deja installe sur ce systeme.
    exit /b
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Preparation de l'installation...
set "DX_TEMP=%TEMP%\DirectXInstall"
if exist "%DX_TEMP%" rd /s /q "%DX_TEMP%" >nul 2>&1
mkdir "%DX_TEMP%"

echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement de DirectX Redist June 2010 (95 Mo)...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -OutFile '%DX_TEMP%\directx_redist.exe' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Echec du telechargement. Verifiez votre connexion.
    rd /s /q "%DX_TEMP%" >nul 2>&1
    exit /b
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Extraction des fichiers...
:: Utiliser l'extracteur integre de DirectX si possible, ou fallback
"%DX_TEMP%\directx_redist.exe" /Q /T:"%DX_TEMP%" >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Installation silencieuse en cours...
if exist "%DX_TEMP%\DXSETUP.exe" (
    start /wait "" "%DX_TEMP%\DXSETUP.exe" /silent
    echo %COLOR_GREEN%[OK]%COLOR_RESET% DirectX June 2010 installe avec succes.
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Une erreur est survenue lors de l'extraction.
)

:: Nettoyage
echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des fichiers temporaires...
rd /s /q "%DX_TEMP%" >nul 2>&1

exit /b

:END_SCRIPT
:: Sans expansion retardee : evite que les "!" dans les textes ([^!], AU REVOIR!, etc.) cassent la fin du script
setlocal DisableDelayedExpansion
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% AU REVOIR! %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Merci d'avoir utilise le script d'optimisation! %COLOR_RESET%
echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%N'oubliez pas de redemarrer votre PC pour finaliser tout.%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
endlocal
endlocal
exit /b 0
