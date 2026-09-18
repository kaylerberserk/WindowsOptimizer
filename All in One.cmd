@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined WINOPT_SOURCE_DIR set "WINOPT_SOURCE_DIR=%~dp0"
if not defined WINOPT_RELEASE_BASE_URL set "WINOPT_RELEASE_BASE_URL=https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main"
set "WINOPT_SELF=%~f0"
set "WINOPT_SELF_BACKUP_SOURCE=%~f0"

:: PowerShell est requis par le script et pour verifier/normaliser le format des fichiers .cmd.
set "WINOPT_PS_MISSING=0"
where powershell >nul 2>&1
if errorlevel 1 set "WINOPT_PS_MISSING=1"
if "%WINOPT_PS_MISSING%"=="1" echo [ERREUR] PowerShell est introuvable. Le script ne peut pas continuer.
if "%WINOPT_PS_MISSING%"=="1" pause
if "%WINOPT_PS_MISSING%"=="1" exit /b 1

:: Contrat du batch : ASCII 7 bits, sans BOM et fins de ligne CRLF.
:: GitHub sert les fichiers bruts en LF : verifier le format avant le premier GOTO/CALL,
:: relancer une copie CRLF si necessaire, puis transmettre son code retour.
powershell -NoProfile -Command "try{$b=[IO.File]::ReadAllBytes($env:WINOPT_SELF);for($i=0;$i-lt$b.Length;$i++){if($b[$i]-eq0-or$b[$i]-gt127){exit 44};if(($b[$i]-eq10-and($i-eq0-or$b[$i-1]-ne13))-or($b[$i]-eq13-and($i+1-ge$b.Length-or$b[$i+1]-ne10))){exit 42}};exit 0}catch{exit 43}" >nul 2>&1
set "WINOPT_FORMAT_RC=%errorlevel%"
if "%WINOPT_FORMAT_RC%"=="43" echo [ERREUR] Impossible de lire ou verifier le format du script.
if "%WINOPT_FORMAT_RC%"=="43" pause
if "%WINOPT_FORMAT_RC%"=="43" exit /b 1
if "%WINOPT_FORMAT_RC%"=="44" echo [ERREUR] Le script doit etre en ASCII sans BOM.
if "%WINOPT_FORMAT_RC%"=="44" pause
if "%WINOPT_FORMAT_RC%"=="44" exit /b 1
if not "%WINOPT_FORMAT_RC%"=="0" if not "%WINOPT_FORMAT_RC%"=="42" echo [ERREUR] Verification du format terminee avec le code %WINOPT_FORMAT_RC%.
if not "%WINOPT_FORMAT_RC%"=="0" if not "%WINOPT_FORMAT_RC%"=="42" pause
if not "%WINOPT_FORMAT_RC%"=="0" if not "%WINOPT_FORMAT_RC%"=="42" exit /b 1
if "%WINOPT_FORMAT_RC%"=="42" powershell -NoProfile -Command "$tmp=Join-Path $env:TEMP ('WindowsOptimizer_crlf_'+[guid]::NewGuid().ToString('N')+'.cmd');try{$b=[IO.File]::ReadAllBytes($env:WINOPT_SELF);$c=[Text.Encoding]::ASCII.GetString($b);$crlf=[string][char]13+[char]10;$c=[regex]::Replace($c,'\r\n|\r|\n',$crlf);[IO.File]::WriteAllText($tmp,$c,[Text.Encoding]::ASCII);$q=[char]34;$a='/d /e:on /v:off /s /c '+$q+$q+$tmp+$q+$q;$p=Start-Process -FilePath $env:ComSpec -ArgumentList $a -Wait -PassThru -NoNewWindow;exit $p.ExitCode}catch{Write-Host '[ERREUR] Impossible de preparer la copie CRLF du script.' -ForegroundColor Red;exit 1}finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}"
if not "%WINOPT_FORMAT_RC%"=="42" goto :WINOPT_FORMAT_READY
set "WINOPT_RELAUNCH_RC=%errorlevel%"
exit /b %WINOPT_RELAUNCH_RC%

:WINOPT_FORMAT_READY

set "WINOPT_SELF="
set "WINOPT_PS_MISSING="
set "WINOPT_FORMAT_RC="
set "WINOPT_RELAUNCH_RC="
setlocal EnableDelayedExpansion
cls
:: IMPORTANT : textes SANS ACCENTS (ASCII) pour affichage fiable en console cmd.exe
:: Ne pas utiliser chcp 65001 (UTF-8 casse l'affichage des .cmd sous Windows)
:: Assurer un repertoire de travail local valide (evite l'erreur "lecteur introuvable" lors d'une elevation de privileges)
cd /d "%SystemDrive%"

:: Activer les sequences d'echappement ANSI pour les couleurs
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Definir le titre de la console
title Script d'Optimisation Windows - All in One

:: Definition du caractere ESC (ASCII 27)
for /f "delims=" %%a in ('powershell -NoProfile -Command "$([char]27)"') do set "ESC=%%a"

:: Si PowerShell echoue, CMD fournit le caractere ESC en solution de secours
if not defined ESC (
    REM Methode alternative via CMD escape sequence
    for /f %%a in ('"prompt $E ^& echo on & for %%b in (1) do rem"') do set "ESC=%%a"
)

:: Fallback ultime : utiliser une variable vide si tout echoue (les couleurs ne s'afficheront pas mais le script fonctionnera)
if not defined ESC set "ESC="

:: Couleurs et Styles
if not "%ESC%"=="" (
    REM ANSI supporte : ESC defini -> couleurs fonctionnelles
    set "COLOR_GREEN=%ESC%[32m" & set "COLOR_YELLOW=%ESC%[33m" & set "COLOR_RED=%ESC%[31m"
    set "COLOR_CYAN=%ESC%[36m"  & set "COLOR_WHITE=%ESC%[37m"  & set "COLOR_BLUE=%ESC%[34m"
    set "COLOR_MAGENTA=%ESC%[35m" & set "COLOR_RESET=%ESC%[0m" & set "STYLE_BOLD=%ESC%[1m"
) else (
    REM Terminal sans ANSI : couleurs vides -> aucun litteral [0m] ou [36m visible
    set "COLOR_GREEN=" & set "COLOR_YELLOW=" & set "COLOR_RED="
    set "COLOR_CYAN="  & set "COLOR_WHITE="  & set "COLOR_BLUE="
    set "COLOR_MAGENTA=" & set "COLOR_RESET=" & set "STYLE_BOLD="
)

:: =================================================================================
:: INITIALISATION DES VARIABLES GLOBALES
:: =================================================================================
set "HAS_INTERNET=0"
:: PROFIL_USAGE : 0 = Gaming (latence reduite, reglages input/GPU plus reactifs)
::               1 = Normal (bureautique, multimedia, ajustements equilibres)
:: PROFIL_POWER : 0 = MaxPerf   (plan Ultimate Performance, economies d'energie coupees)
::               1 = Eco       (plan Equilibre, autonomie/stabilite preservees)
:: REGLE DE PROPRIETE : input/GPU -> USAGE ; energie/NIC/plan-alim -> POWER.
:: Exceptions : Nagle/DelACK et RSC/LSO sont agressifs seulement en Gaming+MaxPerf.
:: Flag composite (derive par :INIT_PROFILS) : IS_GAMING_ECO (Gaming + Eco = laptop gamer sur batterie).
:: DETECTE_PORTABLE garde le type materiel reel detecte au demarrage.
set "PROFIL_USAGE=0"
set "PROFIL_POWER=0"
set "IS_GAMING_ECO=0"
set "DETECTE_PORTABLE=0"
set "HAS_NVIDIA=0"
set "APPLIQUER_SECURITE=0"
set "DESACTIVER_DEFENDER=0"
set "DESACTIVER_ANIMATIONS=0"
set "DESACTIVER_IA=0"
set "DESACTIVER_UAC=0"
set "SKIP_PAUSE=0"
set "AIO_MODE=0"
:: SKIP_PAUSE=0 : menus normaux (confirmations + pause entre sections)
:: SKIP_PAUSE=1 : mode Tout optimiser - enchaine sans re-demander (reponses deja prises)

:: Variables Hardware
set "HW_OS=Detection..."
set "HW_CPU=Detection..."
set "HW_GPU=Detection..."
set "HW_RAM=Detection..."

:: GUID powercfg - utilises en hardcode pour simplifier le code
:: 54533251-82be-4824-96c1-47b60b740d00 = SUB_PROCESSOR
:: 381b4222-f694-41f0-9685-ff5bb260df2e = Plan d'alimentation Equilibre Windows
:: (SUB_ENERGYSAVER de830923-a562-41af-a086-e3a2c6bad2da n'existe plus dans Windows 10/11 moderne)
:: 0cc5b647-c1df-4637-891a-dec35c318584 = Core Parking (P-cores class 1)
:: 0cc5b647-c1df-4637-891a-dec35c318583 = Core Parking (E-cores class 0)
:: 93b8b6dc-0698-4d1c-9ee4-0644e900c85d = Heterogeneous thread scheduling

:: =================================================================================
:: CONVENTION DES INDICATEURS ET COULEURS
:: =================================================================================
:: [EN COURS]       JAUNE = Action en cours d'execution
:: [OK]             VERT  = Resultat verifie
:: [FAIT]           VERT  = Commande ou etape traitee sans verification complete
:: [TERMINE]        VERT  = Fin d'une section ou d'un parcours
:: [INFO]           JAUNE = Explication ou conseil
:: [IGNORE]         CYAN  = Action non executee ou non applicable
:: [AVERTISSEMENT] ROUGE = Risque, consequence ou limitation importante
:: [ERREUR]        ROUGE = Action echouee ou interrompue
:: =================================================================================

:: STRUCTURE DU FICHIER (recherche par label, jamais par numero de ligne)
:: - Interface commune : PROGRESS_BAR a AIO_QUESTION_HEADER
:: - Menus : MENU_PRINCIPAL, MENU_GESTION_WINDOWS, TOUT_OPTIMISER
:: - Optimisations : OPTIMISATIONS_SYSTEME a RESTAURER_ECONOMIES_ENERGIE
:: - Securite : APPLIQUER_PROFIL_SECURITE, TOGGLE_PROTECTIONS_NOYAU
:: - Gestion Windows : TOGGLE_DEFENDER a DESINSTALLER_EDGE
:: - Outils et nettoyage : OUTIL_ACTIVATION a SUPPRIMER_BLOATWARES
:: - Helpers techniques partages : apres END_SCRIPT

:: CHARGEMENT DU SCRIPT
call :SCREEN_HEADER "                     INITIALISATION DU SCRIPT D'OPTIMISATION                     "

set /a "LOAD_TOTAL=5"
set /a "LOAD_STEP=0"

:: Etape 1 : Privileges
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification des privileges administrateur"
:: Verification des privileges via le jeton UAC (independante du service Serveur utilise par net session)
powershell -NoProfile -Command "if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Le script n'est pas execute avec une elevation suffisante.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Verifiez que l'UAC est active et reexecutez en tant qu'administrateur.%COLOR_RESET%
    pause
    exit /b 1
)

:: Sauvegarde non ecrasante du batch avant toute modification du systeme.
set "WINOPT_BACKUP_DIR=%ProgramData%\WindowsOptimizer\Backups"
set "WINOPT_SECURITY_BACKUP=%WINOPT_BACKUP_DIR%\security-baseline.reg"
set "WINOPT_SECURITY_BCD_BACKUP=%WINOPT_BACKUP_DIR%\security-hypervisorlaunchtype.txt"
set "WINOPT_FTH_BACKUP=%WINOPT_BACKUP_DIR%\fth-state.json"
call :BACKUP_SELF_BEFORE_EXECUTION
if !errorlevel! NEQ 0 (
    echo [ERREUR] Impossible de sauvegarder All in One.cmd avant execution.
    pause
    exit /b 1
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
set "LOAD_STEP="
set "LOAD_TOTAL="

:: Ecran d'information (1 fois par session)
call :SCREEN_HEADER "                         WINDOWS OPTIMIZER"
echo %STYLE_BOLD%%COLOR_BLUE% FONCTIONNEMENT%COLOR_RESET%
echo.
echo %COLOR_YELLOW%  [1]%COLOR_RESET% %COLOR_WHITE%Choisissez votre usage : %COLOR_GREEN%GAMING%COLOR_RESET% pour les jeux ou %COLOR_CYAN%NORMAL%COLOR_RESET% pour le quotidien%COLOR_RESET%
echo %COLOR_YELLOW%  [2]%COLOR_RESET% %COLOR_WHITE%Choisissez le mode d'energie : %COLOR_GREEN%Performance max%COLOR_RESET% ou %COLOR_CYAN%ECO%COLOR_RESET%
echo %COLOR_YELLOW%  [3]%COLOR_RESET% %COLOR_WHITE%Lancez une section ou choisissez %STYLE_BOLD%%COLOR_GREEN%[O] TOUT OPTIMISER%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Les choix recommandes sont indiques pendant le parcours automatique.%COLOR_RESET%
echo %COLOR_WHITE%  Chaque option sensible reste expliquee et soumise a votre confirmation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_BLUE% COMMANDES DU CLAVIER%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_RED%  [IMPORTANT] UTILISATION DES CHIFFRES%COLOR_RESET%
echo %COLOR_WHITE%  Pour utiliser les chiffres situes en haut du clavier :%COLOR_RESET%
echo %COLOR_GREEN%    AVEC MAJ  %COLOR_RESET% %COLOR_WHITE%Maintenez MAJ, puis appuyez sur%COLOR_RESET% %STYLE_BOLD%%COLOR_GREEN%1 2 3 4 5 6 7 8 9 0%COLOR_RESET%
echo %COLOR_RED%    SANS MAJ  %COLOR_RESET% %COLOR_WHITE%Le symbole de la touche est saisi et%COLOR_RESET% %COLOR_RED%le menu emet un bip.%COLOR_RESET%
echo %COLOR_CYAN%    PAVE NUM. %COLOR_RESET% %COLOR_WHITE%Les chiffres fonctionnent directement, sans MAJ.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%  [R] CONSEILLE%COLOR_RESET% %COLOR_WHITE%Creer un point de restauration avant les changements.%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_YELLOW%                 Appuyez sur une touche pour ouvrir le menu%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
pause >nul

goto :MENU_PRINCIPAL

:PROGRESS_BAR
setlocal EnableDelayedExpansion
set "PCURRENT=%~1"
set "PTOTAL=%~2"
set "PDESC=%~3"

set /a "PCALC=0"
set /a "PFILL=0"
if not "%PTOTAL%"=="" if not "%PTOTAL%"=="0" (
    set /a "PCALC=%PCURRENT%*100/%PTOTAL%" 2>nul
)
set /a "PFILL=PCALC*20/100" 2>nul

if !PFILL! GTR 20 set PFILL=20
if !PFILL! LSS 0 set PFILL=0

set "PBAR="
for /l %%i in (1,1,20) do (
    if %%i LEQ !PFILL! set "PBAR=!PBAR!#"
    if %%i GTR !PFILL! set "PBAR=!PBAR!."
)

<nul set /p ="!ESC![2K!ESC![1G!COLOR_CYAN![!PBAR!] !COLOR_YELLOW!!PCALC!%% !COLOR_CYAN!!PCURRENT!/!PTOTAL! !COLOR_WHITE!!PDESC!!COLOR_RESET!"
endlocal
exit /b



:DETECT_HARDWARE
:: Parametre optionnel : 1 = conserver les profils deja choisis par l'utilisateur
set "HW_OS=Windows" & set "HW_CPU=Inconnu" & set "HW_GPU=Inconnu" & set "HW_RAM=?" & set "HAS_NVIDIA=0"
if not "%~1"=="1" (
    set "PROFIL_USAGE=0"
    set "PROFIL_POWER=0"
    set "DETECTE_PORTABLE=0"
)
:: Detection materiel en une seule commande pour eviter les scripts temporaires fragiles en CMD.
set "WINOPT_HW_FILE=%TEMP%\hw_info_%RANDOM%_%RANDOM%.tmp"
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor; $v=Get-CimInstance Win32_VideoController; $m=Get-CimInstance Win32_PhysicalMemory; if(-not $m){$m=Get-CimInstance Win32_ComputerSystem}; $b=0; $lc=8,9,10,11,14,30,31,32; $enc=Get-CimInstance Win32_SystemEnclosure -EA SilentlyContinue; if($enc -and $enc.ChassisTypes){foreach($t in $enc.ChassisTypes){if($lc -contains $t){$b=1;break}}}; if(-not $b -and (Get-CimInstance Win32_Battery -EA SilentlyContinue)){$b=1}; $res=@(); $cap=$o.Caption; if(-not $cap){$pn=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName; if($pn){$cap=$pn}else{$cap='Windows'}}; $res+='OS:'+$cap+' ('+$o.Version+')'; if($c){$res+='CPU:'+$c.Name.Trim()}; if($v){$gn=@($v|Where-Object{$_.Name -and $_.Name -notmatch 'Parsec|Virtual Display|Microsoft Basic|Remote|Indirect|Mirror'}|ForEach-Object{$_.Name.Trim()}|Select-Object -Unique); if(-not $gn.Count){$gn=@($v|ForEach-Object{$_.Name.Trim()})}; $res+='GPU:'+($gn -join ' / ')}; if($m.Capacity){$t=($m|Measure-Object Capacity -Sum).Sum; $res+='RAM:'+[math]::Round($t/1GB,0)}elseif($m.TotalPhysicalMemory){$res+='RAM:'+[math]::Round($m.TotalPhysicalMemory/1GB,0)}; $res+='LAPTOP:'+$b; [System.IO.File]::WriteAllLines($env:WINOPT_HW_FILE, $res)" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Detection du materiel impossible.%COLOR_RESET%
    echo %COLOR_WHITE%Les valeurs par defaut seront utilisees.%COLOR_RESET%
)
if exist "%WINOPT_HW_FILE%" (
    for /f "usebackq tokens=1* delims=:" %%a in ("%WINOPT_HW_FILE%") do (
        if /i "%%a"=="OS" set "HW_OS=%%b"
        if /i "%%a"=="CPU" set "HW_CPU=%%b"
        if /i "%%a"=="GPU" set "HW_GPU=%%b"
        if /i "%%a"=="RAM" set "HW_RAM=%%b"
        if /i "%%a"=="LAPTOP" (
            if not "%~1"=="1" (
                if "%%b"=="1" set "PROFIL_POWER=1"
            )
            set "DETECTE_PORTABLE=%%b"
        )
    )
    del "%WINOPT_HW_FILE%" >nul 2>&1
)
set "WINOPT_HW_FILE="
:: Detection intelligente NVIDIA : verifie que le GPU est physique (pas un GPU virtuel de VM)
set "HAS_NVIDIA=0"
echo !HW_GPU! | findstr /i "NVIDIA" >nul && (
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { $v=Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' -and $_.Name -notmatch 'Virtual|Parsec|Remote|Indirect|Mirror|Microsoft Basic' }; if(-not $v){ '0'; exit }; $m=Get-CimInstance Win32_ComputerSystem; if($m.Model -match 'Virtual|VMware|VirtualBox|KVM|QEMU|Xen|Parallels'){ '0'; exit }; '1' } catch { '0' }" 2^>nul`) do set "HAS_NVIDIA=%%V"
    if not defined HAS_NVIDIA set "HAS_NVIDIA=0"
    if not "!HAS_NVIDIA!"=="1" set "HAS_NVIDIA=0"
)
if /i "%HW_OS%"=="Windows" for /f "tokens=2 delims=[]" %%i in ('ver') do set "HW_OS=%%i"
exit /b

:: =================================================================================
:: INIT_PROFILS - Point de verite unique pour les profils
:: =================================================================================
:: Centralise la normalisation des 2 axes de profil et derive les flags composites
:: consommes par les sections d'optimisation. A appeler en tete de chaque section.
::
:: AXES (definis par l'utilisateur dans :TOUT_OPTIMISER, ou deduits ici) :
::   PROFIL_USAGE : 0 = Gaming (latence reduite) | 1 = Normal (bureautique/creation)
::   PROFIL_POWER : 0 = MaxPerf (perf max)        | 1 = Eco (autonomie/stabilite)
::
:: REGLE DE PROPRIETE :
::   - Input, I/O et latence GPU                  -> PROFIL_USAGE
::   - Energie, tuning NIC et plan d'alimentation -> PROFIL_POWER
::   - Nagle/DelACK et RSC/LSO agressifs seulement en Gaming+MaxPerf
:: =================================================================================
:INIT_PROFILS
if not defined PROFIL_USAGE set "PROFIL_USAGE=0"
if not defined PROFIL_POWER (
    REM En l'absence de choix utilisateur : laptop=Eco, desktop=MaxPerf
    if "%DETECTE_PORTABLE%"=="1" (
        set "PROFIL_POWER=1"
    ) else (
        set "PROFIL_POWER=0"
    )
)
REM Cas particulier : Gaming + Eco (laptop gamer sur batterie) - autorise mais signale
set "IS_GAMING_ECO=0"
if "!PROFIL_USAGE!"=="0" (
    if "!PROFIL_POWER!"=="1" set "IS_GAMING_ECO=1"
)
exit /b 0

:RESET_BCD_TIMER_OVERRIDES
REM Les overrides de diagnostic des timers sont supprimes pour tous les profils.
for %%B in (useplatformclock useplatformtick tscsyncpolicy) do bcdedit /deletevalue %%B >nul 2>&1
exit /b 0

:CHOISIR_PROFILS
call :INIT_PROFILS
set "PROFILE_PROMPT=%~2"
if not defined PROFILE_PROMPT set "PROFILE_PROMPT=BOTH"
if /i "!PROFILE_PROMPT!"=="POWER" goto :CHOISIR_PROFILS_POWER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% %~1%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Quel usage voulez-vous privilegier ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[1] GAMING%COLOR_RESET% : Tous types de jeux, reactivite et latence reduite
echo %COLOR_CYAN%[2] NORMAL%COLOR_RESET% : Bureautique, multimedia, creation et stabilite
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au menu principal%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le script adaptera automatiquement ses reglages a cet usage.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez votre usage [1=Gaming / 2=Normal / M=Retour] : %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! LSS 1 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! GTR 3 (
    REM choice.exe en echec (255) : aucune optimisation sans choix explicite.
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 3 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 1 set "PROFIL_USAGE=0"
if !errorlevel! EQU 2 set "PROFIL_USAGE=1"
if /i "!PROFILE_PROMPT!"=="USAGE" goto :CHOISIR_PROFILS_DONE

:CHOISIR_PROFILS_POWER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% %~1%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "%DETECTE_PORTABLE%"=="1" (
    echo %COLOR_WHITE%PC portable detecte. Quel mode energie voulez-vous ?%COLOR_RESET%
) else (
    echo %COLOR_WHITE%Quel mode energie voulez-vous ?%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[1] ECO%COLOR_RESET% : Autonomie, temperature et economies d'energie Windows actives
echo %COLOR_RED%[2] Performance max%COLOR_RESET% : Plus de performances, chauffe et consommation accrues
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au menu principal%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Ce choix ne change pas l'usage Gaming ou Normal selectionne.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez l'energie [1=Eco / 2=Performance max / M=Retour] : %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! LSS 1 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! GTR 3 (
    REM choice.exe en echec (255) : aucune optimisation sans choix explicite.
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 3 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 1 set "PROFIL_POWER=1"
if !errorlevel! EQU 2 set "PROFIL_POWER=0"
goto :CHOISIR_PROFILS_DONE

:CHOISIR_PROFILS_DONE
call :INIT_PROFILS
if /i not "!PROFILE_PROMPT!"=="POWER" if "!IS_GAMING_ECO!"=="1" (
    echo.
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Combinaison GAMING + ECO selectionnee.%COLOR_RESET%
    echo %COLOR_WHITE%    Les optimisations de latence restent actives et reduiront l'autonomie.%COLOR_RESET%
    echo %COLOR_WHITE%    Si l'autonomie est prioritaire, preferez NORMAL + ECO.%COLOR_RESET%
    echo.
    <nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Continuer quand meme ? [O/N] : %COLOR_RESET%"
    call :AZCHOICE ON
    if !errorlevel! NEQ 1 (
        set "PROFILE_PROMPT="
        exit /b 1
    )
)
set "PROFILE_PROMPT="
exit /b 0

:: =================================================================================
:: UTILS
:: =================================================================================


:REFRESH_INTERNET_STATUS
set "HAS_INTERNET=0"
ping -n 1 -w 1500 1.1.1.1 >nul 2>&1
if !errorlevel! EQU 0 (
    set "HAS_INTERNET=1"
    exit /b
)
:: Repli si ICMP est bloque (entreprise, pare-feu) : test HTTP leger (service Microsoft)
powershell -NoProfile -Command "try { $c=(Invoke-WebRequest -Uri 'http://www.msftconnecttest.com/connecttest.txt' -UseBasicParsing -TimeoutSec 5).Content; if ($c -match 'Microsoft') { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if !errorlevel! EQU 0 set "HAS_INTERNET=1"
exit /b

:PROMPT_MANUAL_REBOOT
if "!AIO_MODE!"=="1" exit /b 0
if "!SKIP_PAUSE!"=="1" exit /b 0
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous redemarrer maintenant ? [O/N] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 exit /b 0
if !errorlevel! EQU 1 (
    shutdown /r /t 10 /c "Redemarrage demande par WindowsOptimizer"
    if !errorlevel! EQU 0 (
        cls
        echo.
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Redemarrage programme dans 10 secondes...%COLOR_RESET%
        timeout /t 5 /nobreak >nul
        exit /b 0
    )
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de programmer le redemarrage.%COLOR_RESET%
    exit /b 1
)

:FINISH_ACTION
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Fin de la section : %~1.%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
if not "!AIO_MODE!"=="1" if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les changements.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
exit /b

:: Confirmation O/N - %~1 = message, retourne 0 pour Oui, 1 pour Non
:ASK_CONFIRM
<nul set /p ="%~1"
call :AZCHOICE ON
if !errorlevel! NEQ 1 exit /b 1
exit /b 0

:: %~1 = message
:ASK_IF_INTERACTIVE
if not "!SKIP_PAUSE!"=="0" exit /b 0
call :ASK_CONFIRM "%~1"
:: Retourne 0 pour Oui, 1 pour Non. Les appelants gerent le routage.
if !errorlevel! EQU 1 exit /b 1
exit /b 0

:: Question standard O/N/M.
:: %~1 = message  %~2 = variable flag (ex: APPLIQUER_SECURITE)
:: O : flag=1, retour 0 / N : flag=0, retour 0 / M : flag=0, retour 2
:COMMON_YES_NO
set "%~2=0"
<nul set /p ="%~1"
call :AZCHOICE ONM
set "COMMON_CHOICE=!errorlevel!"
REM O=1, N=2, M=3. La valeur est enregistree une fois pour garantir un routage unique.
if "!COMMON_CHOICE!"=="3" (
    set "COMMON_CHOICE="
    cls
    exit /b 2
)
if "!COMMON_CHOICE!"=="2" (
    set "COMMON_CHOICE="
    exit /b 0
)
if "!COMMON_CHOICE!"=="1" (
    set "%~2=1"
    set "COMMON_CHOICE="
    exit /b 0
)
set "COMMON_CHOICE="
REM En cas d'echec de choice.exe, revenir au menu au lieu d'appliquer une option.
exit /b 2

:: En-tete standard des ecrans principaux.
:: %~1 = titre affiche entre les deux separateurs
:SCREEN_HEADER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%%~1%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
exit /b 0

:: En-tete commun des cinq questions de Tout optimiser.
:: %~1 = numero de question  %~2 = titre court
:AIO_QUESTION_HEADER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% TOUT OPTIMISER - QUESTION %~1 / 5%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_CYAN% %~2%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
exit /b 0

:: Pied standard d'un sous-menu : %~1 = menu de retour, %~2 = invite, %~3 = choix autorises.
:SUBMENU_CHOICE
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au menu %~1%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%%~2%COLOR_RESET%"
call :AZCHOICE %~3
exit /b !errorlevel!

:: Lecture d'une entree menu via choice.exe (silencieux : pas d'ecran de la liste).
:AZCHOICE
choice /c %~1 /n
exit /b !errorlevel!

:MENU_PRINCIPAL
REM Toute entree dans un menu visible est interactive, meme apres un ancien parcours automatique.
set "AIO_MODE=0"
set "SKIP_PAUSE=0"
call :SCREEN_HEADER "Script d'Optimisation Windows : All in One"

REM  Affichage des informations systeme
echo %STYLE_BOLD%%COLOR_WHITE% SYSTEME :%COLOR_RESET% %COLOR_CYAN%%HW_OS%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CPU     :%COLOR_RESET% %COLOR_CYAN%%HW_CPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GPU     :%COLOR_RESET% %COLOR_CYAN%%HW_GPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% RAM     :%COLOR_RESET% %COLOR_CYAN%%HW_RAM% Go%COLOR_RESET%
if "%DETECTE_PORTABLE%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE% TYPE    :%COLOR_RESET% %COLOR_CYAN%PC PORTABLE%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% TYPE    :%COLOR_RESET% %COLOR_CYAN%PC FIXE%COLOR_RESET%
)
if "%HAS_INTERNET%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE% INTERNET:%COLOR_RESET% %COLOR_GREEN%Connecte%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% INTERNET:%COLOR_RESET% %COLOR_YELLOW%Hors ligne ou connexion filtree%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS GENERALES ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Optimisations Systeme%COLOR_RESET%   %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Optimisations Memoire%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Optimisations Disques%COLOR_RESET%   %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Optimisations GPU%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Optimisations Reseau%COLOR_RESET%    %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_GREEN%Optimisations Clavier/Souris%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- REGLAGES AVANCES ---%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_RED%Gerer les economies d'energie%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Gerer les protections Windows%COLOR_RESET%
echo.

echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_YELLOW%[O]%COLOR_RESET% %COLOR_WHITE%Tout optimiser %COLOR_GREEN%: Repondez aux questions, le script gere le reste%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS ---%COLOR_RESET%
echo %COLOR_YELLOW%[N]%COLOR_RESET% %COLOR_CYAN%Nettoyage Avance de Windows%COLOR_RESET%
echo %COLOR_YELLOW%[R]%COLOR_RESET% %COLOR_CYAN%Creer un Point de Restauration%COLOR_RESET%
echo %COLOR_YELLOW%[G]%COLOR_RESET% %COLOR_MAGENTA%Gestion de Windows : Defender, UAC, Edge et OneDrive%COLOR_RESET%
echo %COLOR_YELLOW%[W]%COLOR_RESET% %COLOR_MAGENTA%Activation Windows et Office avec le script MAS%COLOR_RESET%
echo %COLOR_YELLOW%[T]%COLOR_RESET% %COLOR_MAGENTA%WinUtil, utilitaire Windows de Chris Titus Tech%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[Q]%COLOR_RESET% %STYLE_BOLD%%COLOR_RED%Quitter le script%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-8, O, N, R, G, W, T, Q] : %COLOR_RESET%"
call :AZCHOICE 12345678ONRGWTQ

REM  Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 15 goto :END_SCRIPT
if !errorlevel! EQU 14 goto :OUTIL_CHRIS_TITUS
if !errorlevel! EQU 13 goto :OUTIL_ACTIVATION
if !errorlevel! EQU 12 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 11 goto :CREER_POINT_RESTAURATION
if !errorlevel! EQU 10 goto :NETTOYAGE_AVANCE_WINDOWS
if !errorlevel! EQU 9  goto :TOUT_OPTIMISER
if !errorlevel! EQU 8  goto :TOGGLE_PROTECTIONS_NOYAU
if !errorlevel! EQU 7  goto :TOGGLE_ECONOMIES_ENERGIE
if !errorlevel! EQU 6  goto :DO_PERIPHERIQUES
if !errorlevel! EQU 5  goto :DO_RESEAU
if !errorlevel! EQU 4  goto :DO_GPU
if !errorlevel! EQU 3  goto :DO_DISQUES
if !errorlevel! EQU 2  goto :DO_MEMOIRE
if !errorlevel! EQU 1  goto :DO_SYSTEME
goto :MENU_PRINCIPAL

:DO_PERIPHERIQUES
call :CHOISIR_PROFILS "CONFIGURATION PROFILS : PERIPHERIQUES" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_PERIPHERIQUES
goto :MENU_PRINCIPAL

:DO_RESEAU
call :CHOISIR_PROFILS "CONFIGURATION PROFILS : RESEAU" "BOTH"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_RESEAU
goto :MENU_PRINCIPAL

:DO_GPU
call :CHOISIR_PROFILS "CONFIGURATION PROFILS : GPU" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_GPU
goto :MENU_PRINCIPAL

:DO_DISQUES
call :CHOISIR_PROFILS "CONFIGURATION PROFILS : DISQUES" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_DISQUES
goto :MENU_PRINCIPAL

:DO_MEMOIRE
call :CHOISIR_PROFILS "CONFIGURATION PROFILS : MEMOIRE" "BOTH"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_MEMOIRE
goto :MENU_PRINCIPAL

:DO_SYSTEME
call :CHOISIR_PROFILS "CONFIGURATION PROFILS : SYSTEME" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_SYSTEME
goto :MENU_PRINCIPAL

:MENU_GESTION_WINDOWS
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GESTION DES COMPOSANTS WINDOWS"
echo %COLOR_WHITE%Ce menu regroupe les options pour gerer les fonctionnalites%COLOR_RESET%
echo %COLOR_WHITE%et composants systeme : Securite, interface et applications.%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- SECURITE ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Gerer Windows Defender%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Gerer UAC, le controle du compte utilisateur%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- INTERFACE ---%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Gerer les Animations Windows%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Gerer Copilot, Widgets et Recall sous Windows 11%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS MICROSOFT ---%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_RED%Desinstaller OneDrive Completement%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desinstaller Edge Completement%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- RUNTIMES ET DEPENDANCES ---%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_GREEN%Installer les runtimes Visual C++ et DirectX de juin 2010%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS ET NETTOYAGE ---%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Supprimer les applications Windows inutiles%COLOR_RESET%
call :SUBMENU_CHOICE "principal" "Choisissez une option [1-8, M] : " 12345678M
REM  Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 9 goto :MENU_PRINCIPAL
if !errorlevel! EQU 8  goto :SUPPRIMER_BLOATWARES
if !errorlevel! EQU 7  goto :DO_INSTALLER_VISUAL_REDIST
if !errorlevel! EQU 6  goto :DESINSTALLER_EDGE
if !errorlevel! EQU 5  goto :DESINSTALLER_ONEDRIVE
if !errorlevel! EQU 4  goto :MENU_IA_WIDGETS_RECALL
if !errorlevel! EQU 3  goto :TOGGLE_ANIMATIONS
if !errorlevel! EQU 2  goto :TOGGLE_UAC
if !errorlevel! EQU 1  goto :TOGGLE_DEFENDER
goto :MENU_GESTION_WINDOWS

:DO_INSTALLER_VISUAL_REDIST
call :INSTALLER_VISUAL_REDIST
goto :MENU_GESTION_WINDOWS

:TOUT_OPTIMISER
call :CHOISIR_PROFILS "TOUT OPTIMISER : CONFIGURATION" "BOTH"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
goto :TOUT_OPTIMISER_QUESTIONS

:TOUT_OPTIMISER_QUESTIONS
cls
set "APPLIQUER_SECURITE=0"
set "DESACTIVER_DEFENDER=0"
set "DESACTIVER_ANIMATIONS=0"
set "DESACTIVER_IA=0"
set "DESACTIVER_UAC=0"
set "AIO_USAGE_NAME=NORMAL"
set "AIO_POWER_NAME=ECO"
if "!PROFIL_USAGE!"=="0" set "AIO_USAGE_NAME=GAMING"
if "!PROFIL_POWER!"=="0" set "AIO_POWER_NAME=PERFORMANCE MAX"
call :AIO_QUESTION_HEADER 1 "PROTECTIONS WINDOWS"
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE% Vous avez choisi GAMING pour privilegier les jeux et la reactivite.%COLOR_RESET%
    echo %COLOR_WHITE% Le script peut adapter les protections Windows a cet usage :%COLOR_RESET%
    echo %COLOR_WHITE% il garde celles utiles aux anti-cheats modernes et reduit%COLOR_RESET%
    echo %COLOR_WHITE% certaines protections avancees couteuses en performances.%COLOR_RESET%
    echo.
    echo %COLOR_GREEN% [RECOMMANDE]%COLOR_RESET% %COLOR_WHITE%Reglage conseille pour tous types de jeux.%COLOR_RESET%
    echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Modifiable ensuite depuis Gerer les protections Windows.%COLOR_RESET%
    echo.
    echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
    echo %COLOR_GREEN% [O] APPLIQUER%COLOR_RESET%        - Adapter les protections Windows aux jeux
) else (
    echo %COLOR_WHITE% Vous avez choisi NORMAL pour un usage quotidien et stable.%COLOR_RESET%
    echo %COLOR_WHITE% Le script peut appliquer sa base de protections Windows,%COLOR_RESET%
    echo %COLOR_WHITE% dont l'isolation memoire et le blocage des pilotes vulnerables.%COLOR_RESET%
    echo.
    echo %COLOR_GREEN% [RECOMMANDE]%COLOR_RESET% %COLOR_WHITE%Adapte a un usage quotidien, stable et polyvalent.%COLOR_RESET%
    echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Modifiable ensuite depuis Gerer les protections Windows.%COLOR_RESET%
    echo.
    echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
    echo %COLOR_GREEN% [O] APPLIQUER%COLOR_RESET%        - Utiliser la base de protections Windows
)
echo %COLOR_CYAN% [N] NE PAS MODIFIER%COLOR_RESET%  - Garder les reglages actuels
echo %COLOR_YELLOW% [M] ANNULER%COLOR_RESET%          - Retourner au menu principal
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW% Votre choix [O/N/M] : %COLOR_RESET%" APPLIQUER_SECURITE
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

call :AIO_QUESTION_HEADER 2 "WINDOWS DEFENDER"
echo %COLOR_WHITE% Defender est l'antivirus integre de Windows.%COLOR_RESET%
echo %COLOR_WHITE% Le desactiver coupe l'analyse en temps reel et SmartScreen.%COLOR_RESET%
echo.
echo %COLOR_RED% [ATTENTION]%COLOR_RESET% %COLOR_WHITE%Ne le desactivez que si un autre antivirus protege le PC.%COLOR_RESET%
echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Vous pourrez reactiver Defender depuis Gestion Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_RED% [O] DESACTIVER%COLOR_RESET%        - Couper Defender et les protections associees
echo %COLOR_GREEN% [N] NE PAS DESACTIVER%COLOR_RESET% - Laisser Defender tel quel %COLOR_GREEN%[RECOMMANDE]%COLOR_RESET%
echo %COLOR_YELLOW% [M] ANNULER%COLOR_RESET%           - Retourner au menu principal
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW% Votre choix [O/N/M] : %COLOR_RESET%" DESACTIVER_DEFENDER
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

call :AIO_QUESTION_HEADER 3 "ANIMATIONS WINDOWS"
echo %COLOR_WHITE% Les animations rendent l'interface plus fluide visuellement.%COLOR_RESET%
echo %COLOR_WHITE% Les retirer peut rendre un PC limite plus reactif.%COLOR_RESET%
echo.
echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Ce reglage est reversible depuis le menu Gestion Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_CYAN% [O] DESACTIVER%COLOR_RESET%      - Retirer les animations et la transparence
echo %COLOR_GREEN% [N] NE PAS MODIFIER%COLOR_RESET% - Garder les effets visuels actuels
echo %COLOR_YELLOW% [M] ANNULER%COLOR_RESET%         - Retourner au menu principal
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW% Votre choix [O/N/M] : %COLOR_RESET%" DESACTIVER_ANIMATIONS
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

call :AIO_QUESTION_HEADER 4 "COPILOT, WIDGETS ET RECALL"
echo %COLOR_WHITE% Cette option bloque Copilot, masque les Widgets et desactive Recall.%COLOR_RESET%
echo %COLOR_WHITE% Elle utilise les reglages disponibles sur votre version de Windows.%COLOR_RESET%
echo.
echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Recall ne creera plus de nouveaux instantanes.%COLOR_RESET%
echo %COLOR_WHITE%        Les instantanes deja enregistres resteront sur le PC.%COLOR_RESET%
echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Chaque fonction disponible pourra etre reactivee depuis Gestion Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_CYAN% [O] DESACTIVER%COLOR_RESET%      - Bloquer Copilot, Widgets et Recall
echo %COLOR_GREEN% [N] NE PAS MODIFIER%COLOR_RESET% - Garder ces fonctions telles quelles
echo %COLOR_YELLOW% [M] ANNULER%COLOR_RESET%         - Retourner au menu principal
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW% Votre choix [O/N/M] : %COLOR_RESET%" DESACTIVER_IA
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

call :AIO_QUESTION_HEADER 5 "CONFIRMATIONS ADMINISTRATEUR - UAC"
echo %COLOR_WHITE% L'UAC demande votre accord avant une action administrateur.%COLOR_RESET%
echo %COLOR_WHITE% Le desactiver permet aux applications d'agir sans cette demande.%COLOR_RESET%
echo.
echo %COLOR_RED% [ATTENTION]%COLOR_RESET% %COLOR_WHITE%Cela facilite aussi les actions non souhaitees.%COLOR_RESET%
echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Vous pourrez reactiver l'UAC depuis Gestion Windows.%COLOR_RESET%
echo %COLOR_YELLOW% [INFO]%COLOR_RESET% %COLOR_WHITE%Defender et SmartScreen ne seront pas modifies.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_RED% [O] DESACTIVER%COLOR_RESET%        - Supprimer les confirmations apres redemarrage
echo %COLOR_GREEN% [N] NE PAS DESACTIVER%COLOR_RESET% - Laisser l'UAC tel quel %COLOR_GREEN%[RECOMMANDE]%COLOR_RESET%
echo %COLOR_YELLOW% [M] ANNULER%COLOR_RESET%           - Retourner au menu principal
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW% Votre choix [O/N/M] : %COLOR_RESET%" DESACTIVER_UAC
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

call :SCREEN_HEADER " TOUT OPTIMISER - VERIFICATION"
echo %STYLE_BOLD%%COLOR_CYAN% CONFIGURATION%COLOR_RESET%
echo %COLOR_WHITE%   Usage     : !AIO_USAGE_NAME!%COLOR_RESET%
echo %COLOR_WHITE%   Energie   : !AIO_POWER_NAME!%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_CYAN% OPTIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!APPLIQUER_SECURITE!"=="1" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_CYAN% [APPLIQUER]%COLOR_RESET% %COLOR_WHITE%Protections Windows adaptees aux jeux%COLOR_RESET%
    ) else (
        echo %COLOR_CYAN% [APPLIQUER]%COLOR_RESET% %COLOR_WHITE%Base de protections Windows%COLOR_RESET%
    )
) else (
    echo %COLOR_GREEN% [INCHANGE]%COLOR_RESET% %COLOR_WHITE%Reglages de securite actuels%COLOR_RESET%
)
if "!DESACTIVER_DEFENDER!"=="1" (
    echo %COLOR_RED% [DESACTIVER]%COLOR_RESET% %COLOR_WHITE%Windows Defender%COLOR_RESET%
) else (
    echo %COLOR_GREEN% [INCHANGE]%COLOR_RESET% %COLOR_WHITE%Windows Defender%COLOR_RESET%
)
if "!DESACTIVER_ANIMATIONS!"=="1" (
    echo %COLOR_YELLOW% [DESACTIVER]%COLOR_RESET% %COLOR_WHITE%Animations Windows%COLOR_RESET%
) else (
    echo %COLOR_GREEN% [INCHANGE]%COLOR_RESET% %COLOR_WHITE%Animations Windows%COLOR_RESET%
)
if "!DESACTIVER_IA!"=="1" (
    echo %COLOR_CYAN% [DESACTIVER]%COLOR_RESET% %COLOR_WHITE%Copilot, Widgets et Recall%COLOR_RESET%
) else (
    echo %COLOR_GREEN% [INCHANGE]%COLOR_RESET% %COLOR_WHITE%Copilot, Widgets et Recall%COLOR_RESET%
)
if "!DESACTIVER_UAC!"=="1" (
    echo %COLOR_RED% [DESACTIVER]%COLOR_RESET% %COLOR_WHITE%Confirmations UAC%COLOR_RESET%
) else (
    echo %COLOR_GREEN% [INCHANGE]%COLOR_RESET% %COLOR_WHITE%Confirmations UAC%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN% [O] LANCER%COLOR_RESET%  - Demarrer l'optimisation avec ces choix
echo %COLOR_CYAN% [R] REVOIR%COLOR_RESET%  - Recommencer les cinq questions
echo %COLOR_YELLOW% [M] ANNULER%COLOR_RESET% - Retourner au menu principal
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW% Votre choix [O/R/M] : %COLOR_RESET%"
call :AZCHOICE ORM
if !errorlevel! EQU 3 goto :MENU_PRINCIPAL
if !errorlevel! EQU 2 goto :TOUT_OPTIMISER_QUESTIONS
if !errorlevel! NEQ 1 goto :MENU_PRINCIPAL

cls
set "SKIP_PAUSE=1"
set "AIO_MODE=1"
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Demarrage de Tout optimiser avec les choix du recapitulatif.%COLOR_RESET%
echo %COLOR_WHITE%       Les options non selectionnees restent inchangees.%COLOR_RESET%
echo.
REM Preselection silencieuse uniquement : la SECTION 7 reste executee dans l'ordre apres 1 a 6.
REM Les sections precedentes qui ecrivent dans SCHEME_CURRENT ciblent ainsi le bon plan.
set "AIO_POWER_PRESELECTED=0"
call :SELECT_TARGET_POWER_SCHEME !PROFIL_POWER!
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible d'activer le plan d'alimentation cible. Aucune optimisation n'a ete appliquee.%COLOR_RESET%
    set "SKIP_PAUSE=0"
    set "AIO_MODE=0"
    set "AIO_POWER_PRESELECTED="
    goto :MENU_PRINCIPAL
)
set "AIO_POWER_PRESELECTED=1"
call :INSTALLER_VISUAL_REDIST
call :OPTIMISATIONS_SYSTEME
call :OPTIMISATIONS_MEMOIRE
call :OPTIMISATIONS_DISQUES
call :OPTIMISATIONS_GPU
call :OPTIMISATIONS_RESEAU
call :OPTIMISATIONS_PERIPHERIQUES
if "!PROFIL_POWER!"=="0" (
    call :DESACTIVER_ECONOMIES_ENERGIE
) else (
    call :RESTAURER_ECONOMIES_ENERGIE
)
if "!APPLIQUER_SECURITE!"=="1" (
    call :APPLIQUER_PROFIL_SECURITE
)
if "!DESACTIVER_DEFENDER!"=="1" (
    call :DESACTIVER_DEFENDER_SECTION
)
if "!DESACTIVER_ANIMATIONS!"=="1" (
    call :DESACTIVER_ANIMATIONS_SECTION
)
if "!DESACTIVER_IA!"=="1" (
  call :DESACTIVER_IA_SECTION
)
if "!DESACTIVER_UAC!"=="1" (
  call :DESACTIVER_UAC_SECTION
)
call :AFFICHER_RESUME_OPTIMISATION
set "AIO_MODE=0"
set "SKIP_PAUSE=0"
set "AIO_POWER_PRESELECTED="
set "APPLIQUER_SECURITE="
set "DESACTIVER_DEFENDER="
set "DESACTIVER_ANIMATIONS="
set "DESACTIVER_IA="
set "DESACTIVER_UAC="
goto :MENU_PRINCIPAL

:AFFICHER_RESUME_OPTIMISATION
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    echo %STYLE_BOLD%%COLOR_WHITE% PARCOURS TERMINE : USAGE GAMING %COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% PARCOURS TERMINE : USAGE NORMAL %COLOR_RESET%
)
if "!PROFIL_POWER!"=="0" (
    echo %STYLE_BOLD%%COLOR_WHITE% Energie : PERFORMANCE MAX%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% Energie : ECO%COLOR_RESET%
)
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %STYLE_BOLD%%COLOR_BLUE%-- PARCOURS EFFECTUE ------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Sections Systeme, Memoire, Disques et GPU executees.%COLOR_RESET%
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Sections Reseau et Peripheriques executees.%COLOR_RESET%
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Runtimes Visual C++ et DirectX traites.%COLOR_RESET%
if "!PROFIL_POWER!"=="0" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Energie Performance max demandee.%COLOR_RESET%
    echo %COLOR_WHITE%Performances et consommation augmentees.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Energie Eco demandee : Plan Equilibre et economies d'energie actives.%COLOR_RESET%
)
echo.

echo %STYLE_BOLD%%COLOR_BLUE%-- OPTIONS COMPLEMENTAIRES ------------------------------------------------------%COLOR_RESET%
if "!APPLIQUER_SECURITE!"=="1" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[DEMANDE]%COLOR_RESET% %COLOR_WHITE%Protections Windows adaptees aux jeux demandees.%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[DEMANDE]%COLOR_RESET% %COLOR_WHITE%Base de protections Windows demandee.%COLOR_RESET%
    )
) else (
    echo %COLOR_CYAN%[INCHANGE]%COLOR_RESET% %COLOR_WHITE%Aucun changement des protections Windows.%COLOR_RESET%
)
if "!DESACTIVER_DEFENDER!"=="1" (
    echo %COLOR_YELLOW%[DEMANDE]%COLOR_RESET% %COLOR_WHITE%Desactivation de Windows Defender demandee.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[INCHANGE]%COLOR_RESET% %COLOR_WHITE%Aucun changement de Windows Defender.%COLOR_RESET%
)
if "!DESACTIVER_UAC!"=="1" (
    echo %COLOR_YELLOW%[DEMANDE]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'UAC demandee.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[INCHANGE]%COLOR_RESET% %COLOR_WHITE%Aucun changement de l'UAC.%COLOR_RESET%
)
if "!DESACTIVER_ANIMATIONS!"=="1" (
    echo %COLOR_YELLOW%[DEMANDE]%COLOR_RESET% %COLOR_WHITE%Reduction des animations et effets visuels demandee.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[INCHANGE]%COLOR_RESET% %COLOR_WHITE%Aucun changement des animations Windows.%COLOR_RESET%
)
if "!DESACTIVER_IA!"=="1" (
    echo %COLOR_YELLOW%[DEMANDE]%COLOR_RESET% %COLOR_WHITE%Restrictions Copilot, Widgets et Recall demandees.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[INCHANGE]%COLOR_RESET% %COLOR_WHITE%Aucun changement de Copilot, Widgets et Recall.%COLOR_RESET%
)
echo.

echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les reglages.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous redemarrer maintenant ? [O/N] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! EQU 1 (
    shutdown /r /t 3 /c "Redemarrage demande par WindowsOptimizer"
    if !errorlevel! EQU 0 (
        echo.
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Redemarrage dans 3 secondes...%COLOR_RESET%
        timeout /t 2 /nobreak >nul
    ) else (
        echo.
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de la demande de redemarrage. Veuillez redemarrer manuellement.%COLOR_RESET%
        pause
    )
)
exit /b

:OPTIMISATIONS_SYSTEME
cls
call :INIT_PROFILS
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 1 : OPTIMISATIONS SYSTEME%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Ajuste la reactivite, l'interface et la confidentialite,%COLOR_RESET%
echo %COLOR_WHITE%  les services et le demarrage de Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% : Reactivite maximale%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% : Usage quotidien, stabilite et confort%COLOR_RESET%
)
echo.

REM  1.0 - Surcharges BCD des timers : suppression pour tous les profils.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression des surcharges BCD de diagnostic des timers...%COLOR_RESET%
call :RESET_BCD_TIMER_OVERRIDES
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Horloges platform et synchronisation TSC rendues a Windows.%COLOR_RESET%

REM  1.1 - Priorites CPU et planification
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la reactivite du systeme...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEngCP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
) else (
    REM Windows stock : Win32PrioritySeparation=2 et aucun override IFEO de l'outil.
    for %%V in (CpuPriorityClass IoPriority) do reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "%%V" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEngCP.exe\PerfOptions" /v CpuPriorityClass /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages de reactivite appliques%COLOR_RESET%

REM  1.2 - Profil Gaming MMCSS SystemProfile\Tasks\Games
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration du profil de jeu et de la reactivite multimedia...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
) else (
    REM Windows stock 25H2 : Medium / Normal / Priority 2 / GPU Priority 8.
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "Medium" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "Normal" /f >nul 2>&1
)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Profil de jeu et reactivite multimedia configures%COLOR_RESET%

REM  1.3 - Interface Windows
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Optimisation de l'interface Windows...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontPrettyPath" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DesktopLivePreviewHoverTime" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SeparateProcess" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
REM  Windows 11 : desactiver les suggestions et les applications recemment ajoutees dans tous les profils.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowRecentList /t REG_DWORD /d 0 /f >nul 2>&1
REM  Gaming masque aussi Recommandations et Tout ; Normal supprime ces politiques.
if "!PROFIL_USAGE!"=="0" (
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoStartMenuMorePrograms /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection /f >nul 2>&1
    reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HideCategoryView /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoStartMenuMorePrograms /f >nul 2>&1
)
REM  ShowFrequent - Cache des fichiers recents (ne desactive PAS l'indexation Windows)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v DesktopProcess /t REG_DWORD /d 1 /f >nul 2>&1
REM InitialKeyboardIndicators est laisse intact : le stock Windows 25H2 mesure est 2147483648.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f >nul 2>&1

REM  1.4 - Telemetrie et vie privee
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des publicites...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul 2>&1

REM  Optimiser le cache d'icones et miniatures
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_DWORD /d 8192 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul 2>&1

REM  Desactiver la compression des papiers peints
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Interface et confidentialite de base optimisees%COLOR_RESET%

REM  1.5 - Telemetrie systeme et vie privee approfondie
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des traceurs...%COLOR_RESET%
REM  Registre : telemetrie et publicites
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
REM PeriodInNanoSeconds laisse intact : aucune suppression hors section restauration.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Feedback" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1

REM  Content Delivery Manager
for %%V in (ContentDeliveryAllowed FeatureManagementEnabled OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled RemediationRequired RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled SilentInstalledAppsEnabled SoftLandingEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SubscribedContent-310093Enabled SubscribedContent-314563Enabled SubscribedContent-338380Enabled SubscribedContent-338381Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v %%V /t REG_DWORD /d 0 /f >nul 2>&1
)

REM  Recherche Windows - Bing OFF, Cortana OFF (politique + package legacy)
REM  AllowCortana=0 : politique Microsoft officielle (Windows Search local conserve)
REM  ShowCortanaButton/CortanaConsent : cles legacy encore utiles sur anciens builds W10/W11
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Microsoft.549981C3F5F10' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

REM  Activity History OFF
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Telemetrie et publicites desactivees%COLOR_RESET%

REM  Taches planifiees de telemetrie
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des taches planifiees de telemetrie...%COLOR_RESET%
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

REM  Autologgers de diagnostic OFF
for %%L in (AppModel Cellcore DiagLog SQMLogger Diagtrack-Listener) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~L" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" /v Start /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Taches de telemetrie desactivees%COLOR_RESET%

REM  Blocage telemetrie via hosts
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation du blocage de la telemetrie...%COLOR_RESET%
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
attrib -r "%HOSTS%" >nul 2>&1

REM  Backup unique du fichier hosts avant modification ; aucun .bak existant n'est ecrase.
call :BACKUP_HOSTS_BEFORE_CHANGE "%HOSTS%"
set "HOSTS_BACKUP_RC=!errorlevel!"
if "!HOSTS_BACKUP_RC!" NEQ "0" (
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Backup hosts impossible : le fichier ne sera pas modifie.%COLOR_RESET%
    set "HOSTS="
)
REM  Utilisation de PowerShell pour mettre a jour ou ajouter le bloc securise (Telemetrie uniquement)
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$h=$env:HOSTS;$tmp=[System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($h),([System.IO.Path]::GetFileName($h)+'.'+[guid]::NewGuid().ToString('N')+'.tmp'));$crlf=[char]13+[char]10;$s='# Telemetry Block Start';$e='# Telemetry Block End';$domains='vortex.data.microsoft.com','vortex-win.data.microsoft.com','v10.vortex-win.data.microsoft.com','v10.events.data.microsoft.com','telecommand.telemetry.microsoft.com','oca.telemetry.microsoft.com','watson.telemetry.microsoft.com','watsonc.microsoft.com','settings.data.microsoft.com','settings-win.data.microsoft.com','mobile.events.data.microsoft.com','browser.events.data.microsoft.com','self.events.data.microsoft.com','v20.events.data.microsoft.com','telemetry.microsoft.com','telemetrycollector.microsoft.com','pipe.aria.microsoft.com','diagnostics.office.com','activity.windows.com','modern.watson.data.microsoft.com','applicationinsights.microsoft.com','azurewatson.microsoft.com';$nb=$crlf+$s+$crlf;foreach($d in $domains){$nb+='0.0.0.0 '+$d+$crlf};$nb+=$e+$crlf;try{if(Test-Path -LiteralPath $h){$cur=[System.IO.File]::ReadAllText($h,[System.Text.Encoding]::ASCII)}else{$cur=''};$cur=$cur -replace ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)),'';foreach($d in $domains){$cur=$cur -replace ('(?m)^0\.0\.0\.0\s+'+[regex]::Escape($d)+'\s*$'),''};$cur=$cur.TrimEnd()+$nb;if(Test-Path -LiteralPath $h){(Get-Item -LiteralPath $h).Attributes='Normal'};[System.IO.File]::WriteAllText($tmp,$cur,[System.Text.Encoding]::ASCII);[System.IO.File]::Copy($tmp,$h,$true);Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;exit 0}catch{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;exit 1}" >nul 2>&1
set "HOSTS_RC=!errorlevel!"
if "!HOSTS_RC!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Bloc de telemetrie ajoute au fichier hosts%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Fichier hosts non modifie. Les autres reglages continuent.%COLOR_RESET%
)
attrib +r "%HOSTS%" >nul 2>&1
if not "!AIO_MODE!"=="1" ipconfig /flushdns >nul 2>&1
set "HOSTS_RC="
set "HOSTS="
set "HOSTS_BACKUP_RC="

REM  1.6 - Services optimises
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation du reglage des services Windows...%COLOR_RESET%
set "SERVICE_CONFIG_SKIPPED=0"

REM  1 - Services vitaux -> AUTOMATIQUE
for %%S in (
    W32Time
    WpnService
    SysMain
    defragsvc
) do (
  call :SET_EXISTING_SERVICE_START "%%S" 2
)
REM  Configuration du service par utilisateur WpnUserService
call :SET_EXISTING_SERVICE_START "WpnUserService" 2

REM  2 - Services occasionnels et utiles -> MANUEL (demand)
for %%S in (
    ALG
    AppVClient
    BDESVC
    CertPropSvc
    CscService
    GraphicsPerfSvc
    icssvc
    IKEEXT
    lfsvc
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
    WerSvc
    SystemSuggestions
    uhssvc
) do (
  call :SET_EXISTING_SERVICE_START "%%S" 3
)
REM  CDPUserSvc est un service par utilisateur
call :SET_EXISTING_SERVICE_START "CDPUserSvc" 3

REM  3 - Services inutiles et telemetrie -> DESACTIVES
for %%S in (
    AJRouter
    AxInstSV
    DiagTrack
    diagnosticshub.standardcollector.service
    DialogBlockingService
    Fax
    lltdsvc
    NetTcpPortSharing
    RemoteAccess
    RemoteRegistry
    RetailDemo
    shpamsvc
    ssh-agent
    UevAgentService
    WalletService
    WMPNetworkSvc
) do (
  call :SET_EXISTING_SERVICE_START "%%S" 4
)

REM  SEMgrSvc est Manual sur Windows 11 stock. Sur un portable Normal+Eco, le conserver
REM  en Manual : le forcer Disabled peut faire attendre/echouer la page moderne
REM  Parametres > Systeme > Alimentation et batterie. Les autres profils gardent le tuning historique.
if "!DETECTE_PORTABLE!"=="1" if "!PROFIL_USAGE!"=="1" if "!PROFIL_POWER!"=="1" (
  call :SET_EXISTING_SERVICE_START "SEMgrSvc" 3
) else (
  call :SET_EXISTING_SERVICE_START "SEMgrSvc" 4
)

echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Configuration demandee pour les services presents%COLOR_RESET%
if !SERVICE_CONFIG_SKIPPED! GTR 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%!SERVICE_CONFIG_SKIPPED! service ou services absents ignores. Aucune entree inutile creee%COLOR_RESET%
set "SERVICE_CONFIG_SKIPPED="

REM  Services critiques laisses intacts : Bluetooth, Hello, RDP, Spooler, PlugPlay
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Services utiles regles. Bluetooth, VPN, Hello et RDP preserves%COLOR_RESET%

REM  1.7 - Optimisations demarrage et systeme
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme diverses...%COLOR_RESET%
REM  Supprimer le delai de demarrage des applications
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul 2>&1
REM  Desactiver l'attente etat idle avant lancement apps au login (reduit le delai sur Win10/11)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "WaitForIdleState" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "08" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "32" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t REG_DWORD /d 7 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Optimisations demarrage et stockage terminees%COLOR_RESET%

REM  1.8 - Utilitaires et Bloatwares (Automatique)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Ajout de l'option Devenir Proprietaire au menu contextuel...%COLOR_RESET%
reg add "HKCR\*\shell\runas" /ve /t REG_SZ /d "Devenir Proprietaire" /f >nul 2>&1
reg add "HKCR\*\shell\runas" /v "NoWorkingDirectory" /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\*\shell\runas\command" /ve /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" && icacls \"%%1\" /grant administrators:F" /f >nul 2>&1
reg add "HKCR\*\shell\runas" /v "IsolatedCommand" /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" && icacls \"%%1\" /grant administrators:F" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas" /ve /t REG_SZ /d "Devenir Proprietaire" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas" /v "NoWorkingDirectory" /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas\command" /ve /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" /r /d o || takeown /f \"%%1\" /r /d y && icacls \"%%1\" /grant administrators:F /t" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas" /v "IsolatedCommand" /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" /r /d o || takeown /f \"%%1\" /r /d y && icacls \"%%1\" /grant administrators:F /t" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Option Devenir Proprietaire ajoutee au menu contextuel.%COLOR_RESET%

REM  Desactivation des Co-installateurs tiers (Razer/Logitech Popup)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation du reglage des installateurs tiers...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Co-installateurs tiers desactives.%COLOR_RESET%

REM  Privacy Supplementaire
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des reglages de confidentialite complementaires...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f >nul 2>&1

REM  Privacy avancee
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des reglages de confidentialite avances...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DisableDeviceDiagnosticData /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v UploadPermission /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Handwriting" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v PreventHandwritingDataSharing /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PerfTrack" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\PerfTrack" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages de confidentialite avances appliques%COLOR_RESET%

REM  1.9 - Navigateurs
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Optimisation navigateurs...%COLOR_RESET%
REM  Microsoft Edge
REM  DoH mode "allow" : chiffre le DNS quand Cloudflare est joignable, repli DNS normal sinon
REM  ("secure" interdirait tout repli et casse les reseaux filtres/proxy d'entreprise).
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d allow /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v EdgeCollectionsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NetworkPredictionOptions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NewTabPagePrerenderEnabled /t REG_DWORD /d 1 /f >nul 2>&1

REM  Google Chrome
reg add "HKCU\Software\Policies\Google\Chrome" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsMode /t REG_SZ /d allow /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Navigateurs optimises%COLOR_RESET%

REM  1.10 - Desactivation du stockage reserve
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation du stockage reserve Windows...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v PassedPolicy /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Desactivation du stockage reserve demandee.%COLOR_RESET%
echo %COLOR_WHITE%Windows appliquera ce reglage selon son etat.%COLOR_RESET%

REM  1.11 - Desactivation P2P Windows Update (Delivery Optimization)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation du P2P Windows Update...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mises a jour Windows telechargees depuis Microsoft uniquement%COLOR_RESET%

REM  1.12 - Blocage des pubs Store dans la recherche
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Blocage des recommandations Store dans la recherche...%COLOR_RESET%
set "STORE_DB=%LocalAppData%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db"
if exist "!STORE_DB!" (
    REM  SID *S-1-1-0 = groupe "Tout le monde" : independant de la langue Windows.
    REM  ("Everyone" echoue sur un Windows francais : erreur 1332, refus jamais pose.)
    REM  Retirer un eventuel refus identique avant de le reposer rend l'operation idempotente ;
    REM  pour revenir en arriere manuellement : icacls "<chemin vers store.db>" /remove:d *S-1-1-0
    icacls "!STORE_DB!" /remove:d *S-1-1-0 >nul 2>&1
    icacls "!STORE_DB!" /deny *S-1-1-0:F >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pubs Store bloquees dans la recherche%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Blocage des pubs Store non applique ; le script continue.%COLOR_RESET%
    )
) else (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%Base du Store absente ; rien a bloquer.%COLOR_RESET%
)
set "STORE_DB="

REM  1.13 - Affichage du code erreur BSoD
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de l'affichage des codes erreur BSoD...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DisplayParameters /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Codes d'erreur BSoD visibles pour faciliter le diagnostic%COLOR_RESET%

REM  1.14 - Desactivation de l'aide F1
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de la touche F1 et de l'aide Windows...%COLOR_RESET%
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Touche F1 desactivee pour eviter l'ouverture de l'aide%COLOR_RESET%

REM  1.15 - Optimisations audio (latence)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'attenuation audio Windows...%COLOR_RESET%
powershell -NoProfile -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}'; Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { New-ItemProperty -Path $_.PSPath -Name 'DisableAudioEndpointDucking' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } " >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Attenuation audio desactivee (Microphone et sons synchronises)%COLOR_RESET%

REM  1.16 - Desactivation Windows Platform Binary Table (WPBT)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de WPBT pour limiter les logiciels preinstalles...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%WPBT desactive%COLOR_RESET%

REM  1.17 - Intel Thread Director / Core Parking (profil-aware)
REM  SCHEDPOLICY : 0=Tous, 1=Performants, 2=Preferer performants, 3=Efficients, 4=Preferer efficients, 5=Auto.
REM  Ne fait rien sur CPU non-hybride (AMD, Intel avant 12th gen).
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration de la planification des coeurs du processeur...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
if "!PROFIL_USAGE!"=="0" (
    powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2 >nul 2>&1
    if "!DETECTE_PORTABLE!"=="1" (
        powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5 >nul 2>&1
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage Gaming : performances favorisees sur secteur.%COLOR_RESET%
        echo %COLOR_WHITE%La batterie reste equilibree.%COLOR_RESET%
    ) else (
        powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2 >nul 2>&1
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage Gaming : performances favorisees sur secteur et batterie.%COLOR_RESET%
    )
) else (
    call :SET_POWERCFG_ACDC 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Planification des coeurs reglee pour le profil Normal%COLOR_RESET%
)

call :FINISH_ACTION "Reglages systeme" "traites"
exit /b 0

:OPTIMISATIONS_MEMOIRE
cls
call :INIT_PROFILS
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 2 : OPTIMISATIONS MEMOIRE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Configure la RAM, le fichier d'echange, Prefetch, FTH et la%COLOR_RESET%
echo %COLOR_WHITE%  compression memoire selon le profil d'energie et la RAM detectee.%COLOR_RESET%
echo.
if "!PROFIL_POWER!"=="0" (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%Performance max%COLOR_RESET%
    echo %COLOR_WHITE%  Compression memoire desactivee si la RAM depasse 8 Go.%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%ECO%COLOR_RESET%%COLOR_WHITE% : Compression memoire activee pour favoriser l'autonomie%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.

REM  2.1 - Memory Management
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Optimisation de la gestion memoire...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemPages" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion memoire optimisee%COLOR_RESET%

REM  2.2 - Prefetch/SysMain
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration de Prefetch et SuperFetch...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1
    REM Activer Superfetch ; Prefetcher=1 = prefetch applications uniquement (boot prefetch laisse au stock).
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    REM Windows stock 25H2 : EnablePrefetcher=3 et autres valeurs absentes.
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 3 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Prefetch et SuperFetch configures pour accelerer le chargement%COLOR_RESET%

REM  2.3 et 2.4 - Reglages memoire dependants du profil d'energie.
REM  La meme routine est appelee par le changement manuel Eco/Performance max.
call :SET_MEMORY_POWER_PROFILE
set "MEMORY_POWER_PROFILE_RC=!errorlevel!"
if not "!MEMORY_POWER_PROFILE_RC!"=="0" echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Le profil memoire reste partiellement applique.%COLOR_RESET%

call :FINISH_ACTION "Reglages memoire" "traites"
exit /b !MEMORY_POWER_PROFILE_RC!

:OPTIMISATIONS_DISQUES
call :INIT_PROFILS
call :SCREEN_HEADER " SECTION 3 : OPTIMISATIONS DISQUES ET STOCKAGE"
echo %COLOR_WHITE%  Cette section conserve le TRIM et la maintenance Windows,%COLOR_RESET%
echo %COLOR_WHITE%  puis adapte les chemins longs au profil choisi.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.

REM  3.1 - TRIM et restauration des heuristiques NTFS
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation du TRIM et retour des reglages NTFS a Windows...%COLOR_RESET%
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
if "!PROFIL_USAGE!"=="0" (
    REM Gaming conserve ces valeurs sous controle du systeme.
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisable8dot3NameCreation /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMemoryUsage /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMftZoneReservation /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableCompression /f >nul 2>&1
) else (
    REM Windows stock 25H2 mesure : LastAccess=-2147483646, 8.3=2, reste=0.
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 0x80000002 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisable8dot3NameCreation /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMemoryUsage /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMftZoneReservation /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableCompression /t REG_DWORD /d 0 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%TRIM actif et reglages NTFS confies a Windows%COLOR_RESET%

REM  3.2 - Chemins longs NTFS
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation des chemins longs de plus de 260 caracteres...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    REM Windows stock 25H2 mesure : fonctionnalite des chemins longs desactivee.
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Support des chemins longs active pour Gaming.%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Chemins longs rendus au stock Windows.%COLOR_RESET%)

REM  3.3 - TRIM sur volumes SSD
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation de la verification du TRIM...%COLOR_RESET%
set "TRIM_STATUS="
for /f "usebackq delims=" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$stampDir=Join-Path $env:ProgramData 'WindowsOptimizer'; $oldStampDir=Join-Path $env:ProgramData 'OptimizerAllInOne'; $stampFile=Join-Path $stampDir 'last_retrim.txt'; $oldStampFile=Join-Path $oldStampDir 'last_retrim.txt'; if((Test-Path $oldStampFile) -and -not (Test-Path $stampFile)){ if(-not (Test-Path $stampDir)){ New-Item -ItemType Directory -Path $stampDir -Force | Out-Null }; Move-Item -Path $oldStampFile -Destination $stampFile -Force -ErrorAction SilentlyContinue }; $ssds=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -ne 'HDD' -and $_.OperationalStatus -eq 'OK' -and $_.BusType -notin @('Virtual','FileBackedVirtual') }; if(-not $ssds -or $ssds.Count -eq 0){ 'NO_SSD'; exit 0 }; if((Test-Path $stampFile) -and ((Get-Date) - (Get-Item $stampFile).LastWriteTime).TotalDays -lt 30){ 'SKIP_RECENT'; exit 0 }; if(-not (Test-Path $stampDir)){ New-Item -ItemType Directory -Path $stampDir -Force | Out-Null }; $vols=Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and ($_.FileSystem -in @('NTFS','ReFS')) }; $done=$false; foreach($v in $vols){ $part=Get-Partition -DriveLetter $v.DriveLetter -ErrorAction SilentlyContinue; if($part){ $phys=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $part.DiskNumber }; if($phys -and $phys.MediaType -ne 'HDD' -and $phys.BusType -notin @('Virtual','FileBackedVirtual')){ try { Optimize-Volume -DriveLetter $v.DriveLetter -ReTrim -ErrorAction Stop | Out-Null; $done=$true } catch {} } } }; if($done){ Set-Content -Path $stampFile -Value (Get-Date -Format s) -Force; 'TRIM_DONE' } else { 'NO_SSD' }" 2^>nul`) do set "TRIM_STATUS=%%a"
if not defined TRIM_STATUS (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Passage TRIM ignore ; le script continue.%COLOR_RESET%
) else if "%TRIM_STATUS%"=="TRIM_DONE" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%TRIM execute sur les volumes SSD. Prochain passage dans 30 jours%COLOR_RESET%
) else if "%TRIM_STATUS%"=="SKIP_RECENT" (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%TRIM ignore. Passage deja effectue il y a moins de 30 jours%COLOR_RESET%
) else if "%TRIM_STATUS%"=="NO_SSD" (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%Aucun volume SSD detecte pour l'operation TRIM%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%TRIM non effectue. Motif : !TRIM_STATUS!%COLOR_RESET%
)
set "TRIM_STATUS="

REM  3.4 - Pile NVMe prise en charge par Windows
REM  nvmedisk.sys est officiellement reserve a Windows Server 2025 pour le moment.
REM  Les anciens FeatureManagement overrides et tweaks Storport non documentes sont donc retires.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Nettoyage des forcages NVMe experimentaux...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1853569164 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 156965516 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 735209102 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1176759950 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storport\Parameters" /v "IoRingEnabled" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v "MaxOutstandingIORequests" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Pile NVMe laissee au pilote pris en charge par Windows%COLOR_RESET%

REM  3.5 - Defragmentation automatique geree par Windows (TRIM automatique)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de la maintenance automatique des disques...%COLOR_RESET%
REM  Windows 11 detecte automatiquement les SSD et effectue du TRIM au lieu de defragmentation
REM  Il est important de NE PAS desactiver cette tache pour maintenir le TRIM automatique
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Activation demandee : maintenance automatique des disques.%COLOR_RESET%

call :FINISH_ACTION "Reglages disques" "traites"
exit /b 0

:OPTIMISATIONS_GPU
cls
call :INIT_PROFILS
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 4 : OPTIMISATIONS GPU%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Ameliore la reactivite des jeux et reduit les captures en arriere-plan.%COLOR_RESET%
echo %COLOR_WHITE%  Les reglages s'adaptent a votre profil et a votre carte graphique.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% : Priorite a la latence et a la reactivite du GPU%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% : Priorite a la stabilite et a la veille du GPU%COLOR_RESET%
)
echo.

REM  4.1 - GameDVR desactive - Game Mode ON
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'enregistrement automatique de gameplay...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "HistoricalCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_EFSEFeatureFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%GameDVR desactive. Le mode Jeu reste actif pour les performances%COLOR_RESET%

REM  4.2 - Preferences DirectX (profil-aware : Gaming=latence, Normal=confort visuel)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglages graphiques Gaming : latence prioritaire.%COLOR_RESET%
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=0;VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages DirectX pour reduire la latence%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglages DirectX pour l'affichage...%COLOR_RESET%
    REM Le stock Windows 25H2 ne porte pas cette valeur sur cette installation.
    reg delete "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages DirectX rendus au comportement natif%COLOR_RESET%
)

REM  4.3 - Mode MSI (GPU) et telemetrie NVIDIA
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage des interruptions GPU...%COLOR_RESET%
call :SET_DEVICE_MSI_PROFILE Display !PROFIL_USAGE!
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Reglage MSI GPU applique partiellement.%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "FeatureControl" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "NvTeleSvc" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "DisplayWatchdog" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "NvMessageBus" /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    REM Les valeurs MSI d'origine sont restaurees depuis la sauvegarde par peripherique.
    reg delete "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /f >nul 2>&1
    for %%V in (FeatureControl NvTeleSvc DisplayWatchdog NvMessageBus) do reg delete "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "%%V" /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Interruptions GPU reglees.%COLOR_RESET%

REM  4.4 - Desactivation AMD telemetry
if "!PROFIL_USAGE!"=="0" (echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie AMD...%COLOR_RESET%) else (echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des overrides de telemetrie AMD...%COLOR_RESET%)
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\AMD\CN" /v "CollectGIData" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\ATI ACE\AUEPLauncher" /v "ReportProcessedEvents" /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    reg delete "HKLM\SOFTWARE\AMD\CN" /v "CollectGIData" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\ATI ACE\AUEPLauncher" /v "ReportProcessedEvents" /f >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Telemetrie AMD desactivee%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Overrides AMD retires.%COLOR_RESET%)

REM  4.5 - NVIDIA Low Latency
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des reglages NVIDIA pour reduire la latence...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    REM MaxFrameLatency est lu par le pilote depuis la cle de classe par carte, pas depuis GraphicsDrivers.
    for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
        reg add "%%K" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
    )
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages NVIDIA de faible latence appliques en mode GAMING%COLOR_RESET%
) else (
    for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
        reg delete "%%K" /v MaxFrameLatency /f >nul 2>&1
        reg delete "%%K" /v LOWLATENCY /f >nul 2>&1
        reg delete "%%K" /v Node3DLowLatency /f >nul 2>&1
        reg delete "%%K" /v D3PCLatency /f >nul 2>&1
        reg delete "%%K" /v F1TransitionLatency /f >nul 2>&1
    )
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages de faible latence retires.%COLOR_RESET%
    echo %COLOR_WHITE%Veille du GPU reactivee.%COLOR_RESET%
)

REM  4.6 - HAGS Enable
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de la planification GPU acceleree...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
) else (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Planification GPU acceleree demandee.%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Planification GPU rendue au comportement natif.%COLOR_RESET%)
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le gain depend du GPU, du pilote et du jeu.%COLOR_RESET%
echo %COLOR_WHITE%Des saccades sont possibles selon la configuration.%COLOR_RESET%

REM  4.7 - Preemption GPU
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de la gestion des priorites GPU...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage des priorites demande au pilote GPU.%COLOR_RESET%

REM  4.8 - NVIDIA Profile Inspector
REM  Cette section applique un profil d'optimisation NVIDIA pour reduire l'input lag.
if "!HAS_NVIDIA!"=="1" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation du profil GPU NVIDIA...%COLOR_RESET%

        REM Utilisation de Windows\Temp car le %%TEMP%% utilisateur peut etre sur un RamDisk ou lecteur non mappe en Admin
        set "NPI_DIR=%SystemRoot%\Temp\NPI_%RANDOM%_%RANDOM%"
        REM Copie locale via PowerShell - env WINOPT_SOURCE_DIR, cf 7.10 - contourne expansion differee de cmd
        REM NPI_EXE_SRC et NPI_PROFILE_SRC ne sont plus definis ici : copies via PowerShell ci-dessous
        if not exist "!NPI_DIR!" mkdir "!NPI_DIR!" >nul 2>&1

        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation de NVIDIA Profile Inspector et du profil...%COLOR_RESET%
        REM Priorite aux fichiers locaux livres avec le script, telechargement GitHub en secours.
        powershell -NoProfile -Command "try{$b=Join-Path $env:WINOPT_SOURCE_DIR 'Tools\NVIDIA Inspector';$d=$env:NPI_DIR;$e=Join-Path $d 'nvidiaProfileInspector.exe';$p=Join-Path $d 'Kaylers_profile.nip';if(-not([IO.File]::Exists($e))){$s=Join-Path $b 'nvidiaProfileInspector.exe';if([IO.File]::Exists($s)){Copy-Item -LiteralPath $s -Destination $e -Force}};if(-not([IO.File]::Exists($p))){$s2=Join-Path $b 'Kaylers_profile.nip';if([IO.File]::Exists($s2)){Copy-Item -LiteralPath $s2 -Destination $p -Force}}}catch{}"
        REM Copie via PowerShell ci-dessus ; telechargement GitHub en secours
        if not exist "!NPI_DIR!\nvidiaProfileInspector.exe" curl.exe -fsSL --retry 2 --connect-timeout 15 "!WINOPT_RELEASE_BASE_URL!/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe" -o "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        if not exist "!NPI_DIR!\Kaylers_profile.nip" curl.exe -fsSL --retry 2 --connect-timeout 15 "!WINOPT_RELEASE_BASE_URL!/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip" -o "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1

        set "NPI_VALID=1"
        if exist "!NPI_DIR!\nvidiaProfileInspector.exe" (
            for %%A in ("!NPI_DIR!\nvidiaProfileInspector.exe") do if %%~zA LSS 10000 set "NPI_VALID=0"
        ) else (
            set "NPI_VALID=0"
        )

        if exist "!NPI_DIR!\Kaylers_profile.nip" (
            for %%A in ("!NPI_DIR!\Kaylers_profile.nip") do if %%~zA LSS 100 set "NPI_VALID=0"
        ) else (
            set "NPI_VALID=0"
        )

        REM NPI v3 a retire temporairement l'import CLI avant sa restauration en v3.0.1.10.
        REM Refuser explicitement ces versions evite un succes apparent sans profil importe.
        set "NPI_CLI_SUPPORTED=0"
        if "!NPI_VALID!"=="1" (
            powershell -NoProfile -Command "try { $v=[version](Get-Item -LiteralPath (Join-Path $env:NPI_DIR 'nvidiaProfileInspector.exe')).VersionInfo.FileVersion; if($v.Major -eq 3 -and $v -lt [version]'3.0.1.10'){exit 1}; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! EQU 0 set "NPI_CLI_SUPPORTED=1"
        )

        if "!NPI_VALID!"=="1" (
            if "!NPI_CLI_SUPPORTED!"=="1" (
                echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application du profil NVIDIA optimise...%COLOR_RESET%
                start /wait "" "!NPI_DIR!\nvidiaProfileInspector.exe" -silentImport "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
                if !errorlevel! EQU 0 (
                    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA Profile Inspector applique avec succes%COLOR_RESET%
                ) else (
                    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA non importe. Les autres reglages GPU restent appliques.%COLOR_RESET%
                )
            ) else (
                echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%NVIDIA Profile Inspector incompatible.%COLOR_RESET%
                echo %COLOR_WHITE%L'import silencieux du profil est ignore.%COLOR_RESET%
                echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Utilisez NVIDIA Profile Inspector 2.4.x, 3.0.1.10 ou plus recent.%COLOR_RESET%
            )
        ) else (
            echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA ignore : Fichiers absents ou invalides.%COLOR_RESET%
        )

        REM Nettoyage
        del /f /q "!NPI_DIR!\*.*" >nul 2>&1
        rmdir "!NPI_DIR!" >nul 2>&1
        set "NPI_EXE_SRC="
        set "NPI_PROFILE_SRC="
        set "NPI_CLI_SUPPORTED="
    ) else (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation de la restauration du profil GPU...%COLOR_RESET%
        REM Copie locale via PowerShell - env WINOPT_SOURCE_DIR, cf 7.10 - contourne expansion differee de cmd
        REM NPI_EXE_SRC et NPI_PROFILE_SRC ne sont plus definis ici : copies via PowerShell ci-dessous
        REM Le launcher distant ne telecharge que le batch : recuperer aussi les deux fichiers NPI.
        set "NPI_DIR=%SystemRoot%\Temp\NPI_restore_%RANDOM%_%RANDOM%"
        if not exist "!NPI_DIR!" mkdir "!NPI_DIR!" >nul 2>&1
        powershell -NoProfile -Command "try{$b=Join-Path $env:WINOPT_SOURCE_DIR 'Tools\NVIDIA Inspector';$d=$env:NPI_DIR;$e=Join-Path $d 'nvidiaProfileInspector.exe';$p=Join-Path $d 'Kaylers_profile.nip';if(-not([IO.File]::Exists($e))){$s=Join-Path $b 'nvidiaProfileInspector.exe';if([IO.File]::Exists($s)){Copy-Item -LiteralPath $s -Destination $e -Force}};if(-not([IO.File]::Exists($p))){$s2=Join-Path $b 'Kaylers_profile.nip';if([IO.File]::Exists($s2)){Copy-Item -LiteralPath $s2 -Destination $p -Force}}}catch{}"
        REM Copie via PowerShell ci-dessus ; telechargement GitHub en secours
        if not exist "!NPI_DIR!\nvidiaProfileInspector.exe" curl.exe -fsSL --retry 2 --connect-timeout 15 "!WINOPT_RELEASE_BASE_URL!/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe" -o "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        if not exist "!NPI_DIR!\Kaylers_profile.nip" curl.exe -fsSL --retry 2 --connect-timeout 15 "!WINOPT_RELEASE_BASE_URL!/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip" -o "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
        set "NPI_EXE_SRC=!NPI_DIR!\nvidiaProfileInspector.exe"
        set "NPI_PROFILE_SRC=!NPI_DIR!\Kaylers_profile.nip"
        set "NPI_VALID=1"
        if not exist "!NPI_EXE_SRC!" set "NPI_VALID=0"
        if not exist "!NPI_PROFILE_SRC!" set "NPI_VALID=0"
        if exist "!NPI_EXE_SRC!" for %%A in ("!NPI_EXE_SRC!") do if %%~zA LSS 10000 set "NPI_VALID=0"
        if exist "!NPI_PROFILE_SRC!" for %%A in ("!NPI_PROFILE_SRC!") do if %%~zA LSS 100 set "NPI_VALID=0"
        if "!NPI_VALID!"=="1" (
            REM Verifie dans l'assembly fourni : ResetValue appelle DRS_RestoreProfileDefaultSetting puis SaveSettings.
            REM Le NIP importe Base Profile ; les memes SettingID sont donc bien restaures au defaut du pilote.
            REM Les personnalisations NVIDIA utilisant d'autres SettingID ne sont pas touchees.
            powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $a=[Reflection.Assembly]::LoadFrom($env:NPI_EXE_SRC); $t=$a.GetType('nspector.Common.DrsServiceLocator'); $svc=$t.GetField('SettingService',[Reflection.BindingFlags]'Public,NonPublic,Static').GetValue($null); [xml]$x=Get-Content -LiteralPath $env:NPI_PROFILE_SRC -Raw; $ids=@($x.SelectNodes('/ArrayOfProfile/Profile/Settings/ProfileSetting/SettingID') | ForEach-Object {[uint32]$_.InnerText} | Sort-Object -Unique); if(-not $svc -or $ids.Count -eq 0){exit 2}; foreach($id in $ids){$removed=$false; $svc.ResetValue('Base Profile',$id,[ref]$removed)}; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! EQU 0 (
                echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages NVIDIA restaures aux valeurs du pilote%COLOR_RESET%
            ) else (
                echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Reglages NVIDIA GAMING non restaures. Les autres reglages continuent.%COLOR_RESET%
            )
        ) else (
            echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Restauration NVIDIA ignoree : outil ou profil absent/invalide.%COLOR_RESET%
        )
        del /f /q "!NPI_DIR!\*.*" >nul 2>&1
        rmdir "!NPI_DIR!" >nul 2>&1
        set "NPI_EXE_SRC="
        set "NPI_PROFILE_SRC="
        set "NPI_DIR="
        set "NPI_VALID="
    )
) else (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%NVIDIA Profile Inspector ignore. Aucun GPU NVIDIA detecte.%COLOR_RESET%
)

call :FINISH_ACTION "Reglages GPU" "traites"
exit /b 0

:OPTIMISATIONS_RESEAU
cls
call :INIT_PROFILS
set "NETWORK_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Ameliore la reactivite et la stabilite de la connexion.%COLOR_RESET%
echo %COLOR_WHITE%  Regle aussi l'energie USB selon le profil choisi.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

if "!SKIP_PAUSE!"=="0" if "!DETECTE_PORTABLE!"=="1" (
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%PC portable detecte.%COLOR_RESET%
    echo %COLOR_WHITE%Ces reglages peuvent modifier :%COLOR_RESET%
    echo %COLOR_WHITE%  %COLOR_YELLOW%Wi-Fi%COLOR_RESET% : parametres de connexion peuvent reduire la stabilite.%COLOR_RESET%
    echo %COLOR_WHITE%  %COLOR_YELLOW%Batterie%COLOR_RESET% : le mode Performance max peut augmenter la consommation.%COLOR_RESET%
    echo %COLOR_WHITE%  %COLOR_YELLOW%Debit%COLOR_RESET% : le profil Gaming privilegie le temps de reponse.%COLOR_RESET%
    echo.
)

if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% : connexion et carte reseau reglees pour la reactivite.%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% : connexion et stabilite preservees.%COLOR_RESET%
)
if "!PROFIL_POWER!"=="0" (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%Performance max%COLOR_RESET%%COLOR_WHITE% : economies de la carte reduites.%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%ECO%COLOR_RESET%%COLOR_WHITE% : economie et autonomie prioritaires.%COLOR_RESET%
)
if "!IS_GAMING_ECO!"=="1" (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Gaming et Eco combines : latence preservee.%COLOR_RESET%
    echo %COLOR_WHITE%La stabilite mobile et l'autonomie restent prioritaires.%COLOR_RESET%
    echo %COLOR_WHITE%     Les delais TCP utilises restent ceux documentes par Windows.%COLOR_RESET%
)
echo.

REM  5.1 - MMCSS reseau
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la priorite reseau pour les applications multimedia...%COLOR_RESET%
REM  SystemResponsiveness : Gaming = 10 (10% CPU aux taches faible priorite). Normal = 20 (defaut Windows).
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
)
REM Valeur stock Windows documentee : bridage MMCSS conserve.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Priorite reseau configuree selon l'usage.%COLOR_RESET%

REM  5.2 - Pile TCP/IP Win11
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la connexion pour reduire les delais...%COLOR_RESET%
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int ipv4 set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
REM minRto se configure uniquement avec 'set supplemental' ; 'set global' ne prend pas ce parametre.

REM initialRTO=3000ms et maxsynretransmissions=2 = valeurs Windows documentees pour l'etablissement TCP (SYN).
REM initialRTO accepte 300-3000ms et ne regle pas le RTO des paquets une fois la connexion etablie.
if "!PROFIL_USAGE!"=="0" (
    REM Depuis Windows 11 24H2/25H2, WSH n'est plus utilise. ForceWS reste supporte.
    netsh int tcp set heuristics forcews=enabled >nul 2>&1
    netsh int tcp set global rss=enabled initialrto=3000 nonsackrttresiliency=disabled maxsynretransmissions=2 >nul 2>&1
) else (
    REM ForceWS=default restaure le defaut systeme (active). WSH n'a plus d'effet.
    netsh int tcp set heuristics forcews=default >nul 2>&1
    netsh int tcp set global rss=enabled initialrto=1000 nonsackrttresiliency=disabled maxsynretransmissions=4 >nul 2>&1
)
if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        netsh int tcp set global rsc=disabled >nul 2>&1
    ) else (
        netsh int tcp set global rsc=enabled >nul 2>&1
    )
) else (
    netsh int tcp set global rsc=enabled >nul 2>&1
)

if "!PROFIL_USAGE!"=="0" (
    REM BBR2 applique sur les cinq templates acceptes par Windows.
    netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
    netsh int tcp set supplemental template=internetcustom congestionprovider=bbr2 >nul 2>&1
    netsh int tcp set supplemental template=datacenter congestionprovider=bbr2 >nul 2>&1
    netsh int tcp set supplemental template=datacentercustom congestionprovider=bbr2 >nul 2>&1
    netsh int tcp set supplemental template=compat congestionprovider=bbr2 >nul 2>&1
) else (
    REM Fournisseur stock mesure : cubic.
    netsh int tcp set supplemental template=internet congestionprovider=cubic >nul 2>&1
    netsh int tcp set supplemental template=internetcustom congestionprovider=cubic >nul 2>&1
    netsh int tcp set supplemental template=datacenter congestionprovider=cubic >nul 2>&1
    netsh int tcp set supplemental template=datacentercustom congestionprovider=cubic >nul 2>&1
    netsh int tcp set supplemental template=compat congestionprovider=cubic >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Connexion configuree pour reduire les delais.%COLOR_RESET%

REM  TCP Pacing + ECN : essentiels pour BBR2 (pacing = parametre principal de BBR, ECN = signaux precoces congestion)
if "!PROFIL_USAGE!"=="0" (
    netsh int tcp set global pacingprofile=always >nul 2>&1
    netsh int tcp set global ecncapability=enabled >nul 2>&1
) else (
    netsh int tcp set global pacingprofile=off >nul 2>&1
    netsh int tcp set global ecncapability=disabled >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Envoi des donnees ajuste pour limiter les ralentissements.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un reglage local reste desactive pour eviter certains bugs.%COLOR_RESET%

REM  5.3 - Parametres TCP registre
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Parametres TCP registre...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    REM LanmanServer Size=1 = defaut Win11 client Minimize Memory, pas de suppression hors section restauration.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /t REG_DWORD /d 65536 /f >nul 2>&1
    netsh int ipv4 set global loopbacklargemtu=disabled >nul 2>&1
    netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
) else (
    REM Suppression -> retour au defaut Windows - 1024. Les datagrammes UDP superieurs a 1024 octets
    REM empruntent alors le chemin lent - pended I/O. C'est le comportement normal attendu.
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /f >nul 2>&1
    netsh int ipv4 set global loopbacklargemtu=enabled >nul 2>&1
    netsh int ipv6 set global loopbacklargemtu=enabled >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SackOpts /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUDiscovery /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDataRetransmissions /t REG_DWORD /d 5 /f >nul 2>&1
) else (
    REM Ces valeurs sont absentes sur l'installation stock mesuree.
    for %%V in (Tcp1323Opts SackOpts EnablePMTUDiscovery TcpMaxDataRetransmissions) do reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "%%V" /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Registre TCP configure%COLOR_RESET%
REM  5.4 - MSI Mode cartes reseau
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage des interruptions reseau...%COLOR_RESET%
call :SET_DEVICE_MSI_PROFILE Net !PROFIL_USAGE!
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Reglage MSI reseau applique partiellement.%COLOR_RESET%
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Interruptions reseau reglees.%COLOR_RESET%


REM  5.5 - Optimisation BITS
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Optimisation du service BITS...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "EnableBypassProxyForLocal" /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "EnableBypassProxyForLocal" /f >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%BITS optimise%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Override BITS retire.%COLOR_RESET%)

REM  5.6 - Nagle/DelACK (ECO/Normal->defaut natif, Gaming+MaxPerf->agressif)
if "!PROFIL_POWER!"=="1" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la connexion pour le mode Eco...%COLOR_RESET%
    call :RESET_NAGLE_PROFILE
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Parametres de connexion rendus aux valeurs Windows pour le profil Eco.%COLOR_RESET%
) else if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la connexion pour reduire la latence...%COLOR_RESET%
    call :SET_NAGLE_PROFILE 1 1 0
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Connexion reglee pour le profil Gaming.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres de connexion aux valeurs Windows...%COLOR_RESET%
    call :RESET_NAGLE_PROFILE
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Connexion rendue aux valeurs Windows pour le profil Normal.%COLOR_RESET%
)

REM  5.7 - Optimisation cartes reseau
if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la connexion pour Gaming et Performance max...
        echo %COLOR_WHITE%Latence reduite, economie d'energie limitee.%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la connexion pour Normal et Performance max...
        echo %COLOR_WHITE%Stabilite et performances privilegiees.%COLOR_RESET%
    )
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la carte reseau pour le mode Eco...%COLOR_RESET%
)
call :SET_NIC_PROFILE !PROFIL_POWER! !PROFIL_USAGE!
if !errorlevel! NEQ 0 (
    set "NETWORK_SECTION_ERROR=1"
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Certains reglages de la carte reseau n'ont pas pu etre appliques.%COLOR_RESET%
) else if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Profil reseau Gaming + Performance max demande.%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Profil reseau Normal + Performance max demande.%COLOR_RESET%
    )
) else (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Profil NIC Eco demande%COLOR_RESET%
)
call :SET_NIC_PROFILE_CONVERGENCE !PROFIL_POWER! !PROFIL_USAGE!
if !errorlevel! NEQ 0 (
    set "NETWORK_SECTION_ERROR=1"
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%La convergence des cartes reseau reste partielle.%COLOR_RESET%
)
REM  5.8 - Gestion energie USB (impacte adaptateurs Wi-Fi USB, clavier, souris)
set "USB_POWER_DEFERRED=0"
if "!AIO_MODE!"=="1" set "USB_POWER_DEFERRED=1"
if "!USB_POWER_DEFERRED!"=="1" (
    REM En TOUT_OPTIMISER, la section 7 applique l'USB une seule fois sur le plan d'energie cible.
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Gestion USB differee a la section Energie pour eviter un double passage.%COLOR_RESET%
) else (
    if "!PROFIL_POWER!"=="1" (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Conservation de l'economie d'energie USB...%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reduction de la gestion d'energie USB pour limiter la latence...%COLOR_RESET%
    )
    call :SET_USB_POWER !PROFIL_POWER!
    if "!PROFIL_POWER!"=="1" (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Economie d'energie USB conservee. Autonomie preservee.%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie USB reduite. Latence minimale demandee.%COLOR_RESET%
    )
)
set "USB_POWER_DEFERRED="
REM  5.9 - QoS Fortnite DSCP 46 (Gaming uniquement)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Priorite reseau pour Fortnite...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_SZ /d "1" /f >nul 2>&1
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
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Priorite Fortnite appliquee pour le profil Gaming.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression de la priorite Fortnite pour le profil Normal...%COLOR_RESET%
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Priorite Fortnite supprimee%COLOR_RESET%
)

REM  5.10 - Nettoyage des protocoles reseau
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration des composants reseau...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    powershell -NoProfile -Command "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false } | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lldp','ms_implat' -ErrorAction SilentlyContinue }" >nul 2>&1
) else (
    REM Stock mesure : LLDP actif ; ms_implat reste desactive.
    powershell -NoProfile -Command "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false } | ForEach-Object { Enable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lldp' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_implat' -ErrorAction SilentlyContinue }" >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%LLDP et Microsoft Network Adapter Multiplexor desactives.%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Bindings reseau rendus au stock mesure.%COLOR_RESET%)

REM  5.11 - Desactivation NetBIOS over TCP/IP
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de NetBIOS sur TCP/IP...%COLOR_RESET%
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s ^| findstr /i /r "\\Tcpip_.*$" 2^>nul') do (
  if "!PROFIL_USAGE!"=="0" (
    reg add "%%i" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1
  ) else (
    reg add "%%i" /v NetbiosOptions /t REG_DWORD /d 0 /f >nul 2>&1
  )
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%NetBIOS desactive%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%NetBIOS rendu au stock Windows%COLOR_RESET%)

REM  5.12 - RssBaseCpu (Gaming : interrupts NIC decales du core 0)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Repartition des interruptions de la carte reseau...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v RssBaseCpu /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Interruptions reseau reglees pour le profil Gaming.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la repartition des interruptions reseau Windows...%COLOR_RESET%
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v RssBaseCpu /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Repartition des interruptions reseau rendue a Windows.%COLOR_RESET%
)

ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1
nbtstat -RR >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Caches de connexion purges.%COLOR_RESET%

call :FINISH_ACTION "Reglages reseau" "traites"
exit /b !NETWORK_SECTION_ERROR!

:OPTIMISATIONS_PERIPHERIQUES
cls
call :INIT_PROFILS
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 6 : OPTIMISATIONS CLAVIER ET SOURIS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Configure la souris, le clavier, l'affichage DPI et les interruptions USB.%COLOR_RESET%
echo %COLOR_WHITE%  Desactive aussi certains raccourcis d'accessibilite selon le profil.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

REM  Avertissement mode manuel sur PC portable : le profil Normal conserve l'acceleration souris desactivee.
if "!SKIP_PAUSE!"=="0" if "!DETECTE_PORTABLE!"=="1" (
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%PC portable detecte.%COLOR_RESET%
    echo %COLOR_WHITE%Ces reglages peuvent modifier :%COLOR_RESET%
    echo %COLOR_WHITE%  %COLOR_YELLOW%Trackpad%COLOR_RESET% : sans acceleration, le mouvement peut sembler moins naturel.%COLOR_RESET%
    echo %COLOR_WHITE%  %COLOR_YELLOW%Affichage DPI%COLOR_RESET% : le mode Gaming peut modifier l'echelle sur un ecran dense.%COLOR_RESET%
    echo.
)

if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% : souris 1:1 sans acceleration.%COLOR_RESET%
) else (
    if "!DETECTE_PORTABLE!"=="1" (
        echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% : souris 1:1 sans acceleration.%COLOR_RESET%
    ) else (
        echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% : souris 1:1 sans acceleration.%COLOR_RESET%
    )
)
echo.

REM  6.1 - Souris optimisee
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation de la reactivite souris...%COLOR_RESET%
set "KEEP_MOUSE_ACCEL=0"
if "!KEEP_MOUSE_ACCEL!"=="1" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage du trackpad avec une acceleration legere...%COLOR_RESET%
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "4" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "12" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Acceleration legere conservee. Trackpad regle.%COLOR_RESET%
) else (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'acceleration de la souris...%COLOR_RESET%
        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Acceleration souris desactivee - Mouvement 1:1 actif%COLOR_RESET%
    ) else (
        REM Acceleration souris conservee desactivee : choix de l'utilisateur - accel OFF sur sa machine.
        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Acceleration souris conservee desactivee - choix utilisateur%COLOR_RESET%
    )
)
if "!PROFIL_USAGE!"=="0" reg add "HKCU\Control Panel\Mouse" /v "MouseDelay" /t REG_SZ /d "0" /f >nul 2>&1
if "!PROFIL_USAGE!"=="1" reg delete "HKCU\Control Panel\Mouse" /v "MouseDelay" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "SnapToDefaultButton" /t REG_SZ /d "0" /f >nul 2>&1
set "KEEP_MOUSE_ACCEL="
REM Nettoyage des anciens emplacements utilises par les profils d'entree precedents.
for %%V in (MouseDataQueueSize ThreadPriority) do reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "%%V" /f >nul 2>&1
for %%V in (KeyboardDataQueueSize ThreadPriority) do reg delete "HKLM\SYSTEM\CurrentControlSet\Services\kbdhid\Parameters" /v "%%V" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "ThreadPriority" /f >nul 2>&1
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 20 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseTransmitTimeout" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d 20 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "ThreadPriority" /t REG_DWORD /d 31 /f >nul 2>&1
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des reglages souris et clavier du profil Normal...%COLOR_RESET%
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseTransmitTimeout" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "ThreadPriority" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages souris et clavier demandes aux valeurs Windows.%COLOR_RESET%
)
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsolutePointerAsAbsolute" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsoluteAsRelative" /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    REM Stock mesure : TreatAbsolutePointerAsAbsolute=0 et TreatAbsoluteAsRelative=0.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsolutePointerAsAbsolute" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsoluteAsRelative" /t REG_DWORD /d 0 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Parametres souris et HID optimises%COLOR_RESET%

REM  6.2 - Clavier optimise
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Optimisation de la reactivite clavier...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%File clavier reglee sur 20 pour le profil Gaming.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%File clavier non modifiee pour le profil Normal.%COLOR_RESET%
)

REM  6.3 - Win8 Scaling (Profil GAMING uniquement)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la mise a l'echelle DPI Windows pour le profil Gaming...%COLOR_RESET%
    reg add "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mise a l'echelle DPI reglee pour un affichage 1:1.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la mise a l'echelle DPI Windows...%COLOR_RESET%
    reg delete "HKCU\Control Panel\Desktop" /v Win8DpiScaling /f >nul 2>&1
    reg delete "HKCU\Control Panel\Desktop" /v LogPixels /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mise a l'echelle DPI demandee aux valeurs Windows.%COLOR_RESET%
)

REM  6.4 - MSI Mode Universel (Latence Peripheriques)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage des interruptions USB...%COLOR_RESET%
call :SET_DEVICE_MSI_PROFILE USB !PROFIL_USAGE!
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Reglage MSI USB applique partiellement.%COLOR_RESET%
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Interruptions USB reglees.%COLOR_RESET%



REM  6.5 - Raccourcis d'accessibilite selon le profil
if "!PROFIL_USAGE!"=="0" (echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des raccourcis d'accessibilite...%COLOR_RESET%) else (echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des raccourcis d'accessibilite...%COLOR_RESET%)
if "!PROFIL_USAGE!"=="0" (
    reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
) else (
    REM Stock mesure : StickyKeys Flags=510, ToggleKeys Flags=62 et FilterKeys absent.
    reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "510" /f >nul 2>&1
    reg delete "HKCU\Control Panel\Accessibility\StickyKeys" /v "HotkeyActive" /f >nul 2>&1
    reg delete "HKCU\Control Panel\Accessibility\FilterKeys" /v "Flags" /f >nul 2>&1
    reg delete "HKCU\Control Panel\Accessibility\FilterKeys" /v "HotkeyActive" /f >nul 2>&1
    reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "62" /f >nul 2>&1
    reg delete "HKCU\Control Panel\Accessibility\ToggleKeys" /v "HotkeyActive" /f >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Raccourcis d'accessibilite desactives%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Raccourcis d'accessibilite rendus au stock Windows%COLOR_RESET%)

REM  6.6 - HID parse optimise
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableInputDelayOptimization" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableBufferedInput" /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    REM Ces overrides sont absents dans le stock Windows mesure.
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableInputDelayOptimization" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableBufferedInput" /f >nul 2>&1
)
if "!PROFIL_USAGE!"=="0" (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Traitement des entrees HID et delai d'entree optimises.%COLOR_RESET%) else (echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Overrides HID retires ; traitement rendu a Windows.%COLOR_RESET%)

call :FINISH_ACTION "Reglages peripheriques" "traites"
exit /b 0

:TOGGLE_ECONOMIES_ENERGIE
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GERER LE MODE ENERGIE"
echo %COLOR_WHITE%  Choisissez entre performances et economies d'energie.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%ECO%COLOR_RESET%
echo %COLOR_WHITE%    Economies d'energie actives et autonomie preservee.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%PERFORMANCE MAX%COLOR_RESET%
echo %COLOR_WHITE%    Plus de performances, mais plus de chauffe et de consommation.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Performance max demandera ensuite l'usage Gaming ou Normal%COLOR_RESET%
echo %COLOR_WHITE%pour adapter aussi la carte reseau.%COLOR_RESET%
call :SUBMENU_CHOICE "principal" "Choisissez une option [1, 2, M] : " 12M
if !errorlevel! EQU 3 goto :MENU_PRINCIPAL
if !errorlevel! EQU 2 goto :DO_DESACTIVER_ECONOMIES
if !errorlevel! EQU 1 goto :DO_RESTAURER_ECONOMIES
goto :TOGGLE_ECONOMIES_ENERGIE

:DO_RESTAURER_ECONOMIES
call :RESTAURER_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DO_DESACTIVER_ECONOMIES
set "PROFIL_POWER=0"
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - ENERGIE" "USAGE"
if !errorlevel! NEQ 0 goto :TOGGLE_ECONOMIES_ENERGIE
call :DESACTIVER_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DESACTIVER_ECONOMIES_ENERGIE
set "PROFIL_POWER=0"
call :INIT_PROFILS
call :SCREEN_HEADER " APPLICATION DU MODE PERFORMANCE MAX"
echo %COLOR_WHITE%  Performance max garde le processeur et le GPU disponibles.%COLOR_RESET%
echo %COLOR_WHITE%  Le stockage, l'USB, le PCIe et le reseau restent plus reactifs.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Consommation, temperature et bruit peuvent augmenter.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le mode Eco limite la consommation et l'action reste reversible.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

REM  7.1 - Activation du plan Ultimate Performance
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation du plan Ultimate Performance...%COLOR_RESET%
set "POWER_PLAN_ALREADY_ACTIVE=0"
if "!AIO_MODE!"=="1" if "!AIO_POWER_PRESELECTED!"=="1" set "POWER_PLAN_ALREADY_ACTIVE=1"
if "!POWER_PLAN_ALREADY_ACTIVE!"=="1" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Plan Ultimate Performance deja actif pour Tout optimiser%COLOR_RESET%
) else (
    call :SELECT_TARGET_POWER_SCHEME 0
    if !errorlevel! NEQ 0 (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de creer ou d'activer le plan Ultimate Performance.%COLOR_RESET%
        set "POWER_PLAN_ALREADY_ACTIVE="
        exit /b 1
    )
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Plan Ultimate Performance active et verifie.%COLOR_RESET%
)
set "POWER_PLAN_ALREADY_ACTIVE="

REM  7.2 - GPU Power Management (ULPS & PowerMizer)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la gestion d'energie du GPU AMD et NVIDIA...%COLOR_RESET%
REM  ULPS OFF - AMD et PowerMizer NVIDIA, en un seul parcours des instances GPU.
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v EnableUlps_NA /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v PowerMizerEnable /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PerfLevelSrc /t REG_DWORD /d 0x2222 /f >nul 2>&1
  reg add "%%K" /v DisableDynamicPstate /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v RmDisableRegistryCaching /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie du GPU reglee pour les performances.%COLOR_RESET%

REM  7.3 - Parametres avances du plan d'alimentation (user standard)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration avancee du plan d'alimentation...%COLOR_RESET%

call :SET_POWERCFG_ACDC 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
call :SET_POWERCFG_ACDC 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1
call :SET_POWERCFG_ACDC 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0

REM  Veille hybride : desactivee (inutile si hibernate est off)
call :SET_POWERCFG_ACDC 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
call :SET_POWERCFG_ACDC 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0
call :SET_POWERCFG_ACDC 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0

call :SET_POWERCFG_ACDC 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
call :SET_POWERCFG_ACDC 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1
call :SET_POWERCFG_ACDC 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600

call :SET_POWERCFG_ACDC 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1
call :SET_POWERCFG_ACDC 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0
call :SET_POWERCFG_ACDC 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2
call :SET_POWERCFG_ACDC c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3
call :SET_POWERCFG_ACDC f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1
call :SET_POWERCFG_ACDC e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3

echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Parametres avances du plan d'alimentation appliques%COLOR_RESET%

REM  7.4 - Optimisations CPU (Intel Hybrid + AMD Core Parking)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Le processeur reste pret a repondre rapidement...%COLOR_RESET%

REM  Intel Hybrid CPUs (Alder Lake/Raptor Lake/Meteor Lake)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Les coeurs du processeur restent disponibles.%COLOR_RESET%
REM  E-cores (0cc5b647...-583) : 100 = aucun E-core parque
call :SET_POWERCFG_ACDC 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100
call :SET_POWERCFG_ACDC 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Coeurs de processeur maintenus disponibles.%COLOR_RESET%

REM  Desactivation Core Parking (Intel + AMD)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Le processeur evite la mise en veille automatique des coeurs.%COLOR_RESET%
REM  P-cores (0cc5b647...-584) : 100 = aucun P-core parque. Meme GUID pour Intel Hybrid et AMD Ryzen
REM  (le parking core utilise le meme sous-groupe SUB_PROCESSOR 0cc5b647 sur les deux architectures)
REM  GUID SUB_PROCESSOR en dur (alias SUB_PROCESSOR non fiable selon la locale Windows)
call :SET_POWERCFG_ACDC 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage des coeurs demande.%COLOR_RESET%

REM  7.5 - Desactivation economies d'energie USB et peripheriques HID/USB
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reduction de la mise en veille des peripheriques...%COLOR_RESET%
REM Le second parametre differe l'activation du plan : elle est groupee en fin de section 7.
call :SET_USB_POWER 0 1
REM Les valeurs Device Parameters/WDF appartiennent aux pilotes et varient selon chaque peripherique.
REM La commande WMI ci-dessus suffit pour le profil ; aucun forcage registre destructif n'est applique.
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mise en veille des peripheriques HID et USB reduite.%COLOR_RESET%

REM  7.6 - Desactivation du demarrage rapide Fast Startup
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation du demarrage rapide Windows...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide desactive. Les redemarrages complets sont privilegies.%COLOR_RESET%

REM  7.7 - Hibernation
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'hibernation...%COLOR_RESET%
powercfg /hibernate off >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Hibernation desactivee. Espace disque recupere.%COLOR_RESET%

REM  7.8 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration du systeme d'alimentation...%COLOR_RESET%
REM  ASPM est configure correctement a la section 7.18 ci-dessous avec SUB_PCIEXPRESS (501a4d13...)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1

REM  7.9 - Desactivation des Timer Coalescing et DPC
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Les interruptions du processeur sont reduites.%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MinimumDpcRate /t REG_DWORD /d 1 /f >nul 2>&1
REM  DisableTsx - Intel Transactional Synchronization Extensions (Intel uniquement, pas AMD)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
REM  ============================================================================
REM  BLOC AVANCE TIMERCOALESCING - ENTIEREMENT DESACTIVE PAR DEFAUT
REM  Option 1 - 80 octets : NE PAS ACTIVER. Cette valeur peut faire planter Windows au demarrage.
REM  Cause probable : elle force le reglage des timers pendant le chargement de win32k.
REM  Un verrou interne peut ne pas etre encore initialise, causant le crash 0x1E puis Recovery 0xC0000001.
REM  Il s'agit d'un bug interne de Windows, pas d'une erreur de syntaxe ou de longueur de la valeur.
REM  Toute valeur valide de 80 octets utilise ce meme chemin : aucun contournement fiable par registre.
REM  reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
REM  Option 2 - recommandee : supprimer la valeur pour laisser Windows gerer ce parametre normalement.
REM  reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
REM  ============================================================================
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\ModernSleep" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\ControlSet001\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
REM Preset timer MaxPerf experimental : polling rate MouseTester observe plus regulier sur la config testee, resultat materiel-dependent.
REM Les trois suppressions BCD sont communes a tous les profils ; MaxPerf ajoute uniquement ce reglage.
call :RESET_BCD_TIMER_OVERRIDES
bcdedit /set disabledynamictick yes >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Preset timer Performance max demande.%COLOR_RESET%
echo %COLOR_WHITE%Dynamic Tick coupe ; les autres choix de timer restent geres par Windows et HPET est conserve actif.%COLOR_RESET%

REM  7.10 - Installation SetTimerResolution
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration de SetTimerResolution...%COLOR_RESET%
set "STR_DIR=%ProgramFiles%\SetTimerResolution"
set "STR_OLD_DIR=%ProgramFiles%\OptimizerAllInOne"
set "STR_EXE=%STR_DIR%\SetTimerResolution.exe"
set "STR_STARTUP_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
set "STR_TIMER_ERROR=0"
REM  Le dossier de destination doit exister AVANT toute copie/telechargement (sinon echec)
if not exist "%STR_DIR%" mkdir "%STR_DIR%" >nul 2>&1
if not exist "%STR_EXE%" if exist "%STR_OLD_DIR%\SetTimerResolution.exe" move /Y "%STR_OLD_DIR%\SetTimerResolution.exe" "%STR_EXE%" >nul 2>&1
if exist "%STR_OLD_DIR%" rmdir "%STR_OLD_DIR%" >nul 2>&1
if exist "%STR_EXE%" for %%A in ("%STR_EXE%") do if %%~zA LSS 10000 del /f /q "%STR_EXE%" >nul 2>&1
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution deja installe dans %STR_DIR%%COLOR_RESET%
) else (
    call :INSTALL_STR_BINARY
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution installe dans %STR_DIR%%COLOR_RESET%
    ) else (
        set "STR_TIMER_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution non installe ; le timer automatique est indisponible.%COLOR_RESET%
    )
)
if exist "%STR_EXE%" (
    taskkill /F /IM SetTimerResolution.exe >nul 2>&1
    call :REMOVE_STR_AUTOSTART_TASK
    call :CREATE_STR_STARTUP_SHORTCUT
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Raccourci SetTimerResolution configure au demarrage.%COLOR_RESET%
    ) else (
        set "STR_TIMER_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Raccourci de demarrage non cree.%COLOR_RESET%
    )
    start "" /D "%STR_DIR%" "%STR_EXE%" --resolution 5070 --no-console >nul 2>&1
    set "STR_START_RC=!errorlevel!"
    if "!STR_START_RC!"=="0" (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Lancement de SetTimerResolution demande avec une resolution de 5070.%COLOR_RESET%
        timeout /t 1 /nobreak >nul
        powershell -NoProfile -Command "if (@(Get-Process -Name SetTimerResolution -ErrorAction SilentlyContinue).Count -gt 0) { exit 0 } else { exit 1 }" >nul 2>&1
        if !errorlevel! NEQ 0 (
            set "STR_TIMER_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution ne tourne pas apres le lancement.%COLOR_RESET%
        )
    ) else (
        set "STR_TIMER_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution n'a pas pu etre lance.%COLOR_RESET%
    )
    set "STR_START_RC="
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Cette resolution peut augmenter les reveils du processeur.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le mode Eco permet de la desactiver.%COLOR_RESET%
)

REM  7.11 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Le processeur ne sera plus limite automatiquement.%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage de la limitation automatique demande.%COLOR_RESET%

REM  7.12 - Desactivation ASPM
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Le lien PCI Express evite les economies d'energie.%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage PCI Express demande ; latence potentiellement reduite.%COLOR_RESET%

REM  7.13 - Optimisations stockage et disques
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage de la gestion d'energie du stockage...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\'+$c) -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; New-ItemProperty -Path $p -Name 'EnableHIPM' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'EnableDIPM' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'EnableHDDParking' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie du stockage reglee pour les performances.%COLOR_RESET%

REM  7.14 - Optimisations avancees des services
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression des limites de latence du stockage...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\'+$c) -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; New-ItemProperty -Path $p -Name 'IoLatencyCap' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Limites de latence stockage supprimees%COLOR_RESET%

REM  7.15 - GPU PreferMaxPerf
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Configuration GPU en mode performances maximales...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%GPU configure en mode performances maximales%COLOR_RESET%

REM  7.16 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de la mise en veille des peripheriques PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
REM  7.17 - Energie PCIe
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation gestion d'energie PCIe...%COLOR_RESET%
call :SET_POWERCFG_ACDC 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie PCIe desactivee%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "DisableASPM" /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v "RMForcedMaxPerf" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%GPU optimise%COLOR_RESET%

REM  7.18 - Convergence reseau du profil Energie (parcours manuel uniquement)
REM  TOUT_OPTIMISER a deja applique la meme matrice dans la section Reseau.
set "NIC_PROFILE_ERROR=0"
if not "!AIO_MODE!"=="1" (
    echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Synchronisation du profil reseau avec Performance max...%COLOR_RESET%
    if "!PROFIL_USAGE!"=="0" (
        netsh int tcp set global rsc=disabled >nul 2>&1
        call :SET_NAGLE_PROFILE 1 1 0
    ) else (
        netsh int tcp set global rsc=enabled >nul 2>&1
        call :RESET_NAGLE_PROFILE
    )
    call :SET_NIC_PROFILE 0 !PROFIL_USAGE!
    if !errorlevel! NEQ 0 (
        set "NIC_PROFILE_ERROR=1"
        echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Synchronisation reseau appliquee partiellement.%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Synchronisation avec Performance max demandee.%COLOR_RESET%
    )
    call :SET_NIC_PROFILE_CONVERGENCE 0 !PROFIL_USAGE!
    if !errorlevel! NEQ 0 (
        set "NIC_PROFILE_ERROR=1"
        echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%La convergence des cartes reseau reste partielle.%COLOR_RESET%
    )
)

REM  Appliquer l'ensemble des modifications du plan d'alimentation en une seule fois
powercfg /S SCHEME_CURRENT >nul 2>&1

set "STR_EXE="
set "STR_OLD_DIR="
set "STR_STARTUP_LNK="
set "ENERGY_SECTION_RC=0"
if "!STR_TIMER_ERROR!"=="1" set "ENERGY_SECTION_RC=1"
set "STR_TIMER_ERROR="
if "!NIC_PROFILE_ERROR!"=="1" set "ENERGY_SECTION_RC=1"
set "NIC_PROFILE_ERROR="
if not "!AIO_MODE!"=="1" (
    call :SET_MEMORY_POWER_PROFILE
    if !errorlevel! NEQ 0 set "ENERGY_SECTION_RC=1"
)
call :FINISH_ACTION "Reglages d'energie Performance max" "traites"
exit /b !ENERGY_SECTION_RC!

:RESTAURER_ECONOMIES_ENERGIE
set "PROFIL_POWER=1"
call :INIT_PROFILS
call :SCREEN_HEADER " APPLICATION DU MODE ECO"
echo %COLOR_WHITE%  Applique le plan Equilibre et les economies d'energie Windows.%COLOR_RESET%
echo %COLOR_WHITE%  Les surcharges du mode Performance max sont supprimees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

REM  Numerotation 7.x locale a cette branche : le mode Performance max possede sa propre sequence.
REM  7.0 - Activer Equilibre sans effacer les plans OEM/personnalises.
REM  PowerRestoreDefaultPowerSchemes est volontairement exclu : l'API supprime TOUS les plans courants.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les plans personnalises sont conserves.%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation du plan Equilibre Windows...%COLOR_RESET%
set "POWER_PLAN_ALREADY_ACTIVE=0"
if "!AIO_MODE!"=="1" if "!AIO_POWER_PRESELECTED!"=="1" set "POWER_PLAN_ALREADY_ACTIVE=1"
if "!POWER_PLAN_ALREADY_ACTIVE!"=="1" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Plan Equilibre deja actif pour Tout optimiser.%COLOR_RESET%
) else (
    call :SELECT_TARGET_POWER_SCHEME 1
    if !errorlevel! NEQ 0 (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible d'activer le plan Equilibre.%COLOR_RESET%
        set "POWER_PLAN_ALREADY_ACTIVE="
        exit /b 1
    )
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Plan Equilibre active et verifie.%COLOR_RESET%
)
set "POWER_PLAN_ALREADY_ACTIVE="
REM Le plan Ultimate duplique est conserve : il peut etre reutilise sans proliferer les GUID.

REM  7.1 - Demarrage rapide (Fast Startup)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration du demarrage rapide au stock Windows...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide reactive comme au defaut Windows.%COLOR_RESET%

REM  7.2 - Hibernation
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Retour de l'hibernation au stock Windows...%COLOR_RESET%
powercfg /hibernate on >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Hibernation et veille hybride rendues disponibles comme sur le stock mesure.%COLOR_RESET%

REM  7.3 - USB Selective Suspend
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reactivation de la mise en veille selective USB...%COLOR_RESET%
call :SET_USB_POWER 1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie USB demandee%COLOR_RESET%

REM  7.4 - Timer Coalescing
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression des surcharges Timer Coalescing...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MinimumDpcRate /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\ModernSleep" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\ControlSet001\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 1 /f >nul 2>&1
REM  Supprime les surcharges BCD communes ; Eco retire aussi le choix Dynamic Tick de MaxPerf.
call :RESET_BCD_TIMER_OVERRIDES
bcdedit /deletevalue disabledynamictick >nul 2>&1
REM  Reactive HPET s'il avait ete desactive par une ancienne version du script.
powershell -NoProfile -Command "Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'ACPI\PNP0103\*' -and $_.Problem -eq 22 } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing, BCD des timers et HPET rendus a Windows.%COLOR_RESET%

REM  7.5 - SetTimerResolution de la connexion
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression de SetTimerResolution de la connexion...%COLOR_RESET%
call :REMOVE_STR_AUTOSTART_TASK
taskkill /f /im SetTimerResolution.exe >nul 2>&1
if exist "%ProgramFiles%\SetTimerResolution\SetTimerResolution.exe" del /f /q "%ProgramFiles%\SetTimerResolution\SetTimerResolution.exe" >nul 2>&1
if exist "%ProgramFiles%\OptimizerAllInOne\SetTimerResolution.exe" del /f /q "%ProgramFiles%\OptimizerAllInOne\SetTimerResolution.exe" >nul 2>&1
if exist "%ProgramFiles%\SetTimerResolution" rmdir "%ProgramFiles%\SetTimerResolution" >nul 2>&1
if exist "%ProgramFiles%\OptimizerAllInOne" rmdir "%ProgramFiles%\OptimizerAllInOne" >nul 2>&1
set "STR_STARTUP_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
if exist "%STR_STARTUP_LNK%" del /f /q "%STR_STARTUP_LNK%" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Autolancement SetTimerResolution supprime.%COLOR_RESET%

REM  7.6 - Restaurer Intel Thread Director (visibilite panneau)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Windows peut a nouveau regler la repartition des taches.%COLOR_RESET%
REM Stock Windows 25H2 mesure : Attributes=1 pour Thread Director.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
REM bae08b81-2d5e-4688-ad6a-13243356654b : GUID non documente MS Learn 2026 - aucun override present.
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglage de la repartition des taches demande.%COLOR_RESET%

REM  7.7 - Restaurer Core Parking (powercfg + visibilite panneau)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Les coeurs peuvent de nouveau se mettre en veille.%COLOR_RESET%
REM Stock Windows 25H2 mesure : Attributes=1 pour le parking des P-cores.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mise en veille des coeurs rendue au plan Equilibre.%COLOR_RESET%

REM  7.8 - Power Throttling
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Windows peut de nouveau limiter le processeur si necessaire.%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Limitation automatique rendue a Windows.%COLOR_RESET%

REM  7.9 - Seuils d'economie d'energie (20 %% dans le plan Equilibre, pas de restauration necessaire)

REM  7.10 - ULPS (AMD) et PowerMizer (Auto)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie des GPU AMD et NVIDIA...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v EnableUlps /f >nul 2>&1
  reg delete "%%K" /v EnableUlps_NA /f >nul 2>&1
  reg delete "%%K" /v PowerMizerEnable /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevel /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevelAC /f >nul 2>&1
  reg delete "%%K" /v PerfLevelSrc /f >nul 2>&1
  reg delete "%%K" /v DisableDynamicPstate /f >nul 2>&1
  reg delete "%%K" /v RmDisableRegistryCaching /f >nul 2>&1
  reg delete "%%K" /v DisableASPM /f >nul 2>&1
  reg delete "%%K" /v RMForcedMaxPerf /f >nul 2>&1
)

REM  7.11 - Economies d'energie reseau (NIC)
REM Les bindings appartiennent a la section Reseau et ne sont pas modifies ici.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des economies d'energie de la carte reseau...%COLOR_RESET%
set "NIC_ECO_PROFILE_ERROR=0"
if not "!AIO_MODE!"=="1" (
    netsh int tcp set global rsc=enabled >nul 2>&1
    call :RESET_NAGLE_PROFILE
    call :SET_NIC_PROFILE 1 1
    if !errorlevel! NEQ 0 set "NIC_ECO_PROFILE_ERROR=1"
    call :SET_NIC_PROFILE_CONVERGENCE 1 1
    if !errorlevel! NEQ 0 set "NIC_ECO_PROFILE_ERROR=1"
)
if "!NIC_ECO_PROFILE_ERROR!"=="1" (
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Restauration reseau appliquee partiellement.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages d'economie de la carte reseau demandes%COLOR_RESET%
)

REM  7.12 - Visibilite des parametres processeur dans le panneau
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite des parametres processeur...%COLOR_RESET%
REM Stock Windows 25H2 mesure : Attributes=1 pour les E-cores.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Visibilite des parametres restauree%COLOR_RESET%

REM  7.13 - ASPM (PCI Express)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie PCI Express...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion PCI Express rendue a Windows et au pilote.%COLOR_RESET%

REM  7.14 - Mise en veille des disques et stockage
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres de stockage...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f >nul 2>&1
REM  Supprimer HIPM/DIPM/HDDParking pour revenir aux valeurs par defaut systeme
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\'+$c) -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnableHIPM','EnableDIPM','EnableHDDParking' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Parametres de stockage restaures%COLOR_RESET%

REM  7.15 - Limites de latence I/O
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration des limites de latence I/O...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\'+$c) -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IoLatencyCap' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Limites de latence I/O restaurees%COLOR_RESET%

REM  7.16 - Gestion d'energie GPU
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie GPU...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v PreferMaxPerf /f >nul 2>&1
)
REM Les preferences DirectX appartiennent au profil GPU choisi en section 4.
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie GPU restauree%COLOR_RESET%
REM  7.17 - Gestion d'energie PCI
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression des surcharges d'energie PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v D3ColdSupported /f >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie PCI rendue aux pilotes.%COLOR_RESET%

REM  7.18 - Systeme d'alimentation
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration du systeme d'alimentation...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Systeme d'alimentation restaure%COLOR_RESET%

REM  7.19 - Peripheriques ACPI/HID/PCI/USB
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de l'economie des peripheriques...%COLOR_RESET%
REM Les valeurs Device Parameters/WDF restent gerees par les pilotes : ne pas supprimer
REM EnhancedPowerManagementEnabled, SelectiveSuspendEnabled ou IdleInWorkingState en bloc.
REM SET_USB_POWER 1 et le plan Equilibre restaurent l'etat fonctionnel sans detruire ces valeurs.
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Parametres d'economie des peripheriques restaures%COLOR_RESET%

REM  7.20 - Gestion d'energie PCIe (visibilite panneau)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite PCIe...%COLOR_RESET%
REM Stock Windows 25H2 mesure : Attributes=2 pour la visibilite PCIe.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Visibilite PCIe restauree%COLOR_RESET%

REM  7.21 - Energie PCIe GPU (ASPM restaure en 7.13, valeurs powercfg via 7.0)

REM  7.22 - Les surcharges de l'optimiseur ont ete annulees sans toucher aux autres plans.

set "STR_STARTUP_LNK="
set "ENERGY_SECTION_RC=0"
if "!NIC_ECO_PROFILE_ERROR!"=="1" set "ENERGY_SECTION_RC=1"
set "NIC_ECO_PROFILE_ERROR="
if not "!AIO_MODE!"=="1" (
    call :SET_MEMORY_POWER_PROFILE
    if !errorlevel! NEQ 0 set "ENERGY_SECTION_RC=1"
)
call :FINISH_ACTION "Reglages d'energie Eco" "traites"
exit /b !ENERGY_SECTION_RC!

:APPLIQUER_PROFIL_SECURITE
call :INIT_PROFILS
set "SECURITY_TARGET_NAME=DEFAUT WINDOWS"
if "!PROFIL_USAGE!"=="0" set "SECURITY_TARGET_NAME=GAMING"
if "!SECURITY_FORCE_PERF_MAX!"=="1" set "SECURITY_TARGET_NAME=PERFORMANCE MAX"
if not "!SKIP_PAUSE!"=="0" goto :APPLIQUER_PROFIL_SECURITE_RUN
call :SCREEN_HEADER " SECTION 8 : APPLICATION DU MODE DE SECURITE"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Gaming et Performance max reduisent des protections.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Defaut Windows restaure le snapshot ou applique la base stock mesuree.%COLOR_RESET%
echo %COLOR_WHITE%Il ne remet pas tout le PC dans son etat d'usine.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%VBS fournit l'isolation ; HVCI correspond a l'integrite de la memoire.%COLOR_RESET%
echo %COLOR_WHITE%Mode determine par votre parcours : !SECURITY_TARGET_NAME!%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Appliquer !SECURITY_TARGET_NAME! ? [O=Appliquer / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:APPLIQUER_PROFIL_SECURITE_RUN
REM  Force PerfMax (drapeau interne) > PERF_MAX : VBS/HVCI/RequirePlatform=0.
REM  Gaming (usage=0) > GAMING : VBS/HVCI actifs, RequirePlatform=0.
REM  Normal (usage=1) > DEFAUT : snapshot restaure ou base stock mesuree, quel que soit le profil d'energie.
if "!SECURITY_FORCE_PERF_MAX!"=="1" (
    call :APPLIQUER_SECURITE_PERF_MAX
    exit /b !errorlevel!
)
if "!PROFIL_USAGE!"=="0" (
    call :APPLIQUER_SECURITE_GAMING
    exit /b !errorlevel!
)
call :RESTAURER_PROTECTIONS_SECURITE
exit /b !errorlevel!

:APPLIQUER_SECURITE_GAMING
call :SCREEN_HEADER " APPLICATION DU MODE DE SECURITE GAMING"
call :CAPTURE_SECURITY_BASELINE
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%La base de securite ne peut pas etre sauvegardee ; aucune modification appliquee.%COLOR_RESET%
    exit /b 1
)

REM Etat cible Gaming : aucun reglage gere par l'option 8 d'un autre profil ne doit subsister.
for %%V in (MoveImages EnableGdsMitigation PerformMmioMitigation RestrictIndirectBranchPrediction EnableKvashadow KvaOpt DisableStibp EnableRetpoline DisableBranchPrediction) do reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "%%V" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reglage des protections du processeur...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 33554435 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Protections CPU reglees pour la performance.%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application de VBS/HVCI et des protections Gaming...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v WasEnabledBy /t REG_DWORD /d 2 /f >nul 2>&1
for %%V in (EnableVirtualizationBasedSecurity RequirePlatformSecurityFeatures HypervisorEnforcedCodeIntegrity) do reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "%%V" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
REM LSA-PPL reste actif sans verrou UEFI : RunAsPPL=1. La valeur 2 pose un verrou
REM UEFI quasi irreversible (suppression via outil Microsoft en environnement de recuperation).
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v RunAsPPL /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPLBoot /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /f >nul 2>&1
REM Supprime la surcharge BCD ; Windows reprend son comportement par defaut.
bcdedit /deletevalue hypervisorlaunchtype >nul 2>&1
REM HVCI peut maintenir la blocklist active malgre cette demande locale.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul 2>&1
REM CFG revient a NOTSET et SEHOP passe a OFF sans modifier les autres mitigations systeme.
call :SET_CFG_NOTSET_SEHOP_OFF
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mode de securite Gaming demande.%COLOR_RESET%
exit /b 0

:APPLIQUER_SECURITE_PERF_MAX
call :SCREEN_HEADER " APPLICATION DU MODE DE SECURITE PERFORMANCE MAX"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Protections memoire et processeur reduites.%COLOR_RESET%
call :CAPTURE_SECURITY_BASELINE
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%La base de securite ne peut pas etre sauvegardee ; aucune modification appliquee.%COLOR_RESET%
    exit /b 1
)

REM Etat cible Performance Max : aucun reglage gere par l'option 8 d'un autre profil ne doit subsister.
for %%V in (MoveImages EnableGdsMitigation PerformMmioMitigation RestrictIndirectBranchPrediction EnableKvashadow KvaOpt DisableStibp EnableRetpoline DisableBranchPrediction) do reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "%%V" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 33554435 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v WasEnabledBy /t REG_DWORD /d 2 /f >nul 2>&1
for %%V in (EnableVirtualizationBasedSecurity HypervisorEnforcedCodeIntegrity) do reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "%%V" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
REM LSA-PPL reste actif sans verrou UEFI : RunAsPPL=1. La valeur 2 pose un verrou
REM UEFI quasi irreversible (suppression via outil Microsoft en environnement de recuperation).
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v RunAsPPL /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPLBoot /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /f >nul 2>&1
REM Supprime la surcharge BCD ; Windows reprend son comportement par defaut.
bcdedit /deletevalue hypervisorlaunchtype >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul 2>&1
REM CFG revient a NOTSET et SEHOP passe a OFF sans modifier les autres mitigations systeme.
call :SET_CFG_NOTSET_SEHOP_OFF
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Mode de securite Performance max demande.%COLOR_RESET%
exit /b 0

:RESTAURER_PROTECTIONS_SECURITE
call :SCREEN_HEADER " APPLICATION DU MODE DEFAUT WINDOWS"
REM Microsoft ne definit pas une valeur brute universelle pour le "defaut".
REM Restaurer la base capturee si elle existe ; sans snapshot, appliquer uniquement
REM les valeurs et absences mesurees sur l'installation Windows 11 25H2 de reference.
call :RESTORE_SECURITY_BASELINE
set "SECURITY_RESTORE_RC=!errorlevel!"
if "!SECURITY_RESTORE_RC!"=="0" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Etat de securite precedent restaure sans ecraser les autres reglages.%COLOR_RESET%
    set "SECURITY_RESTORE_RC="
    exit /b 0
)
if "!SECURITY_RESTORE_RC!"=="1" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%La restauration de la base de securite a echoue ; les overrides restent inchanges.%COLOR_RESET%
    set "SECURITY_RESTORE_RC="
    exit /b 1
)

REM Aucun snapshot disponible : appliquer la base stock mesuree sur Windows 11 25H2.
for %%V in (MoveImages EnableGdsMitigation PerformMmioMitigation RestrictIndirectBranchPrediction EnableKvashadow KvaOpt DisableStibp EnableRetpoline DisableBranchPrediction FeatureSettingsOverride FeatureSettingsOverrideMask) do reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "%%V" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 0 /f >nul 2>&1
for %%V in (KernelSEHOPEnabled DisableExceptionChainValidation MitigationOptions MitigationAuditOptions) do reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "%%V" /f >nul 2>&1
for %%V in (EnableVirtualizationBasedSecurity RequirePlatformSecurityFeatures Locked) do reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "%%V" /f >nul 2>&1
for %%V in (Enabled Locked WasEnabledBy) do reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "%%V" /f >nul 2>&1
for %%V in (EnableVirtualizationBasedSecurity RequirePlatformSecurityFeatures HypervisorEnforcedCodeIntegrity LsaCfgFlags) do reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "%%V" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v RunAsPPL /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /f >nul 2>&1
REM Base stock : PPL actif sans verrou UEFI (RunAsPPL=1) ; RunAsPPLBoot reste supprime.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPLBoot /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 1 /f >nul 2>&1
bcdedit /deletevalue {current} hypervisorlaunchtype >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Base de securite stock Windows 25H2 appliquee.%COLOR_RESET%
set "SECURITY_RESTORE_RC="
exit /b 0

:SET_CFG_NOTSET_SEHOP_OFF
REM Efface seulement CFG, desactive SEHOP et preserve toutes les autres mitigations.
powershell -NoProfile -Command "$p='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel';[byte[]]$b=(Get-ItemProperty $p -EA 0).MitigationOptions;if(-not $b){$b=New-Object byte[] 24};$b[5]=$b[5]-band 252;$b[9]=$b[9]-band 252;$b[0]=($b[0]-band 207)-bor 32;Set-ItemProperty $p MitigationOptions $b -EA Stop" >nul 2>&1
exit /b %errorlevel%

REM =================================================================================
REM TOGGLE_PROTECTIONS_NOYAU - Menu fusionne VBS/HVCI + Mitigations CPU
REM 3 modes : Defaut Windows / Gaming / Perf Max
REM =================================================================================
:TOGGLE_PROTECTIONS_NOYAU
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GERER LES PROTECTIONS WINDOWS"
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%DEFAUT WINDOWS%COLOR_RESET%
echo %COLOR_WHITE%    Restaure le snapshot ou applique la base stock 25H2 mesuree.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_CYAN%GAMING%COLOR_RESET%  %COLOR_GREEN%RECOMMANDE%COLOR_RESET%
echo %COLOR_WHITE%    Equilibre performances et protections pour tous types de jeux.%COLOR_RESET%
echo %COLOR_WHITE%    Conserve les protections utiles aux anti-cheats modernes.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_RED%PERFORMANCE MAX%COLOR_RESET%  %COLOR_RED%DECONSEILLE%COLOR_RESET%
echo %COLOR_WHITE%    Reduit davantage la securite et peut bloquer des anti-cheats.%COLOR_RESET%
call :SUBMENU_CHOICE "Gestion Windows" "Choisissez une option [1-3, M] : " 123M
if !errorlevel! EQU 4 goto :PROTECTIONS_RETURN
if !errorlevel! EQU 3 goto :PROTECTIONS_PERF_MAX
if !errorlevel! EQU 2 goto :PROTECTIONS_GAMING
if !errorlevel! EQU 1 goto :PROTECTIONS_WINDOWS_DEFAULT
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_WINDOWS_DEFAULT
call :SCREEN_HEADER " MODE DEFAUT WINDOWS"
echo %COLOR_WHITE%Ce mode restaure le snapshot ou applique la base stock 25H2 mesuree.%COLOR_RESET%
echo %COLOR_WHITE%Windows, les pilotes et les strategies determinent alors l'etat effectif.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Il revient aux valeurs precedentes quand un snapshot existe.%COLOR_RESET%
echo.
call :ASK_CONFIRM "%STYLE_BOLD%%COLOR_YELLOW%Appliquer le mode Defaut Windows ? [O=Appliquer / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :TOGGLE_PROTECTIONS_NOYAU
REM Applique integralement le profil Defaut Windows, quel que soit le profil precedent.
call :RESTAURER_PROTECTIONS_SECURITE
call :FINISH_ACTION "Mode Defaut Windows" "applique"
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_GAMING
call :SCREEN_HEADER " MODE GAMING"
echo %COLOR_WHITE%Ce mode conserve l'isolation et l'integrite de la memoire.%COLOR_RESET%
echo %COLOR_WHITE%Il reduit certaines protections du processeur pour les performances.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Tous types de jeux ; compatibilite anti-cheat elevee.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les changements.%COLOR_RESET%
echo.
call :ASK_CONFIRM "%STYLE_BOLD%%COLOR_YELLOW%Appliquer le mode Gaming ? [O=Appliquer / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :TOGGLE_PROTECTIONS_NOYAU
set "SKIP_PAUSE_TMP=!SKIP_PAUSE!"
set "SKIP_PAUSE=1"
set "PROFIL_USAGE_TMP=!PROFIL_USAGE!"
set "PROFIL_USAGE=0"
call :INIT_PROFILS
call :APPLIQUER_PROFIL_SECURITE
set "PROFIL_USAGE=!PROFIL_USAGE_TMP!"
set "PROFIL_USAGE_TMP="
set "SKIP_PAUSE=!SKIP_PAUSE_TMP!"
set "SKIP_PAUSE_TMP="
call :FINISH_ACTION "Mode Gaming" "applique"
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_PERF_MAX
call :SCREEN_HEADER " MODE PERFORMANCE MAX"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Protection de la memoire et du processeur reduite.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le gain varie selon le processeur et les pilotes.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Certains anti-cheats peuvent refuser le jeu.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%La surcharge BCD de l'hyperviseur sera supprimee.%COLOR_RESET%
echo %COLOR_WHITE%Windows reprendra son comportement par defaut.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Defaut Windows permet de restaurer la base de securite.%COLOR_RESET%
echo %COLOR_WHITE%Certaines protections, dont CFG et LSA, restent conservees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_YELLOW%Appliquer malgre la protection reduite ?%COLOR_RESET%
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Votre choix [O=Appliquer / N=Annuler] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :TOGGLE_PROTECTIONS_NOYAU

REM === Appliquer le profil Performance Max complet en un seul passage ===
REM PROFIL_USAGE=1 avec le drapeau interne selectionne directement la branche Performance Max.
set "SKIP_PAUSE_TMP=!SKIP_PAUSE!"
set "PROFIL_USAGE_TMP=!PROFIL_USAGE!"
set "PROFIL_USAGE=1"
set "SKIP_PAUSE=1"
call :INIT_PROFILS
set "SECURITY_FORCE_PERF_MAX=1"
call :APPLIQUER_PROFIL_SECURITE
set "SECURITY_FORCE_PERF_MAX="
set "PROFIL_USAGE=!PROFIL_USAGE_TMP!"
set "PROFIL_USAGE_TMP="
set "SKIP_PAUSE=!SKIP_PAUSE_TMP!"
set "SKIP_PAUSE_TMP="
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Reglages Performance max demandes : protections reduites.%COLOR_RESET%

call :FINISH_ACTION "Mode Performance max" "applique"
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_RETURN
goto :MENU_PRINCIPAL

:APPLY_SMARTSCREEN_DISABLE_EXTRA
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%La protection peut etre restauree depuis le profil Defender.%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de SmartScreen sur Windows, AppHost et Edge...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "TyposquattingCheckerEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%SmartScreen desactive sur les principales surfaces Windows.%COLOR_RESET%
exit /b

:RESTORE_SMARTSCREEN_DEFAULT_EXTRA
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Restauration SmartScreen par defaut...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "TyposquattingCheckerEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /f >nul 2>&1
exit /b

:TOGGLE_DEFENDER
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GERER WINDOWS DEFENDER"
echo %COLOR_WHITE%  Windows Defender analyse les fichiers et programmes en temps reel.%COLOR_RESET%
echo %COLOR_WHITE%  Windows peut proteger Defender contre les modifications.%COLOR_RESET%
echo %COLOR_WHITE%  Dans ce cas, certaines actions du script seront bloquees.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%REACTIVER DEFENDER%COLOR_RESET% : Antivirus et SmartScreen
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%DESACTIVER DEFENDER%COLOR_RESET% : Protection fortement reduite
call :SUBMENU_CHOICE "Gestion Windows" "Choisissez une option [1, 2, M] : " 12M
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_DEFENDER_SECTION
  goto :TOGGLE_DEFENDER
)
if !errorlevel! EQU 1 (
  call :ACTIVER_DEFENDER_SECTION
  goto :TOGGLE_DEFENDER
)
goto :TOGGLE_DEFENDER

REM  ___DEFENDER_ULT_EMBEDDED_SUBS___
:ACTIVER_DEFENDER_SECTION
call :SCREEN_HEADER " ACTIVATION DE WINDOWS DEFENDER"
echo %COLOR_WHITE%  Reactive Defender sans ecraser les regles ASR ni CFA.%COLOR_RESET%
echo.
set "DEFENDER_ACTION_ERROR=0"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reactivation des services Windows Defender...%COLOR_RESET%
sc query WinDefend >nul 2>&1
if !errorlevel! EQU 0 sc config WinDefend start= auto >nul 2>&1
for %%S in (WdNisSvc Sense SecurityHealthService WdNisDrv) do (
    sc query %%S >nul 2>&1
    if !errorlevel! EQU 0 sc config %%S start= demand >nul 2>&1
)
for %%S in (WdBoot WdFilter) do (
    sc query %%S >nul 2>&1
    if !errorlevel! EQU 0 sc config %%S start= boot >nul 2>&1
)
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService WdNisDrv) do sc start %%S >nul 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" >nul 2>&1 && reg add "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Suppression des politiques de desactivation ajoutees par l'outil...%COLOR_RESET%
for %%V in (DisableRealtimeMonitoring DisableIOAVProtection DisableScriptScanning DisableBehaviorMonitoring DisableOnAccessProtection DisableArchiveScanning DisableEmailScanning DisableRemovableDriveScanning DisableScanningMappedNetworkDrivesForFullScan DisableScanningNetworkFiles) do reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "%%V" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v DisableAsyncScanOnOpen /f >nul 2>&1
for %%V in (DisableAntiSpyware DisableAntiVirus DisableBlockAtFirstSeen DisableRoutinelyTakingAction) do reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "%%V" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v VerifiedAndReputableTrustModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v SmartLockerMode /t REG_DWORD /d 1 /f >nul 2>&1
call :RESTORE_SMARTSCREEN_DEFAULT_EXTRA

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Reactivation des protections principales...%COLOR_RESET%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableBlockAtFirstSeen $false -DisableIOAVProtection $false -DisableScriptScanning $false -DisableArchiveScanning $false -DisableEmailScanning $false -DisableRemovableDriveScanning $false -PUAProtection Enabled -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples -EnableNetworkProtection Enabled -ErrorAction Stop;exit 0}catch{exit 1}" >nul 2>&1
if !errorlevel! NEQ 0 set "DEFENDER_ACTION_ERROR=1"

for %%T in ("Microsoft\Windows\Windows Defender\Windows Defender Cleanup" "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" "Microsoft\Windows\Windows Defender\Windows Defender Update" "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" "Microsoft\Windows\Windows Defender\Windows Defender Verification" "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh") do schtasks /Change /TN "%%~T" /Enable >nul 2>&1
powershell -NoProfile -Command "try{$s=Get-MpComputerStatus -ErrorAction Stop;if($s.AntivirusEnabled-and$s.RealTimeProtectionEnabled){exit 0};exit 1}catch{exit 1}" >nul 2>&1
if !errorlevel! NEQ 0 set "DEFENDER_ACTION_ERROR=1"
if "!DEFENDER_ACTION_ERROR!"=="0" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Defender reactive ; ASR et CFA existants conserves.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Defender reste partiel ou gere par une politique externe.%COLOR_RESET%
)
call :FINISH_ACTION "Reglages Windows Defender" "traites"
exit /b !DEFENDER_ACTION_ERROR!
:DESACTIVER_DEFENDER_SECTION
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_DEFENDER_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%La desactivation retire l'antivirus et l'analyse en temps reel.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Plusieurs protections associees seront aussi reduites.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le gain de ressources varie selon le PC.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Defender pourra etre reactive depuis ce menu.%COLOR_RESET%
echo %COLOR_WHITE%  Utilisez cette option seulement si un autre antivirus protege deja le PC.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Si Windows bloque l'action, desactivez d'abord%COLOR_RESET%
echo %COLOR_WHITE%la protection contre les modifications dans Securite Windows.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Desactiver Windows Defender ? [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_DEFENDER_RUN
call :SCREEN_HEADER " DESACTIVATION DE WINDOWS DEFENDER"
echo %COLOR_WHITE%  Desactive Windows Defender, SmartScreen et les taches planifiees associees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Verification de la protection contre les modifications...%COLOR_RESET%
powershell -NoProfile -Command "if ((Get-MpComputerStatus).IsTamperProtected -eq $true) { exit 1 } else { exit 0 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%La protection contre les modifications est encore activee.%COLOR_RESET%
    if "!SKIP_PAUSE!"=="1" (
        echo %COLOR_WHITE%Defender est conserve.%COLOR_RESET%
        echo %COLOR_WHITE%Modifiez l'option dans Securite Windows, puis recommencez.%COLOR_RESET%
        goto :DEFENDER_SECTION_END
    )
    echo %COLOR_WHITE%La desactivation est arretee avant de laisser Defender dans un etat partiel.%COLOR_RESET%
    echo %COLOR_WHITE%Desactivez-la manuellement dans Securite Windows, puis relancez cette action.%COLOR_RESET%
    pause
    exit /b 1
)

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des preferences Defender...%COLOR_RESET%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';try{Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableBlockAtFirstSeen $true -DisableIOAVProtection $true -DisableScriptScanning $true -DisableArchiveScanning $true -DisableEmailScanning $true -DisableRemovableDriveScanning $true -PUAProtection Disabled -MAPSReporting Disabled -SubmitSamplesConsent 2 -EnableNetworkProtection Disabled -ErrorAction Stop;exit 0}catch{exit 1}" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Les preferences Defender n'ont pas converge ; les services restent actifs.%COLOR_RESET%
    exit /b 1
)

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des services Windows Defender...%COLOR_RESET%
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService) do sc stop %%S >nul 2>&1
for %%S in (WinDefend WdNisSvc Sense WdBoot WdFilter WdNisDrv SecurityHealthService) do sc config %%S start= disabled >nul 2>&1
for %%S in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend SecurityHealthService) do reg query "HKLM\SYSTEM\CurrentControlSet\Services\%%S" >nul 2>&1 && reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de la protection en temps reel...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScriptScanning" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v "DisableAsyncScanOnOpen" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des politiques Windows Defender...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "VerifiedAndReputableTrustModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "SmartLockerMode" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des taches planifiees de Defender et ExploitGuard...%COLOR_RESET%
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Update" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Disable >nul 2>&1

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de SmartScreen...%COLOR_RESET%
call :APPLY_SMARTSCREEN_DISABLE_EXTRA
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Preferences Defender et SmartScreen desactives.%COLOR_RESET%
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Desactivation de Defender demandee. Protection reduite selon Windows.%COLOR_RESET%
call :FINISH_ACTION "Reglages Windows Defender" "traites"
exit /b 0

:DEFENDER_SECTION_END
exit /b 1

:TOGGLE_UAC
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GERER UAC : CONTROLE DE COMPTE UTILISATEUR"
echo %COLOR_WHITE%  L'UAC affiche une invite de confirmation avant toute action admin.%COLOR_RESET%
echo %COLOR_WHITE%  Le desactiver supprime ces confirmations pour toutes les applications.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC : confirmations administrateur%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC : moins de confirmations%COLOR_RESET%
call :SUBMENU_CHOICE "Gestion Windows" "Choisissez une option [1, 2, M] : " 12M
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_UAC_SECTION
  goto :TOGGLE_UAC
)
if !errorlevel! EQU 1 (
  call :ACTIVER_UAC_SECTION
  goto :TOGGLE_UAC
)
goto :TOGGLE_UAC

:ACTIVER_UAC_SECTION
call :SCREEN_HEADER " ACTIVATION DE L'UAC"
echo %COLOR_WHITE%  Reactive le Controle de compte utilisateur.%COLOR_RESET%
echo %COLOR_WHITE%  Les confirmations administrateur seront de nouveau affichees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les demandes de confirmation administrateur seront de nouveau affichees.%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de l'UAC...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Activation de l'UAC demandee.%COLOR_RESET%
call :FINISH_ACTION "Reglage UAC" "traite"
exit /b 0

:DESACTIVER_UAC_SECTION
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_UAC_RUN
call :SCREEN_HEADER " CONFIRMATION : DESACTIVER L'UAC"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Les confirmations administrateur seront supprimees.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les applications pourront obtenir des droits eleves sans invite.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows Defender et SmartScreen ne changent pas.%COLOR_RESET%
echo %COLOR_WHITE%  Le reglage est reversible depuis le menu UAC.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Desactiver l'UAC ? [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_UAC_RUN
call :SCREEN_HEADER " DESACTIVATION DE L'UAC"
echo %COLOR_WHITE%  Desactive uniquement le Controle de compte utilisateur.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Les applications pourront obtenir des droits eleves%COLOR_RESET%
echo %COLOR_WHITE%sans demander de confirmation.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Effectif apres redemarrage et reversible depuis ce menu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'UAC...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'UAC demandee.%COLOR_RESET%
call :FINISH_ACTION "Reglage UAC" "traite"
exit /b 0

:TOGGLE_ANIMATIONS
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GERER LES ANIMATIONS WINDOWS"
echo %COLOR_WHITE%  Les animations utilisent un peu de processeur et de carte graphique.%COLOR_RESET%
echo %COLOR_WHITE%  Les desactiver peut rendre l'interface plus reactive,%COLOR_RESET%
echo %COLOR_WHITE%  mais moins fluide visuellement.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer les animations Windows : interface standard%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver les animations Windows : interface plus rapide%COLOR_RESET%
call :SUBMENU_CHOICE "Gestion Windows" "Choisissez une option [1, 2, M] : " 12M
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_ANIMATIONS_SECTION
  goto :TOGGLE_ANIMATIONS
)
if !errorlevel! EQU 1 (
  call :ACTIVER_ANIMATIONS_SECTION
  goto :TOGGLE_ANIMATIONS
)
goto :TOGGLE_ANIMATIONS

:ACTIVER_ANIMATIONS_SECTION
call :SCREEN_HEADER " ACTIVATION DES ANIMATIONS WINDOWS"
echo %COLOR_WHITE%  Reactive les animations, la transparence et les effets visuels Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation des animations et effets visuels...%COLOR_RESET%

REM  Le stock Windows 25H2 laisse VisualFXSetting absent : Windows choisit son comportement natif.
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1
for %%V in (MenuAnimation TooltipAnimation SelectionFade MenuFade) do reg delete "HKCU\Control Panel\Desktop" /v "%%V" /f >nul 2>&1
for %%V in (AnimateWindow ComboboxAnimation ListBoxSmoothScrolling) do reg delete "HKCU\Control Panel\Desktop" /v "%%V" /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop" /v UserUIEffects /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1

REM  Activer les effets visuels supplementaires
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop" /v CursorShadow /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /f >nul 2>&1

echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Activation des animations demandee.%COLOR_RESET%
call :FINISH_ACTION "Reglages animations" "traites"
exit /b 0

:DESACTIVER_ANIMATIONS_SECTION
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_ANIMATIONS_RUN
call :SCREEN_HEADER " CONFIRMATION : DESACTIVER LES ANIMATIONS WINDOWS"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Animations et transparence seront desactivees.%COLOR_RESET%
echo %COLOR_WHITE%L'interface paraitra moins fluide.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Reglage reversible depuis ce menu.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Une reconnexion peut etre necessaire.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les animations ? [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_ANIMATIONS_RUN
call :SCREEN_HEADER " DESACTIVATION DES ANIMATIONS WINDOWS"
echo %COLOR_WHITE%  Desactive les animations et effets visuels pour reduire la charge graphique.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Interface moins animee et transparence desactivee.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Reversible depuis ce menu ; reconnexion parfois necessaire.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des animations et effets visuels...%COLOR_RESET%

REM  VisualFXSetting=3 (Personnalise) pour que Windows utilise uniquement les cles
REM  individuelles ci-dessous sans recalculer tous les effets (ce qui reset le menu Demarrer)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1
for %%V in (MenuAnimation TooltipAnimation SelectionFade MenuFade) do reg add "HKCU\Control Panel\Desktop" /v "%%V" /t REG_SZ /d "0" /f >nul 2>&1
for %%V in (AnimateWindow ComboboxAnimation ListBoxSmoothScrolling) do reg add "HKCU\Control Panel\Desktop" /v "%%V" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1

REM  Garder les options utiles actives (Police, Ombre icone, Drag content)
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Desactivation des animations demandee.%COLOR_RESET%
call :FINISH_ACTION "Reglages animations" "traites"
exit /b 0

:MENU_IA_WIDGETS_RECALL
set "SKIP_PAUSE=0"
call :SCREEN_HEADER " GERER COPILOT, WIDGETS ET RECALL WINDOWS 11"
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Ces fonctions concernent Windows 11.%COLOR_RESET%
echo %COLOR_WHITE%Les reglages sont ignores lorsqu'une fonction est absente.%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- COPILOT ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer : Copilot%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver : Copilot%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- WIDGETS ---%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Activer : Widgets%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_RED%Desactiver : Widgets%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- RECALL WINDOWS 11 24H2 ---%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Activer : Recall%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desactiver : Recall%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_RED%Desactiver Copilot, Widgets et Recall%COLOR_RESET%
call :SUBMENU_CHOICE "Gestion Windows" "Choisissez une option [1-6, D, M] : " 123456DM
if !errorlevel! EQU 8 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 7 goto :MENU_IA_OPTION_8_GATE
if !errorlevel! EQU 6 goto :MENU_IA_OPTION_6_GATE
if !errorlevel! EQU 5 goto :MENU_IA_OPTION_5
if !errorlevel! EQU 4 goto :MENU_IA_OPTION_4_GATE
if !errorlevel! EQU 3 goto :MENU_IA_OPTION_3
if !errorlevel! EQU 2 goto :MENU_IA_OPTION_2_GATE
if !errorlevel! EQU 1 goto :MENU_IA_OPTION_1
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_8_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_8
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Confirmer la desactivation de Copilot, Widgets et Recall ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage peut etre necessaire.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les trois fonctions ? [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_8
call :DESACTIVER_IA_SECTION
if !errorlevel! NEQ 0 (
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
call :FINISH_ACTION "Toutes les fonctions IA/Widgets" "desactivees"
goto :MENU_IA_WIDGETS_RECALL

:DESACTIVER_IA_SECTION
call :SCREEN_HEADER " DESACTIVATION DE COPILOT / WIDGETS / RECALL"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des restrictions Copilot, Widgets et Recall.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
call :CORE_DESACTIVER_COPILOT
call :CORE_DESACTIVER_WIDGETS
call :CORE_DESACTIVER_RECALL
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Restrictions Copilot, Widgets et Recall appliquees.%COLOR_RESET%
exit /b 0

:MENU_IA_OPTION_6_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_6
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Recall ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Recall peut enregistrer des instantanes de votre activite.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les instantanes deja enregistres ne seront pas supprimes.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Recall pourra etre reactive depuis ce menu.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Votre choix [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_6
call :SCREEN_HEADER " DESACTIVATION DE RECALL"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de Recall...%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les instantanes existants sont conserves.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_RECALL
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Restrictions Recall appliquees.%COLOR_RESET%
call :FINISH_ACTION "Reglages Recall" "traites"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_5
call :SCREEN_HEADER " ACTIVATION DE RECALL"
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Recall pourra de nouveau enregistrer des instantanes.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage peut etre necessaire.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_RECALL
set "AI_ACTION_RC=!errorlevel!"
if "!AI_ACTION_RC!"=="2" (
    set "AI_ACTION_RC="
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%Recall n'est pas disponible sur cette version ou ce materiel.%COLOR_RESET%
    pause
    goto :MENU_IA_WIDGETS_RECALL
)
if not "!AI_ACTION_RC!"=="0" (
    set "AI_ACTION_RC="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Recall n'a pas pu etre reactive completement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
set "AI_ACTION_RC="
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Activation de Recall terminee.%COLOR_RESET%
call :FINISH_ACTION "Reglages Recall" "traites"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_4_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_4
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver les Widgets ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Desactiver les Widgets retire actualites et meteo.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Reactivable depuis ce menu ; redemarrage parfois necessaire.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les Widgets ? [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_4
call :SCREEN_HEADER " DESACTIVATION DES WIDGETS"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation des Widgets dans la barre des taches.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_WIDGETS
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Restrictions Widgets appliquees.%COLOR_RESET%
call :FINISH_ACTION "Reglages Widgets" "traites"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_3
call :SCREEN_HEADER " ACTIVATION DES WIDGETS"
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les actualites et la meteo reviendront dans la barre des taches.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_WIDGETS
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Widgets actives.%COLOR_RESET%
call :FINISH_ACTION "Reglages Widgets" "traites"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_2_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_2
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Copilot ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Desactiver Copilot retire ses suggestions et integrations Edge.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Reactivable depuis ce menu ; redemarrage parfois necessaire.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE "%STYLE_BOLD%%COLOR_YELLOW%Desactiver Copilot ? [O=Desactiver / N=Annuler] : %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_2
call :SCREEN_HEADER " DESACTIVATION DE COPILOT"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Desactivation de Copilot et de ses integrations Edge.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_COPILOT
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Restrictions Copilot appliquees.%COLOR_RESET%
call :FINISH_ACTION "Reglages Copilot" "traites"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_1
call :SCREEN_HEADER " ACTIVATION DE COPILOT"
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Reactiver Copilot restaure son bouton et ses suggestions IA.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_COPILOT
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Copilot active.%COLOR_RESET%
call :FINISH_ACTION "Reglages Copilot" "traites"
goto :MENU_IA_WIDGETS_RECALL


:CORE_ACTIVER_COPILOT
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de Copilot et de ses integrations Edge...%COLOR_RESET%
call :DELETE_REG_VALUE_IF_PRESENT "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /f >nul 2>&1
REM  Reactivation de Copilot dans Edge
for %%V in (HubsSidebarEnabled CopilotPageContext) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKCU\Software\Policies\Microsoft\Edge" "%%V"
)
for %%V in (HubsSidebarEnabled CopilotPageContext EdgeEntraCopilotPageContext Microsoft365CopilotChatIconEnabled) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Edge" "%%V"
)
    call :REMOVE_COPILOT_HOSTS_BLOCK
if not "!AIO_MODE!"=="1" ipconfig /flushdns >nul 2>&1
exit /b 0

:CORE_DESACTIVER_COPILOT
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des restrictions Copilot et de ses integrations Edge...%COLOR_RESET%
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /t REG_DWORD /d 0 /f >nul 2>&1
REM  Desactivation de Copilot dans Edge
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "CopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "CopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeEntraCopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "Microsoft365CopilotChatIconEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
    REM Les strategies suffisent ; nettoyer l'ancien bloc hosts qui cassait aussi le site Copilot.
    call :REMOVE_COPILOT_HOSTS_BLOCK
    if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le bloc hosts Copilot n'est pas nettoye ; les strategies restent appliquees.%COLOR_RESET%
if not "!AIO_MODE!"=="1" ipconfig /flushdns >nul 2>&1
exit /b 0


:CORE_ACTIVER_WIDGETS
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation des Widgets et de leur bouton...%COLOR_RESET%
call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests"
call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds"
REM TaskbarDa peut etre protege par Windows/UCPD. Retirer la strategie Dsh reactive deja les Widgets.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 1 /f >nul 2>&1
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows protege le bouton Widgets ; utilisez les Parametres pour l'afficher.%COLOR_RESET%
exit /b 0

:CORE_DESACTIVER_WIDGETS
set "WIDGETS_BUILD=0"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour les Widgets...%COLOR_RESET%
for /f "tokens=3" %%B in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "WIDGETS_BUILD=%%B"
if !WIDGETS_BUILD! GEQ 22000 (
    REM Windows 11 : strategie Widgets actuelle et bouton de la barre des taches.
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
    REM TaskbarDa peut etre protege par Windows/UCPD. La strategie Dsh suffit a desactiver toute l'experience Widgets.
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
    if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Bouton Widgets protege par Windows ; la strategie principale reste appliquee.%COLOR_RESET%
) else (
    REM Windows 10 : ancienne strategie Actualites et centres d'interet uniquement.
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul 2>&1
)
set "WIDGETS_BUILD="
exit /b 0


:CORE_ACTIVER_RECALL
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Activation de Recall et de ses fonctions associees...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 1 /f >nul 2>&1
REM Nettoyage des anciennes valeurs non officielles posees par des versions precedentes.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /f >nul 2>&1
for %%V in (DisableAgentWorkspaces DisableAgentConnectors DisableRemoteAgentConnectors DisableClickToDo) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "%%V"
)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageCreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableCocreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableGenerativeFill" /f >nul 2>&1
for %%V in (DisableImageCreator DisableCocreator DisableGenerativeFill) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" "%%V"
)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageSpaceForRecallSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageDurationForRecallSnapshots" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v "DisableClickToDo" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v "InsightsEnabled" /f >nul 2>&1
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; $f=Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction SilentlyContinue; if($null -eq $f){exit 2}; try { Enable-WindowsOptionalFeature -Online -FeatureName 'Recall' -NoRestart -ErrorAction Stop *>$null; exit 0 } catch { exit 1 }" >nul 2>&1
set "AI_FEATURE_RC=!errorlevel!"
if "!AI_FEATURE_RC!"=="2" (
    set "AI_FEATURE_RC="
    exit /b 2
)
if not "!AI_FEATURE_RC!"=="0" (
    set "AI_FEATURE_RC="
    exit /b 1
)
set "AI_FEATURE_RC="
exit /b 0

:CORE_DESACTIVER_RECALL
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour Recall...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /f >nul 2>&1
REM Valeur enumeree : 2 = forcer la desactivation (1 forcerait l'activation).
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentConnectors" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /t REG_DWORD /d 2 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableClickToDo" /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageCreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableCocreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableGenerativeFill" /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableImageCreator" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableCocreator" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableGenerativeFill" /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageSpaceForRecallSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageDurationForRecallSnapshots" /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
REM Nettoyer les anciennes surcharges non documentees sans modifier voix, saisie ou autorisations generales.
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /f >nul 2>&1
REM La suppression du composant est un nettoyage facultatif : les strategies ci-dessus suffisent a desactiver Recall.
REM DISM peut signaler un redemarrage requis comme un succes distinct ; cela ne doit pas invalider tout le bloc IA.
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { $f=Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction SilentlyContinue; if($null -ne $f -and $f.State -ne 'DisabledWithPayloadRemoved'){ Disable-WindowsOptionalFeature -Online -FeatureName 'Recall' -Remove -NoRestart -ErrorAction Stop *>$null }; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Strategies actives ; composant Recall conserve.%COLOR_RESET%
exit /b 0

:DESINSTALLER_ONEDRIVE
call :SCREEN_HEADER " DESINSTALLATION COMPLETE DE ONEDRIVE"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%OneDrive et son dossier utilisateur seront supprimes.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Les fichiers locaux non synchronises peuvent etre perdus.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Sauvegardez vos fichiers importants avant de continuer.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Desinstaller completement OneDrive ? [O=Desinstaller / N=Annuler] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS

call :SCREEN_HEADER " EXECUTION DESINSTALLATION COMPLETE DE ONEDRIVE"
echo %COLOR_WHITE%Progression : arret, deconnexion, desinstallation, nettoyage registre,%COLOR_RESET%
echo %COLOR_WHITE%taches planifiees, dossiers restants et raccourcis.%COLOR_RESET%
echo.

REM  Arreter les processus OneDrive
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 1 sur 7 : arret des processus OneDrive et sync Office...%COLOR_RESET%
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im OneDriveSetup.exe >nul 2>&1
taskkill /f /im FileCoAuth.exe >nul 2>&1
taskkill /f /im FileSyncHelper.exe >nul 2>&1
taskkill /f /im OneDriveStandaloneUpdater.exe >nul 2>&1
timeout /t 3 /nobreak >nul
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" explorer.exe >nul 2>&1
timeout /t 3 /nobreak >nul
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Processus OneDrive arretes.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 2 sur 7 : deconnexion des comptes OneDrive...%COLOR_RESET%
powershell -NoProfile -Command "try { Import-Module -Name Microsoft.PowerShell.Management -Force; Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Comptes OneDrive deconnectes.%COLOR_RESET%

REM  Commande pour desinstaller OneDrive
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 3 sur 7 : execution du desinstalleur OneDrive...%COLOR_RESET%
set "ONEDRIVE_UNINSTALLER="
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    set "ONEDRIVE_UNINSTALLER=%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe"
) else if exist "%SYSTEMROOT%\System32\OneDriveSetup.exe" (
    set "ONEDRIVE_UNINSTALLER=%SYSTEMROOT%\System32\OneDriveSetup.exe"
)
if defined ONEDRIVE_UNINSTALLER (
    "!ONEDRIVE_UNINSTALLER!" /uninstall >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Desinstalleur OneDrive execute.%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le desinstalleur OneDrive a retourne une erreur ; le nettoyage continue.%COLOR_RESET%
    )
) else (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%Desinstalleur OneDrive absent ; le nettoyage continue.%COLOR_RESET%
)
set "ONEDRIVE_UNINSTALLER="

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 4 sur 7 : nettoyage des reglages OneDrive...%COLOR_RESET%
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
reg delete "HKLM\SOFTWARE\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Cles OneDrive nettoyees.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 5 sur 7 : suppression des taches planifiees OneDrive...%COLOR_RESET%
REM PowerShell plutot que le CSV de schtasks : Windows 10 ajoute une colonne HostName en premiere position,
REM ce qui faisait echouer la suppression silencieusement.
powershell -NoProfile -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like '*OneDrive*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Taches planifiees OneDrive supprimees.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 6 sur 7 : nettoyage des dossiers OneDrive restants...%COLOR_RESET%
if exist "%AppData%\Microsoft\OneDrive" rd "%AppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%SystemDrive%\OneDriveTemp" rd "%SystemDrive%\OneDriveTemp" /q /s >nul 2>&1
REM  Wildcards : rd ne supporte pas les wildcards, il faut une enumeration for /d
for /d %%C in ("%Temp%\OneDrive*") do rd "%%C" /q /s >nul 2>&1
if exist "%USERPROFILE%\OneDrive" (
    call :TAKEOWN_RECURSIF "%USERPROFILE%\OneDrive"
    rd "%USERPROFILE%\OneDrive" /s /q >nul 2>&1
)
if exist "%LOCALAPPDATA%\Microsoft\OneDrive" (
    call :TAKEOWN_RECURSIF "%LOCALAPPDATA%\Microsoft\OneDrive"
    rd "%LOCALAPPDATA%\Microsoft\OneDrive" /s /q >nul 2>&1
)
if exist "%PROGRAMDATA%\Microsoft OneDrive" (
    call :TAKEOWN_RECURSIF "%PROGRAMDATA%\Microsoft OneDrive"
    rd "%PROGRAMDATA%\Microsoft OneDrive" /s /q >nul 2>&1
)
if exist "%SystemDrive%\OneDriveTemp" (
    call :TAKEOWN_RECURSIF "%SystemDrive%\OneDriveTemp"
    rd "%SystemDrive%\OneDriveTemp" /s /q >nul 2>&1
)
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Dossiers OneDrive restants nettoyes.%COLOR_RESET%

REM  Supprimer les raccourcis OneDrive du menu Demarrer
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 7 sur 7 : suppression des raccourcis OneDrive...%COLOR_RESET%
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Raccourcis OneDrive supprimes.%COLOR_RESET%

set "ONEDRIVE_REMOVE_OK=1"
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" set "ONEDRIVE_REMOVE_OK=0"
if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" set "ONEDRIVE_REMOVE_OK=0"
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Microsoft OneDrive\OneDrive.exe" set "ONEDRIVE_REMOVE_OK=0"
if exist "%USERPROFILE%\OneDrive" set "ONEDRIVE_REMOVE_OK=0"
if "!ONEDRIVE_REMOVE_OK!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification : OneDrive et son dossier utilisateur ne sont plus presents.%COLOR_RESET%
    call :FINISH_ACTION "OneDrive" "desinstalle"
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Verification : OneDrive est encore partiellement present.%COLOR_RESET%
    if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage peut liberer les fichiers encore verrouilles.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
)
set "ONEDRIVE_REMOVE_OK="
goto :MENU_GESTION_WINDOWS

:DESINSTALLER_EDGE
call :SCREEN_HEADER " DESINSTALLATION COMPLETE DE MICROSOFT EDGE"

echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Recherche, Widgets, Meteo et certaines applis web%COLOR_RESET%
echo %COLOR_WHITE%peuvent avoir besoin de Microsoft Edge.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows Update peut reinstaller Edge.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Desinstaller completement Microsoft Edge ? [O=Desinstaller / N=Annuler] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SUPPRESSION DES DONNEES UTILISATEUR%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%La suppression efface toutes les donnees locales du profil.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%En les conservant, elles resteront disponibles apres reinstallation.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Historique, cookies, favoris et mots de passe seront perdus.%COLOR_RESET%
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Les extensions et leurs reglages seront aussi supprimes.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Exportez les favoris et mots de passe avant de continuer.%COLOR_RESET%
echo.
echo %COLOR_WHITE%Confirmer la suppression des donnees utilisateur Edge ?%COLOR_RESET%
echo %COLOR_WHITE%- Historique de navigation%COLOR_RESET%
echo %COLOR_WHITE%- Cookies et donnees de sites%COLOR_RESET%
echo %COLOR_WHITE%- Favoris/Signets%COLOR_RESET%
echo %COLOR_WHITE%- Mots de passe sauvegardes%COLOR_RESET%
echo %COLOR_WHITE%- Extensions et themes%COLOR_RESET%
echo %COLOR_WHITE%- Parametres et preferences%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%[O] OUI : Supprimer les donnees Edge   [N] NON : Conserver les donnees : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 (
    set "SUPPR_DATA=0"
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Donnees Edge conservees pour une reinstallation.%COLOR_RESET%
) else (
    set "SUPPR_DATA=1"
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Donnees Edge supprimees sans restauration automatique.%COLOR_RESET%
)

call :SCREEN_HEADER " EXECUTION DESINSTALLATION COMPLETE DE MICROSOFT EDGE"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Arret, desinstallation et nettoyage de Microsoft Edge...%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 1 sur 12 : arret des processus Edge...%COLOR_RESET%
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Processus Edge arretes.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 2 sur 12 : suppression de l'icone Edge...%COLOR_RESET%
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1
if not exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" goto :EDGE_SKIP_TASKBAR_LINKS
call :REMOVE_EDGE_TASKBAR_LINKS
:EDGE_SKIP_TASKBAR_LINKS
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Raccourci Edge de la barre des taches supprime.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 3 sur 12 : execution du desinstalleur Edge...%COLOR_RESET%
set "EDGE_UNINSTALLER_FOUND=0"
if exist "%ProgramFiles%\Microsoft\Edge\Application" call :RUN_EDGE_UNINSTALLER "%ProgramFiles%\Microsoft\Edge\Application"
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" call :RUN_EDGE_UNINSTALLER "%ProgramFiles(x86)%\Microsoft\Edge\Application"
if "!EDGE_UNINSTALLER_FOUND!"=="1" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Desinstalleur Edge execute.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%Aucun desinstalleur Edge officiel trouve ; le nettoyage force continue.%COLOR_RESET%
)
set "EDGE_UNINSTALLER_FOUND="

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 4 sur 12 : nettoyage des dossiers programme Edge...%COLOR_RESET%
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
if defined ProgramFiles(x86) rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Dossiers programme Edge supprimes.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 5 sur 12 : nettoyage des reglages Edge...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Cles de registre Edge nettoyees.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 6 sur 12 : traitement des donnees utilisateur...%COLOR_RESET%
if "%SUPPR_DATA%"=="1" (
    if exist "%LOCALAPPDATA%\Microsoft\Edge" rd "%LOCALAPPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    if exist "%APPDATA%\Microsoft\Edge" rd "%APPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur Edge supprimees.%COLOR_RESET%
) else (
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\BrowserSwitcher" /f >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\PreferenceMACs" /f >nul 2>&1
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur Edge conservees.%COLOR_RESET%
)

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 7 sur 12 : nettoyage des donnees systeme partagees...%COLOR_RESET%
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Donnees systeme communes nettoyees%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 8 sur 12 : suppression des raccourcis Edge...%COLOR_RESET%
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Raccourcis Edge supprimes.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 9 sur 12 : suppression des associations Edge...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Classes\MSEdgeHTM" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\MSEdgePDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\msedge.exe" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Associations de fichiers Edge supprimees.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 10 sur 12 : nettoyage de l'index de recherche...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_http" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_https" /f >nul 2>&1
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Index de recherche et menu demarrer nettoyes.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 11 sur 12 : nettoyage des caches Edge...%COLOR_RESET%
del "%LOCALAPPDATA%\IconCache.db" /f /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f /q >nul 2>&1
if defined ProgramFiles(x86) reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Caches d'icones nettoyes.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Etape 12 sur 12 : blocage des reinstallations automatiques...%COLOR_RESET%
REM  Strategies Edge Update officielles. Elles sont surtout garanties sur les appareils joints a un domaine.
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "InstallDefault" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventFirstRunPage" /f >nul 2>&1
echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Strategie anti-reinstallation Edge appliquee si prise en charge.%COLOR_RESET%

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Verification finale de la desinstallation...%COLOR_RESET%
set "EDGE_REMOVE_OK=1"
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "EDGE_REMOVE_OK=0"
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "EDGE_REMOVE_OK=0"

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!EDGE_REMOVE_OK!"=="1" (
    echo  %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification : Microsoft Edge n'est plus installe.%COLOR_RESET%
) else (
    echo  %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Verification : desinstallation Edge incomplete.%COLOR_RESET%
)
if "%SUPPR_DATA%"=="0" (
    echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Favoris, mots de passe et historique Edge ont ete preserves.%COLOR_RESET%
)
echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%L'icone Edge a ete retiree de la barre des taches.%COLOR_RESET%
set "SUPPR_DATA="
if "!EDGE_REMOVE_OK!"=="1" (
    call :FINISH_ACTION "Microsoft Edge" "desinstalle"
) else (
    if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage peut liberer les fichiers encore verrouilles.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
)
set "EDGE_REMOVE_OK="
goto :MENU_GESTION_WINDOWS

:OUTIL_ACTIVATION
call :SCREEN_HEADER " OUTIL D'ACTIVATION WINDOWS ET OFFICE MAS"

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Lancement de l'outil d'activation ; suivez les instructions a l'ecran.%COLOR_RESET%
call :RUN_REMOTE_PS "https://get.activated.win"
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Outil d'activation termine.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de telecharger ou d'executer l'outil d'activation.%COLOR_RESET%
)
pause
goto :MENU_PRINCIPAL

:OUTIL_CHRIS_TITUS
call :SCREEN_HEADER " OUTIL CHRIS TITUS TECH WINUTIL"

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Lancement de l'outil Chris Titus Tech...%COLOR_RESET%
echo %COLOR_WHITE%Suivez les instructions affichees dans sa fenetre.%COLOR_RESET%
call :RUN_REMOTE_PS "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Outil Chris Titus Tech termine.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de telecharger ou d'executer WinUtil.%COLOR_RESET%
)
pause
goto :MENU_PRINCIPAL

:CREER_POINT_RESTAURATION
call :SCREEN_HEADER " CREATION D'UN POINT DE RESTAURATION"

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Verification et activation de la restauration systeme si necessaire...%COLOR_RESET%
powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive ($env:SystemDrive+'\') -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification : restauration systeme disponible sur %SystemDrive%.%COLOR_RESET%
) else (
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Restauration systeme non confirmee ; creation du point continue.%COLOR_RESET%
)
timeout /t 2 /nobreak >nul
echo.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Creation d'un point de restauration en cours...%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%La creation peut prendre jusqu'a 60 secondes.%COLOR_RESET%
echo.

for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss" 2^>nul') do set "RP_TIMESTAMP=%%a"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $key='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'; $name='SystemRestorePointCreationFrequency'; $had=$false; $old=$null; $ok=$false; try { $p=Get-ItemProperty -LiteralPath $key -ErrorAction Stop; $had=$p.PSObject.Properties.Name -contains $name; if($had){$old=$p.$name; Set-ItemProperty -LiteralPath $key -Name $name -Value 0 -ErrorAction Stop}else{New-ItemProperty -LiteralPath $key -Name $name -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null}; Checkpoint-Computer -Description 'Optimizations_%RP_TIMESTAMP%' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; $ok=$true } catch { $ok=$false } finally { try { if($had){Set-ItemProperty -LiteralPath $key -Name $name -Value $old -ErrorAction Stop}else{Remove-ItemProperty -LiteralPath $key -Name $name -ErrorAction SilentlyContinue} } catch { $ok=$false } }; if($ok){exit 0}else{exit 1}" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Point de restauration cree avec succes.%COLOR_RESET%
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Nom : Optimizations_%RP_TIMESTAMP%%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de la creation du point de restauration.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Verifiez la restauration systeme, l'espace disque%COLOR_RESET%
    echo %COLOR_WHITE%et les strategies de groupe.%COLOR_RESET%
)
set "RP_TIMESTAMP="
pause
goto :MENU_PRINCIPAL

:NETTOYAGE_AVANCE_WINDOWS
call :SCREEN_HEADER " NETTOYAGE AVANCE WINDOWS"

REM  Analyse espace initial
set "SPACE_BEFORE_MB="
for /f %%a in ('powershell -NoProfile -NoLogo -Command "[int]((Get-PSDrive -Name '%SystemDrive:~0,1%').Free / 1MB)" 2^>nul') do set "SPACE_BEFORE_MB=%%a"
if defined SPACE_BEFORE_MB (
    set "SPACE_MEASURE_OK=1"
) else (
    set "SPACE_MEASURE_OK=0"
    set "SPACE_BEFORE_MB=0"
)

echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Fichiers temporaires, caches et corbeille seront supprimes.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Documents, Images, Videos et donnees de recuperation sont conserves.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows.old fera l'objet d'une confirmation separee.%COLOR_RESET%
echo.
<nul set /p ="%COLOR_YELLOW%Lancer ce nettoyage maintenant ? [O=Lancer / N=Annuler] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_PRINCIPAL

call :SCREEN_HEADER " NETTOYAGE AVANCE WINDOWS"

REM  Initialiser la barre de progression (26 etapes - caches de perf conserves)
set /a "CLEAN_TOTAL=26"
set /a "CLEAN_STEP=0"
set /a "CLEAN_WARNINGS=0"
REM CLEAN_SCRIPT_PATH supprime : utiliser $env:WINOPT_SELF_BACKUP_SOURCE (defini en tete du script, delayed OFF) qui preserve le point exclam du chemin

REM  ETAPE 1 - Fichiers temporaires utilisateur (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires utilisateur"
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue';$self=[IO.Path]::GetFullPath($env:WINOPT_SELF_BACKUP_SOURCE);Get-ChildItem -LiteralPath $env:TEMP -Force|Where-Object{$p=[IO.Path]::GetFullPath($_.FullName);$p-ne$self-and-not $self.StartsWith($p+'\',[StringComparison]::OrdinalIgnoreCase)}|Remove-Item -Recurse -Force -ErrorAction SilentlyContinue;exit 0" >nul 2>&1

REM  ETAPE 2 - Fichiers temporaires Windows (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires Windows"
del /s /q /f "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >nul 2>&1
if exist "%SystemRoot%\Servicing\LC\*.tmp" del /s /q /f "%SystemRoot%\Servicing\LC\*.tmp" >nul 2>&1

REM  ETAPE 3 - Logs systeme (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs systeme"
del /s /q /f "%SystemRoot%\Logs\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Panther\*.log" >nul 2>&1

REM  ETAPE 4 - Fichiers de crash / dumps (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers de crash et dumps"
del /s /q /f "%SystemRoot%\Minidump\*.*" >nul 2>&1
del /q /f "%SystemRoot%\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\memory.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\LiveKernelReports\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\Sysdata\*.dmp" >nul 2>&1
del /s /q /f "%LOCALAPPDATA%\CrashDumps\*.*" >nul 2>&1

REM  ETAPE 5 - Rapports d'erreurs et Telemetrie
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Rapports d'erreurs et Telemetrie"
for %%D in (ReportArchive ReportQueue Temp) do if exist "%ProgramData%\Microsoft\Windows\WER\%%D" rd /s /q "%ProgramData%\Microsoft\Windows\WER\%%D" >nul 2>&1
for %%D in (ReportArchive ReportQueue Temp) do if exist "%LOCALAPPDATA%\Microsoft\Windows\WER\%%D" rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\WER\%%D" >nul 2>&1
REM  Le dossier Diagnosis et les racines WER sont conserves pour garder leurs ACL et services intacts.

REM  ETAPE 6 - Cache Windows Update et Delivery Optimization
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Update et Delivery Optimization"
for %%S in (wuauserv bits cryptsvc dosvc) do (
    set "CLEAN_WAS_RUNNING_%%S=0"
    powershell -NoProfile -Command "try { if((Get-Service -Name '%%S' -ErrorAction Stop).Status -eq 'Running'){exit 0}else{exit 1} } catch { exit 2 }" >nul 2>&1
    if !errorlevel! EQU 0 set "CLEAN_WAS_RUNNING_%%S=1"
    net stop %%S >nul 2>&1
)
timeout /t 2 /nobreak >nul
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
REM  DataStore et ReportingEvents.log contiennent l'historique Windows Update : Ne pas les effacer.
if exist "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" (
    rd /s /q "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
    md "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
)
for %%S in (wuauserv bits cryptsvc dosvc) do (
    if "!CLEAN_WAS_RUNNING_%%S!"=="1" net start %%S >nul 2>&1
    set "CLEAN_WAS_RUNNING_%%S="
)

REM  ETAPE 7 - Corbeille
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Corbeille"
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

REM  ETAPE 8 - Journaux composants Windows (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux composants Windows"
del /s /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\CBS\*.cab" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.cab" >nul 2>&1

REM  ETAPE 9 - Cache de polices
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache de polices"
set "CLEAN_FONTCACHE_WAS_RUNNING=0"
powershell -NoProfile -Command "try{if((Get-Service FontCache -ErrorAction Stop).Status -eq 'Running'){exit 0};exit 1}catch{exit 2}" >nul 2>&1
if !errorlevel! EQU 0 set "CLEAN_FONTCACHE_WAS_RUNNING=1"
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
if "!CLEAN_FONTCACHE_WAS_RUNNING!"=="1" net start FontCache >nul 2>&1
set "CLEAN_FONTCACHE_WAS_RUNNING="

REM  ETAPE 10 - Cache Windows Store et applications (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Store et applications"
powershell -NoProfile -Command "Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Edge|WebView|Microsoft\.Windows' } | ForEach-Object { Remove-Item -Path ($_.FullName+'\AC\INetCache\*') -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path ($_.FullName+'\AC\Temp\*') -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path ($_.FullName+'\LocalState\Cache\*') -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1
REM  wsreset.exe supprime (ouvre UI Store + 5-15s); vidage PS du cache suffit

REM  ETAPE 11 - Cache DNS
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache DNS"
ipconfig /flushdns >nul 2>&1

REM  ETAPE 12 - Journaux Event Viewer archives uniquement
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux Event Viewer archives"
del /q /f "%SystemRoot%\System32\winevt\Logs\Archive-*.evtx" >nul 2>&1
REM  Les journaux actifs Systeme, Application et Securite restent disponibles pour le diagnostic.

REM  ETAPE 13 - Ancienne installation Windows avec confirmation
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Anciennes installations Windows"
if exist "%SystemDrive%\Windows.old" (
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Supprimer Windows.old efface l'ancienne installation.%COLOR_RESET%
    call :ASK_IF_INTERACTIVE "[O] OUI : Supprimer Windows.old   [N] NON : Conserver Windows.old : "
    if !errorlevel! EQU 0 (
        call :TAKEOWN_RECURSIF "%SystemDrive%\Windows.old"
        icacls "%SystemDrive%\Windows.old" /grant *S-1-5-32-544:F /t >nul 2>&1
        rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
    ) else (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows.old est conserve et peut servir a la recuperation.%COLOR_RESET%
    )
)
REM  $SysReset, $Windows.~BT et $Windows.~WS sont conserves : ils peuvent servir a la recuperation ou a une mise a niveau en cours.

REM  ETAPE 14 - Optimisation disque (TRIM/Defrag)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation disque TRIM et Defrag"
defrag %SystemDrive% /O /H >nul 2>&1

REM  ETAPE 15 - Nettoyage Windows Cleanmgr (ameliore - plus de categories 2026)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Nettoyage Windows"
call :SELECT_CLEANMGR_SAGEID
REM Exclusions volontaires : Previous Installations (confirmation etape 13), Windows ESD
REM (source de reinitialisation) et User file versions (donnees de recuperation utilisateur).
for %%K in ("Active Setup Temp Folders" "BranchCache" "Content Indexer Cleaner" "Delivery Optimization Files" "Device Driver Packages" "Diagnostic Data Viewer database files" "Downloaded Program Files" "GameNewsFiles" "GameStatisticsFiles" "GameUpdateFiles" "Language Pack" "Memory Dump Files" "Offline Pages Files" "Old ChkDsk Files" "RetailDemo Offline Content" "Service Pack Cleanup" "Setup Log Files" "System error memory dump files" "System error minidump files" "Temporary Files" "Temporary Setup Files" "Temporary Sync Files" "Thumbnail Cache" "Update Cleanup" "Upgrade Discarded Files" "Windows Defender" "Windows Error Reporting Archive Files" "Windows Error Reporting Files" "Windows Error Reporting Queue Files" "Windows Error Reporting System Archive Files" "Windows Error Reporting System Queue Files" "Windows Error Reporting Temp Files" "Windows Upgrade Log Files") do (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" >nul 2>&1
    if !errorlevel! EQU 0 reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t REG_DWORD /d 2 /f >nul 2>&1
)
REM /sagerun nettoie tous les disques ; /d est ignore (non documente avec /sagerun).
powershell -NoProfile -Command "try {$p=Start-Process -FilePath 'cleanmgr' -ArgumentList '/sagerun:%SAGEID%' -NoNewWindow -PassThru -ErrorAction Stop;if(-not $p.WaitForExit(120000)){try{$p.Kill();$p.WaitForExit()}catch{};exit 2};exit $p.ExitCode}catch{exit 1}" >nul 2>&1
set "CLEANMGR_RC=!errorlevel!"
if not "!CLEANMGR_RC!"=="0" (
    set /a "CLEAN_WARNINGS+=1"
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%L'outil Windows n'a pas termine normalement.%COLOR_RESET%
    echo %COLOR_WHITE%Le reste du nettoyage continue.%COLOR_RESET%
)
powershell -NoProfile -Command "Get-ChildItem 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches' -ErrorAction SilentlyContinue|ForEach-Object{Remove-ItemProperty -LiteralPath $_.PSPath -Name 'StateFlags%SAGEID%' -ErrorAction SilentlyContinue}" >nul 2>&1
set "CLEANMGR_RC="

REM  ETAPE 16 - Nettoyage composants systeme (via DISM)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Nettoyage des composants systeme"
dism /online /Cleanup-Image /StartComponentCleanup /Quiet >nul 2>&1
set "CLEAN_DISM_RC=!errorlevel!"
if not "!CLEAN_DISM_RC!"=="0" if not "!CLEAN_DISM_RC!"=="3010" (
    set /a "CLEAN_WARNINGS+=1"
    echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Nettoyage composants : code !CLEAN_DISM_RC!.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les autres etapes continuent.%COLOR_RESET%
)
set "CLEAN_DISM_RC="

REM  ETAPE 17 - Fichiers temporaires profil systeme (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Profil systeme et caches Internet"
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\*.tmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*.*" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\*.tmp" >nul 2>&1

REM  ETAPE 18 - Cache d'icones (securise - redemarre l'explorateur)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache d'icones"
set "CLEAN_EXPLORER_WAS_RUNNING=0"
tasklist /fi "imagename eq explorer.exe" 2>nul | find /i "explorer.exe" >nul
if !errorlevel! EQU 0 set "CLEAN_EXPLORER_WAS_RUNNING=1"
if "!CLEAN_EXPLORER_WAS_RUNNING!"=="1" taskkill /f /im explorer.exe >nul 2>&1
if "!CLEAN_EXPLORER_WAS_RUNNING!"=="1" timeout /t 1 /nobreak >nul
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*" >nul 2>&1
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
if "!CLEAN_EXPLORER_WAS_RUNNING!"=="1" start explorer.exe >nul 2>&1
set "CLEAN_EXPLORER_WAS_RUNNING="

REM  ETAPE 19 - Caches Windows 11 : Widgets, Copilot, Recall (nouveau W11 2026)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Widgets, Copilot, Recall"
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AC\INetCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AC\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\AC\INetCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\AC\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\LocalCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\LocalCache" >nul 2>&1
REM  Copilot (W11 24H2+)
if exist "%LOCALAPPDATA%\Packages\Microsoft.Windows.Copilot_*\AC\INetCache" for /d %%d in ("%LOCALAPPDATA%\Packages\Microsoft.Windows.Copilot_*") do (
    if exist "%%d\AC\INetCache" rd /s /q "%%d\AC\INetCache" >nul 2>&1
    if exist "%%d\LocalCache" rd /s /q "%%d\LocalCache" >nul 2>&1
)
REM  Recall / AI Explorer (W11 2025+) - caches INet temporaires uniquement
if exist "%LOCALAPPDATA%\Packages\Microsoft.Windows.AI.Explorer_*\AC\Temp" for /d %%d in ("%LOCALAPPDATA%\Packages\Microsoft.Windows.AI.Explorer_*") do (
    if exist "%%d\AC\Temp" rd /s /q "%%d\AC\Temp" >nul 2>&1
)
REM  Recall snapshots conserves (donnees personnelles)

REM  ETAPE 20 - Cache notifications logs (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs notifications"
if exist "%LOCALAPPDATA%\Microsoft\Windows\Notifications" (
    del /s /q /f "%LOCALAPPDATA%\Microsoft\Windows\Notifications\*.log" >nul 2>&1
)

REM  ETAPE 21 - Logs et setup OneDrive (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs OneDrive"
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\logs" rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive\logs" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\logs" rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive\setup\logs" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" del /s /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.tmp" del /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.tmp" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\*.tmp" >nul 2>&1

REM  ETAPE 22 - Logs support Windows Defender (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs support Defender"
if exist "%ProgramData%\Microsoft\Windows Defender\Support\*.log" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Support\*.log" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Support\*.cab" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Support\*.cab" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Support\*.tmp" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Support\*.tmp" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Scans\*.tmp" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Scans\*.tmp" >nul 2>&1

REM  ETAPE 23 - Optimisation indexation Windows Search (compacte uniquement)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation indexation recherche"
set "CLEAN_WSEARCH_WAS_RUNNING=0"
powershell -NoProfile -Command "try{if((Get-Service WSearch -ErrorAction Stop).Status -eq 'Running'){exit 0};exit 1}catch{exit 2}" >nul 2>&1
if !errorlevel! EQU 0 set "CLEAN_WSEARCH_WAS_RUNNING=1"
net stop WSearch >nul 2>&1
timeout /t 1 /nobreak >nul
if exist "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.log" del /s /q /f "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.log" >nul 2>&1
if "!CLEAN_WSEARCH_WAS_RUNNING!"=="1" net start WSearch >nul 2>&1
set "CLEAN_WSEARCH_WAS_RUNNING="

REM  ETAPE 24 - Cache RDP / Bureau a distance (nouveau)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Bureau a distance RDP"
if exist "%LOCALAPPDATA%\Microsoft\TerminalServerClient\Cache" rd /s /q "%LOCALAPPDATA%\Microsoft\TerminalServerClient\Cache" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Remote Desktop Connection Manager\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Remote Desktop Connection Manager\*.tmp" >nul 2>&1

REM  ETAPE 25 - Logs et temps Office (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Temporaires Office"
if exist "%LOCALAPPDATA%\Microsoft\Office\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Office\*.tmp" >nul 2>&1
if exist "%TEMP%\Microsoft\Office\*.tmp" del /s /q /f "%TEMP%\Microsoft\Office\*.tmp" >nul 2>&1

REM  ETAPE 26 - Cache npm (node package manager)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache npm"
powershell -NoProfile -Command "$cache=npm config get cache 2>$null; if($cache -and (Test-Path $cache)){ Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue; Write-Output 'OK' }" >nul 2>&1

REM  Calcul final (PowerShell pour la precision des decimales)
if "%SPACE_MEASURE_OK%"=="1" (
    for /f "tokens=1-3" %%a in ('powershell -NoProfile -Command "$before=[long]%SPACE_BEFORE_MB% * 1024 * 1024; $after=(Get-PSDrive -Name '%SystemDrive:~0,1%').Free; $freed=$after-$before; if($freed -lt 0){$freed=0}; $beforeGB=[math]::Round($before/1GB, 2); $afterGB=[math]::Round($after/1GB, 2); $freedGB=[math]::Round($freed/1GB, 2); Write-Output ('{0} {1} {2}' -f $beforeGB,$afterGB,$freedGB)" 2^>nul') do (
        set "SPACE_BEFORE_GB=%%a"
        set "SPACE_AFTER_GB=%%b"
        set "SPACE_FREED_GB=%%c"
    )
)
if not defined SPACE_FREED_GB (
    set "SPACE_BEFORE_GB=N/D"
    set "SPACE_AFTER_GB=N/D"
    set "SPACE_FREED_GB=N/D"
)

set "CLEAN_STEP="
set "CLEAN_TOTAL="
REM CLEAN_SCRIPT_PATH supprime : voir le commentaire de l'ETAPE 1 (WINOPT_SELF_BACKUP_SOURCE)

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Nettoyage avance termine%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo   %COLOR_WHITE%Espace avant :%COLOR_RESET% %COLOR_YELLOW%%SPACE_BEFORE_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace apres :%COLOR_RESET% %COLOR_GREEN%%SPACE_AFTER_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace gagne :%COLOR_RESET% %COLOR_CYAN%%SPACE_FREED_GB% Go%COLOR_RESET%
if not "%CLEAN_WARNINGS%"=="0" echo   %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%%CLEAN_WARNINGS% etapes terminees avec avertissement ; consultez les messages precedents.%COLOR_RESET%
echo.
if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
set "SAGEID="
set "SPACE_BEFORE_MB="
set "SPACE_BEFORE_GB="
set "SPACE_AFTER_GB="
set "SPACE_FREED_GB="
set "SPACE_MEASURE_OK="
set "CLEAN_WARNINGS="
goto :MENU_PRINCIPAL


:INSTALLER_VISUAL_REDIST
call :SCREEN_HEADER " INSTALLATION DES RUNTIMES VISUAL C++ ET DIRECTX"

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Detection du runtime Visual C++ v14 actuel...%COLOR_RESET%

REM  Detection via les cles VC14 officielles (Installed=1), confirmee par la DLL principale.
call :DETECT_VC14_RUNTIME

REM  Compter combien sont deja installes
set /a "VCINSTALLED_COUNT=%VC2015X86%+%VC2015X64%" 2>nul

echo.
echo %COLOR_WHITE%Versions detectees V14 :%COLOR_RESET% %COLOR_GREEN%%VCINSTALLED_COUNT%/2%COLOR_RESET%

REM  Si tout est deja installe, afficher message et retourner
if "%VCINSTALLED_COUNT%"=="2" (
    echo.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification : toutes les versions V14 sont deja installees.%COLOR_RESET%
    set "VC2015X86="
    set "VC2015X64="
    set "VCINSTALLED_COUNT="
    if "!SKIP_PAUSE!"=="0" timeout /t 2 /nobreak >nul
    goto :INSTALLER_DIRECTX_SECTION
)

REM  Suite : installation des paquets VC++ manquants (flux sequentiel, pas de goto vers ce point)
echo.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Installation des versions manquantes...%COLOR_RESET%
set /a "VC_TO_INSTALL=2-VCINSTALLED_COUNT"
echo %COLOR_WHITE%Packages a installer:%COLOR_RESET% %COLOR_YELLOW%%VC_TO_INSTALL%%COLOR_RESET%
echo.

REM  Initialiser la barre de progression (2 packages au total)
set /a "VC_TOTAL=2"
set /a "VC_STEP=0"

REM  Creer un dossier temporaire pour les installations
set "VCREDIST_DIR=%TEMP%\VCRedistInstall_%RANDOM%_%RANDOM%"
if not exist "%VCREDIST_DIR%" mkdir "%VCREDIST_DIR%" >nul 2>&1

REM  Visual C++ v14 actuel x86
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "Visual C++ v14 actuel x86"
if "%VC2015X86%"=="0" call :INSTALL_VC14_REDIST x86 "https://aka.ms/vc14/vc_redist.x86.exe" "vc2015x86.exe"

REM  Visual C++ v14 actuel x64
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "Visual C++ v14 actuel x64"
if "%VC2015X64%"=="0" call :INSTALL_VC14_REDIST x64 "https://aka.ms/vc14/vc_redist.x64.exe" "vc2015x64.exe"
echo.
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Verification des installations...%COLOR_RESET%

REM  Re-detection avec la meme source de verite qu'avant l'installation.
call :DETECT_VC14_RUNTIME
set /a "VCINSTALL=VC2015X86+VC2015X64" 2>nul

echo.
if "%VCINSTALL%"=="2" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification reelle : %COLOR_GREEN%%VCINSTALL%/2%COLOR_RESET% %COLOR_WHITE%versions presentes.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Verification reelle : %COLOR_RED%%VCINSTALL%/2%COLOR_RESET% %COLOR_WHITE%versions presentes.%COLOR_RESET%
)
if "!SKIP_PAUSE!"=="0" timeout /t 3 /nobreak >nul

REM  Nettoyage des fichiers temporaires
if exist "%VCREDIST_DIR%" rd /s /q "%VCREDIST_DIR%" >nul 2>&1
set "VC_STEP="
set "VC_TOTAL="
set "VCREDIST_DIR="
set "VC_TO_INSTALL="
set "VC2015X86="
set "VC2015X64="
set "VCINSTALL="
set "VCINSTALLED_COUNT="
set "VC_EXIT="
goto :INSTALLER_DIRECTX_SECTION

:INSTALLER_DIRECTX_SECTION
cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DE DIRECTX RUNTIME JUNE 2010%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :INSTALLER_DIRECTX
set "DX_SECTION_RESULT=!errorlevel!"

if "!SKIP_PAUSE!"=="0" (
    echo.
    pause
)
exit /b !DX_SECTION_RESULT!

:INSTALLER_DIRECTX
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Verification de l'installation de DirectX...%COLOR_RESET%

REM  Detection de DirectX June 2010 (XAudio2_7.dll est un bon indicateur).
REM  Sur Windows 64 bits, les runtimes x64 ET x86 doivent etre presents.
call :DETECT_DIRECTX_JUNE2010

if "%DX_INSTALLED%"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification : DirectX June 2010 est deja installe.%COLOR_RESET%
    set "DX_INSTALLED="
    set "DX_TEMP="
    exit /b 0
)

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Preparation de l'installation...%COLOR_RESET%
set "DX_TEMP=%TEMP%\DirectXInstall_%RANDOM%_%RANDOM%"
mkdir "%DX_TEMP%" >nul 2>&1

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Telechargement de DirectX Redist June 2010, environ 95 Mo...%COLOR_RESET%
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $f=Join-Path $env:DX_TEMP 'directx_redist.exe'; Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -OutFile $f -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $f).Length -lt 80000000){throw 'size'};$s=Get-AuthenticodeSignature -LiteralPath $f;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft'){throw 'signature'};exit 0 } catch { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de DirectX.%COLOR_RESET%
    rd /s /q "%DX_TEMP%" >nul 2>&1
    set "DX_INSTALLED="
    set "DX_TEMP="
    exit /b 1
)
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Extraction des fichiers...%COLOR_RESET%
REM  Utiliser l'extracteur integre de DirectX si possible, ou fallback
"%DX_TEMP%\directx_redist.exe" /Q /T:"%DX_TEMP%" >nul 2>&1
set "DX_RESULT=!errorlevel!"

echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Installation silencieuse en cours...%COLOR_RESET%
if "!DX_RESULT!"=="0" (
    if exist "%DX_TEMP%\DXSETUP.exe" (
        start /wait "" "%DX_TEMP%\DXSETUP.exe" /silent >nul 2>&1
        set "DX_RESULT=!errorlevel!"
        if "!DX_RESULT!"=="3010" (
            set "DX_REBOOT=1"
            set "DX_RESULT=0"
        )
        if "!DX_RESULT!"=="1641" (
            set "DX_REBOOT=1"
            set "DX_RESULT=0"
        )
        if "!DX_RESULT!"=="0" (
            call :DETECT_DIRECTX_JUNE2010
            if "!DX_INSTALLED!"=="1" (
                echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification : DirectX June 2010 est installe.%COLOR_RESET%
                if defined DX_REBOOT echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est requis par l'installateur DirectX.%COLOR_RESET%
            ) else (
                set "DX_RESULT=1"
                echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP a termine, mais les runtimes restent incomplets.%COLOR_RESET%
            )
        ) else (
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP a retourne le code !DX_RESULT!.%COLOR_RESET%
            echo %COLOR_WHITE%L'installation est peut-etre incomplete.%COLOR_RESET%
        )
    ) else (
        set "DX_RESULT=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP.exe est introuvable apres extraction.%COLOR_RESET%
    )
) else (
    set "DX_RESULT=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Une erreur est survenue lors de l'extraction.%COLOR_RESET%
)

REM  Nettoyage
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Nettoyage des fichiers temporaires...%COLOR_RESET%
rd /s /q "%DX_TEMP%" >nul 2>&1

set "DX_INSTALLED="
set "DX_TEMP="
set "DX_REBOOT="
if "!DX_RESULT!"=="0" (
    set "DX_RESULT="
    exit /b 0
)
set "DX_RESULT="
exit /b 1


:SUPPRIMER_BLOATWARES
call :SCREEN_HEADER " SUPPRESSION DES APPLICATIONS PREINSTALLEES"
echo %COLOR_RED%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%La liste sera desinstallee pour tous les utilisateurs.%COLOR_RESET%
echo.
echo %COLOR_RED%[SUPPRIMES]%COLOR_RESET% %COLOR_WHITE%News, Solitaire, Skype, People, Family et Candy Crush,%COLOR_RESET%
echo %COLOR_WHITE%Aide, Assistance rapide, Conseils, Maps et Office Hub,%COLOR_RESET%
echo %COLOR_WHITE%Mixed Reality, Feedback et Forfaits mobiles.%COLOR_RESET%
echo %COLOR_GREEN%[CONSERVES]%COLOR_RESET% %COLOR_WHITE%Courrier, Meteo, Musique, Video,%COLOR_RESET%
echo %COLOR_WHITE%Calculatrice, Store, Photos et Notes.%COLOR_RESET%
echo.
<nul set /p ="%COLOR_YELLOW%Desinstaller cette liste d'applications ? [O=Desinstaller / N=Annuler] : %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS

call :SCREEN_HEADER " EXECUTION - SUPPRESSION DES APPLICATIONS PREINSTALLEES"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Recherche et suppression des applications preinstallees...%COLOR_RESET%
set "APPX_RESULT_FILE=%TEMP%\WindowsOptimizer_appx_%RANDOM%_%RANDOM%.tmp"
set "APPX_REMOVED=0"
set "APPX_MISSING=0"
set "APPX_FAILED=0"
set "APPX_RESULT_OK=0"
powershell -NoProfile -Command "$apps=@('Microsoft.BingNews','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.SkypeApp','Microsoft.FeedbackHub','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.OneConnect','Microsoft.WindowsMaps','Microsoft.MixedReality.Portal','Microsoft.People','Microsoft.Family','King.CandyCrushSaga','King.CandyCrushSodaSaga','Microsoft.QuickAssist');$removed=0;$missing=0;$failed=0;$prov=@(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue);foreach($app in $apps){$packages=@(Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue);$provisioned=@($prov|Where-Object{$_.DisplayName-eq$app-or$_.PackageName-like($app+'_*')});if($packages.Count-eq0-and$provisioned.Count-eq0){$missing++;Write-Host \"   [IGNORE] Non installe : $app\" -ForegroundColor DarkGray;continue};Write-Host \"   [INFO] Suppression de : $app ...\" -ForegroundColor Cyan;$appFailed=$false;foreach($package in $packages){try{$package|Remove-AppxPackage -AllUsers -ErrorAction Stop}catch{$appFailed=$true}};foreach($package in $provisioned){try{Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop|Out-Null}catch{$appFailed=$true}};if($appFailed){$failed++;Write-Host \"   [AVERTISSEMENT] Suppression incomplete : $app\" -ForegroundColor Yellow}else{$removed++}};[IO.File]::WriteAllText($env:APPX_RESULT_FILE,($removed.ToString()+'|'+$missing.ToString()+'|'+$failed.ToString()),[Text.Encoding]::ASCII);if($failed-gt0){exit 1};exit 0"
set "APPX_RC=!errorlevel!"
if exist "!APPX_RESULT_FILE!" for /f "usebackq tokens=1-3 delims=^|" %%A in ("!APPX_RESULT_FILE!") do (
    set "APPX_REMOVED=%%A"
    set "APPX_MISSING=%%B"
    set "APPX_FAILED=%%C"
    set "APPX_RESULT_OK=1"
)
if exist "!APPX_RESULT_FILE!" del /f /q "!APPX_RESULT_FILE!" >nul 2>&1
echo.
if "!APPX_RESULT_OK!"=="0" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Le bilan de suppression n'a pas pu etre etabli.%COLOR_RESET%
) else if "!APPX_RC!"=="0" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%!APPX_REMOVED! application traitee ; !APPX_MISSING! deja absente.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%!APPX_FAILED! application non supprimee completement.%COLOR_RESET%
    echo %COLOR_WHITE%!APPX_REMOVED! traitee ; !APPX_MISSING! deja absente.%COLOR_RESET%
)
set "APPX_RESULT_FILE="
set "APPX_REMOVED="
set "APPX_MISSING="
set "APPX_FAILED="
set "APPX_RESULT_OK="
set "APPX_RC="
pause
goto :MENU_GESTION_WINDOWS

:END_SCRIPT
REM  Sans expansion retardee : evite que les "!" dans les textes ([EN COURS], AU REVOIR!, etc.) cassent la fin du script
setlocal DisableDelayedExpansion
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% AU REVOIR ! %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %COLOR_WHITE%Merci d'avoir utilise le script d'optimisation.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_YELLOW%Redemarrez votre PC pour finaliser l'optimisation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
REM  EXIT /B ferme automatiquement les SETLOCAL. Garder EnableExtensions actif
REM  jusqu'a la sortie evite un echec final si CMD les avait desactivees au depart.
exit /b 0

REM  =================================================================================
REM  HELPERS
REM  =================================================================================

REM  --- Windows, registre et nettoyage ------------------------------------------------
:BACKUP_SELF_BEFORE_EXECUTION
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$d=$env:WINOPT_BACKUP_DIR;$s=$env:WINOPT_SELF_BACKUP_SOURCE;if([string]::IsNullOrWhiteSpace($s)-or-not(Test-Path -LiteralPath $s)){exit 1};New-Item -ItemType Directory -Path $d -Force|Out-Null;$dst=Join-Path $d ('All in One_'+[guid]::NewGuid().ToString('N')+'.cmd');Copy-Item -LiteralPath $s -Destination $dst -Force;if(-not(Test-Path -LiteralPath $dst)-or((Get-Item -LiteralPath $dst).Length-ne(Get-Item -LiteralPath $s).Length)){exit 1};exit 0}catch{exit 1}" >nul 2>&1
exit /b !errorlevel!

:BACKUP_HOSTS_BEFORE_CHANGE
set "WINOPT_HOSTS_SOURCE=%~1"
if not defined WINOPT_HOSTS_SOURCE set "WINOPT_HOSTS_SOURCE=%SystemRoot%\System32\drivers\etc\hosts"
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$s=$env:WINOPT_HOSTS_SOURCE;if(-not(Test-Path -LiteralPath $s)){exit 0};$d=Join-Path $env:WINOPT_BACKUP_DIR 'Hosts';New-Item -ItemType Directory -Path $d -Force|Out-Null;$dst=Join-Path $d ('hosts_'+[guid]::NewGuid().ToString('N')+'.bak');Copy-Item -LiteralPath $s -Destination $dst -Force;if(-not(Test-Path -LiteralPath $dst)-or((Get-Item -LiteralPath $dst).Length-ne(Get-Item -LiteralPath $s).Length)){exit 1};exit 0}catch{exit 1}" >nul 2>&1
set "WINOPT_HOSTS_BACKUP_RC=!errorlevel!"
set "WINOPT_HOSTS_SOURCE="
exit /b !WINOPT_HOSTS_BACKUP_RC!

:CAPTURE_SECURITY_BASELINE
if exist "%WINOPT_SECURITY_BACKUP%" if exist "%WINOPT_SECURITY_BCD_BACKUP%" exit /b 0
if exist "%WINOPT_SECURITY_BACKUP%" exit /b 1
if exist "%WINOPT_SECURITY_BCD_BACKUP%" exit /b 1
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$r=$env:WINOPT_SECURITY_BACKUP;$b=$env:WINOPT_SECURITY_BCD_BACKUP;New-Item -ItemType Directory -Path (Split-Path -Parent $r) -Force|Out-Null;$targets=@(@{Path='SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management';Names=@('MoveImages','EnableGdsMitigation','PerformMmioMitigation','RestrictIndirectBranchPrediction','EnableKvashadow','KvaOpt','DisableStibp','EnableRetpoline','DisableBranchPrediction','FeatureSettings','FeatureSettingsOverride','FeatureSettingsOverrideMask')},@{Path='SYSTEM\CurrentControlSet\Control\Session Manager\Kernel';Names=@('KernelSEHOPEnabled','DisableExceptionChainValidation','MitigationOptions','MitigationAuditOptions')},@{Path='SYSTEM\CurrentControlSet\Control\DeviceGuard';Names=@('EnableVirtualizationBasedSecurity','RequirePlatformSecurityFeatures','Locked')},@{Path='SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity';Names=@('Enabled','Locked','WasEnabledBy')},@{Path='SOFTWARE\Policies\Microsoft\Windows\DeviceGuard';Names=@('EnableVirtualizationBasedSecurity','RequirePlatformSecurityFeatures','HypervisorEnforcedCodeIntegrity','LsaCfgFlags')},@{Path='SOFTWARE\Policies\Microsoft\Windows\System';Names=@('RunAsPPL')},@{Path='SYSTEM\CurrentControlSet\Control\Lsa';Names=@('LsaCfgFlags','RunAsPPLBoot','RunAsPPL')},@{Path='SYSTEM\CurrentControlSet\Control\CI\Policy';Names=@('WHQLSettings')},@{Path='SYSTEM\CurrentControlSet\Control\CI\Config';Names=@('VulnerableDriverBlocklistEnable')});$base=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$lines=@('Windows Registry Editor Version 5.00','');foreach($x in $targets){$lines+=('[HKEY_LOCAL_MACHINE\'+$x.Path+']');$key=$base.OpenSubKey($x.Path,$false);foreach($n in $x.Names){$present=$key-and($key.GetValueNames()-contains$n);if(-not$present){$lines+=([char]34+$n+[char]34+'=-');continue};$kind=$key.GetValueKind($n);$value=$key.GetValue($n,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);if($kind-eq[Microsoft.Win32.RegistryValueKind]::DWord){$lines+=('{0}=dword:{1:x8}'-f([char]34+$n+[char]34),[uint32]$value)}elseif($kind-eq[Microsoft.Win32.RegistryValueKind]::QWord){$lines+=('{0}=hex(b):{1}'-f([char]34+$n+[char]34),(([BitConverter]::GetBytes([uint64]$value)|ForEach-Object{$_.ToString('x2')})-join','))}elseif($kind-eq[Microsoft.Win32.RegistryValueKind]::Binary){$lines+=('{0}=hex:{1}'-f([char]34+$n+[char]34),(([byte[]]$value|ForEach-Object{$_.ToString('x2')})-join','))}else{$v=([string]$value).Replace('\','\\').Replace([string][char]34,'\'+[char]34);$lines+=([char]34+$n+[char]34+'='+[char]34+$v+[char]34)}};if($key){$key.Dispose()};$lines+=''};$base.Dispose();[IO.File]::WriteAllLines($r,$lines,[Text.Encoding]::Unicode);$bt=(& bcdedit.exe /enum '{current}' 2>$null)-join[Environment]::NewLine;$v='__ABSENT__';if($bt-match'(?m)^\s*hypervisorlaunchtype\s+(\S+)'){$v=$Matches[1]};[IO.File]::WriteAllText($b,$v,[Text.Encoding]::ASCII);exit 0}catch{Remove-Item -LiteralPath @($env:WINOPT_SECURITY_BACKUP,$env:WINOPT_SECURITY_BCD_BACKUP) -Force -ErrorAction SilentlyContinue;exit 1}" >nul 2>&1
exit /b !errorlevel!

:RESTORE_SECURITY_BASELINE
if not exist "%WINOPT_SECURITY_BACKUP%" if not exist "%WINOPT_SECURITY_BCD_BACKUP%" exit /b 2
if not exist "%WINOPT_SECURITY_BACKUP%" exit /b 1
if not exist "%WINOPT_SECURITY_BCD_BACKUP%" exit /b 1
reg import "%WINOPT_SECURITY_BACKUP%" >nul 2>&1
if !errorlevel! NEQ 0 exit /b 1
set "WINOPT_BCD_VALUE="
for /f "usebackq delims=" %%A in ("%WINOPT_SECURITY_BCD_BACKUP%") do set "WINOPT_BCD_VALUE=%%A"
if not defined WINOPT_BCD_VALUE exit /b 1
if /i "!WINOPT_BCD_VALUE!"=="__ABSENT__" (
    bcdedit /deletevalue {current} hypervisorlaunchtype >nul 2>&1
) else (
    bcdedit /set {current} hypervisorlaunchtype !WINOPT_BCD_VALUE! >nul 2>&1
)
if !errorlevel! NEQ 0 exit /b 1
del /f /q "%WINOPT_SECURITY_BACKUP%" "%WINOPT_SECURITY_BCD_BACKUP%" >nul 2>&1
set "WINOPT_BCD_VALUE="
exit /b 0

:SET_MEMORY_POWER_PROFILE
set "MEMORY_POWER_ERROR=0"
echo %COLOR_YELLOW%[EN COURS]%COLOR_RESET% %COLOR_WHITE%Synchronisation de la memoire avec le profil d'energie...%COLOR_RESET%
if "!PROFIL_POWER!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 0 /f >nul 2>&1
)
if !errorlevel! NEQ 0 set "MEMORY_POWER_ERROR=1"
if "!PROFIL_POWER!"=="0" (
    call :FTH_DISABLE
) else (
    call :FTH_RESTORE
)
set "MEMORY_FTH_RC=!errorlevel!"
if not "!MEMORY_FTH_RC!"=="0" set "MEMORY_POWER_ERROR=1"
set "RAM_GB=0"
for /f %%A in ('powershell -NoProfile -Command "[math]::Round(((Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop|Measure-Object Capacity -Sum).Sum)/1GB,0)" 2^>nul') do if not "%%A"=="" set "RAM_GB=%%A"
if "!RAM_GB!"=="0" set "MEMORY_POWER_ERROR=1"
if "!PROFIL_POWER!"=="1" (
    powershell -NoProfile -Command "$ErrorActionPreference='Stop';Enable-MMAgent -MemoryCompression -ErrorAction Stop" >nul 2>&1
) else if !RAM_GB! GTR 8 (
    powershell -NoProfile -Command "$ErrorActionPreference='Stop';Disable-MMAgent -MemoryCompression -ErrorAction Stop" >nul 2>&1
) else (
    powershell -NoProfile -Command "$ErrorActionPreference='Stop';Enable-MMAgent -MemoryCompression -ErrorAction Stop" >nul 2>&1
)
if !errorlevel! NEQ 0 set "MEMORY_POWER_ERROR=1"
if "!MEMORY_POWER_ERROR!"=="0" (
    echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Memoire, FTH et compression alignes avec le profil d'energie.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%La convergence du profil memoire est incomplete.%COLOR_RESET%
)
set "MEMORY_FTH_RC="
exit /b !MEMORY_POWER_ERROR!

:FTH_DISABLE
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$f=$env:WINOPT_FTH_BACKUP;$base=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$key=$base.OpenSubKey('SOFTWARE\Microsoft\FTH',$true);if(-not$key){$key=$base.CreateSubKey('SOFTWARE\Microsoft\FTH')};if(Test-Path -LiteralPath $f){$present=$key.GetValueNames()-contains'Enabled';if($present-and$key.GetValueKind('Enabled')-eq[Microsoft.Win32.RegistryValueKind]::DWord-and[int]$key.GetValue('Enabled')-eq 0){exit 0};exit 2};$present=$key.GetValueNames()-contains'Enabled';$state=[ordered]@{Present=$present;Kind='None';Value=$null};if($present){$kind=$key.GetValueKind('Enabled');$state.Kind=[string]$kind;$value=$key.GetValue('Enabled',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);if($kind-eq[Microsoft.Win32.RegistryValueKind]::Binary){$state.Value=[Convert]::ToBase64String([byte[]]$value)}elseif($kind-eq[Microsoft.Win32.RegistryValueKind]::MultiString){$state.Value=@($value)}else{$state.Value=$value}};[IO.File]::WriteAllText($f,($state|ConvertTo-Json -Depth 5),[Text.Encoding]::UTF8);$key.SetValue('Enabled',0,[Microsoft.Win32.RegistryValueKind]::DWord);if($key.GetValueKind('Enabled')-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$key.GetValue('Enabled')-ne 0){exit 1};exit 0}catch{exit 1}" >nul 2>&1
exit /b !errorlevel!

:FTH_RESTORE
if not exist "%WINOPT_FTH_BACKUP%" exit /b 0
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$f=$env:WINOPT_FTH_BACKUP;$state=Get-Content -LiteralPath $f -Raw|ConvertFrom-Json;$base=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$key=$base.OpenSubKey('SOFTWARE\Microsoft\FTH',$true);$present=$key-and($key.GetValueNames()-contains'Enabled');if($present-and($key.GetValueKind('Enabled')-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$key.GetValue('Enabled')-ne 0)){exit 2};if($state.Present){if(-not$key){$key=$base.CreateSubKey('SOFTWARE\Microsoft\FTH')};$kind=[Microsoft.Win32.RegistryValueKind]::Parse([Microsoft.Win32.RegistryValueKind],[string]$state.Kind);$value=$state.Value;if($kind-eq[Microsoft.Win32.RegistryValueKind]::Binary){$value=[Convert]::FromBase64String([string]$state.Value)}elseif($kind-eq[Microsoft.Win32.RegistryValueKind]::DWord){$value=[uint32]$state.Value}elseif($kind-eq[Microsoft.Win32.RegistryValueKind]::QWord){$value=[uint64]$state.Value}elseif($kind-eq[Microsoft.Win32.RegistryValueKind]::MultiString){$value=@($state.Value)};$key.SetValue('Enabled',$value,$kind)}elseif($key-and$present){$key.DeleteValue('Enabled',$false)};Remove-Item -LiteralPath $f -Force -ErrorAction Stop;exit 0}catch{exit 1}" >nul 2>&1
exit /b !errorlevel!

:REMOVE_COPILOT_HOSTS_BLOCK
call :BACKUP_HOSTS_BEFORE_CHANGE "%SystemRoot%\System32\drivers\etc\hosts"
if !errorlevel! NEQ 0 (
    echo %COLOR_YELLOW%[AVERTISSEMENT]%COLOR_RESET% %COLOR_WHITE%Backup hosts impossible ; le fichier hosts reste inchange.%COLOR_RESET%
    exit /b 1
)
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$h=Join-Path $env:SystemRoot 'System32\drivers\etc\hosts';$item=$null;$attrs=$null;try{if(Test-Path -LiteralPath $h){$item=Get-Item -LiteralPath $h -Force -ErrorAction Stop;$attrs=$item.Attributes;$item.IsReadOnly=$false;$c=[IO.File]::ReadAllText($h);$s='# Copilot Block Start';$e='# Copilot Block End';$n=$c -replace ('(?s)\r?\n?'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)),'';if($n-ne$c){[IO.File]::WriteAllText($h,$n,[Text.Encoding]::ASCII)}};exit 0}catch{exit 1}finally{if($item-ne$null-and $attrs-ne$null){try{$item.Attributes=$attrs}catch{}}}" >nul 2>&1
exit /b !errorlevel!

:DELETE_REG_VALUE_IF_PRESENT
REM Suppression best-effort sans query : une valeur absente est deja dans l'etat voulu.
reg delete "%~1" /v "%~2" /f >nul 2>&1
exit /b 0

:TAKEOWN_RECURSIF
REM Prise de possession recursive ; la lettre de /d depend de la locale du systeme
REM (O = Oui sous Windows francais, Y = Yes sous Windows anglais). Les deux sont tentees.
takeown /f "%~1" /r /d o >nul 2>&1
if errorlevel 1 takeown /f "%~1" /r /d y >nul 2>&1
exit /b 0

:SELECT_CLEANMGR_SAGEID
REM  Choisir un identifiant libre pour ne pas ecraser une configuration cleanmgr existante.
for /l %%N in (1,1,20) do (
    set /a "SAGEID=1000 + ^(!RANDOM! %% 30000^)"
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" /s /f "StateFlags!SAGEID!" >nul 2>&1
    if !errorlevel! NEQ 0 exit /b 0
)
set "SAGEID=65535"
exit /b 0

:SET_NAGLE_PROFILE
powershell -NoLogo -NoProfile -Command "$ack=[int]'%~1'; $noDelay=[int]'%~2'; $delAck=[int]'%~3'; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress }; if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value $ack -Force | Out-Null; New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value $noDelay -Force | Out-Null; New-ItemProperty -Path $p -Name TcpDelAckTicks -PropertyType DWord -Value $delAck -Force | Out-Null } }" >nul 2>&1
exit /b

:RESET_NAGLE_PROFILE
REM Les cles sont absentes par defaut : les supprimer restaure le comportement TCP natif.
powershell -NoLogo -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Remove-ItemProperty -LiteralPath $_.PSPath -Name TcpAckFrequency,TCPNoDelay,TcpDelAckTicks -ErrorAction SilentlyContinue }" >nul 2>&1
exit /b

:SET_POWERCFG_ACDC
set "POWERCFG_ACDC_FAILED=0"
powercfg /setacvalueindex SCHEME_CURRENT %~1 %~2 %~3 >nul 2>&1
if errorlevel 1 set "POWERCFG_ACDC_FAILED=1"
powercfg /setdcvalueindex SCHEME_CURRENT %~1 %~2 %~3 >nul 2>&1
if errorlevel 1 set "POWERCFG_ACDC_FAILED=1"
exit /b !POWERCFG_ACDC_FAILED!

:SELECT_TARGET_POWER_SCHEME
REM Selection silencieuse pour TOUT OPTIMISER. Aucun autre reglage de la section 7 n'est execute ici.
if "%~1"=="1" (
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
    if errorlevel 1 exit /b 1
    exit /b 0
)
set "AIO_TARGET_GUID="
for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do (set "AIO_TARGET_GUID=%%G" & set "AIO_TARGET_GUID=!AIO_TARGET_GUID: =!")
if not defined AIO_TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "99999999-9999-9999-9999-999999999999"') do (set "AIO_TARGET_GUID=%%G" & set "AIO_TARGET_GUID=!AIO_TARGET_GUID: =!")
)
if not defined AIO_TARGET_GUID (
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1
    if errorlevel 1 exit /b 1
    set "AIO_TARGET_GUID=99999999-9999-9999-9999-999999999999"
)
powercfg /setactive !AIO_TARGET_GUID! >nul 2>&1
if errorlevel 1 (
    set "AIO_TARGET_GUID="
    exit /b 1
)
set "AIO_TARGET_GUID="
exit /b 0

:DETECT_VC14_RUNTIME
set "VC2015X86=0"
set "VC2015X64=0"
REM Microsoft enregistre les runtimes v14 dans VC\Runtimes\{x86^|x64}.
REM /reg:32 vise le package x86 et /reg:64 le package x64 sur Windows 64 bits.
REM Attention : Installed=1 peut persister apres desinstallation si Visual Studio
REM avec composant C++ est installe (StackOverflow #67493523). On verifie donc aussi
REM la presence de la DLL principale comme filet de securite.
if defined ProgramFiles(x86) (
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" /v Installed /reg:32 2>nul | findstr /R /I "Installed.*REG_DWORD.*0x1" >nul
    if !errorlevel! EQU 0 if exist "%SystemRoot%\SysWOW64\vcruntime140.dll" set "VC2015X86=1"
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Installed /reg:64 2>nul | findstr /R /I "Installed.*REG_DWORD.*0x1" >nul
    if !errorlevel! EQU 0 if exist "%SystemRoot%\System32\vcruntime140.dll" set "VC2015X64=1"
) else (
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" /v Installed 2>nul | findstr /R /I "Installed.*REG_DWORD.*0x1" >nul
    if !errorlevel! EQU 0 if exist "%SystemRoot%\System32\vcruntime140.dll" set "VC2015X86=1"
    REM Aucun package x64 n'est attendu sur un Windows 32 bits.
    set "VC2015X64=1"
)
exit /b 0

:INSTALL_VC14_REDIST
set "VC_ARCH=%~1"
set "VC_URL=%~2"
set "VC_FILE=%~3"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $f=Join-Path $env:VCREDIST_DIR $env:VC_FILE; Invoke-WebRequest -Uri $env:VC_URL -OutFile $f -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $f).Length -lt 5000000){throw 'size'};$s=Get-AuthenticodeSignature -LiteralPath $f;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft'){throw 'signature'};exit 0 } catch { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de Visual C++ v14 !VC_ARCH!.%COLOR_RESET%
) else (
    start /wait "" "!VCREDIST_DIR!\!VC_FILE!" /q /norestart >nul 2>&1
    set "VC_EXIT=!errorlevel!"
    if "!VC_EXIT!"=="0" (
        echo %COLOR_GREEN%[FAIT]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 !VC_ARCH! installe.%COLOR_RESET%
    ) else if "!VC_EXIT!"=="3010" (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 !VC_ARCH! installe - redemarrage requis.%COLOR_RESET%
    ) else if "!VC_EXIT!"=="1641" (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 !VC_ARCH! installe - redemarrage initie/requis.%COLOR_RESET%
    ) else if "!VC_EXIT!"=="1638" (
        echo %COLOR_CYAN%[IGNORE]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 !VC_ARCH! : une version compatible est deja presente.%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 !VC_ARCH! : code installateur !VC_EXIT!.%COLOR_RESET%
    )
)
set "VC_ARCH="
set "VC_URL="
set "VC_FILE="
exit /b 0

:DETECT_DIRECTX_JUNE2010
set "DX_INSTALLED=0"
REM XAudio2_7 seul ne prouve pas que le redist June 2010 est complet.
REM Tester un noyau de DLL side-by-side dans chaque architecture permet au moins
REM d'eviter de court-circuiter DXSETUP apres une installation manifestement partielle.
set "DX_LEGACY_FILES=XAudio2_7.dll X3DAudio1_7.dll XAPOFX1_5.dll xactengine3_7.dll xinput1_3.dll D3DCompiler_43.dll D3DX9_43.dll D3DX10_43.dll D3DX11_43.dll"
if defined ProgramFiles(x86) (
    set "DX_INSTALLED=1"
    for %%F in (!DX_LEGACY_FILES!) do (
        if not exist "%SystemRoot%\System32\%%F" set "DX_INSTALLED=0"
        if not exist "%SystemRoot%\SysWOW64\%%F" set "DX_INSTALLED=0"
    )
) else (
    set "DX_INSTALLED=1"
    for %%F in (!DX_LEGACY_FILES!) do if not exist "%SystemRoot%\System32\%%F" set "DX_INSTALLED=0"
)
set "DX_LEGACY_FILES="
exit /b 0

:INSTALL_STR_BINARY
set "STR_TMP=%STR_DIR%\SetTimerResolution.exe.download"
set "STR_DOWNLOAD_URL=%WINOPT_RELEASE_BASE_URL%/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe"
if exist "%STR_TMP%" del /f /q "%STR_TMP%" >nul 2>&1
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$src=Join-Path $env:WINOPT_SOURCE_DIR 'Tools\Timer & Interrupt\SetTimerResolution.exe';if([IO.File]::Exists($src)){Copy-Item -LiteralPath $src -Destination $env:STR_TMP -Force;exit 0};exit 1}catch{exit 1}" >nul 2>&1
call :VALIDATE_STR_BINARY
if !errorlevel! EQU 0 goto :INSTALL_STR_COMMIT
if exist "%STR_TMP%" del /f /q "%STR_TMP%" >nul 2>&1
where curl.exe >nul 2>&1
if !errorlevel! NEQ 0 goto :INSTALL_STR_BITS
curl.exe --fail --location --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 45 --silent --show-error --output "%STR_TMP%" "%STR_DOWNLOAD_URL%"
call :VALIDATE_STR_BINARY
if !errorlevel! EQU 0 goto :INSTALL_STR_COMMIT
if exist "%STR_TMP%" del /f /q "%STR_TMP%" >nul 2>&1
:INSTALL_STR_BITS
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{Import-Module BitsTransfer -ErrorAction Stop;Start-BitsTransfer -Source $env:STR_DOWNLOAD_URL -Destination $env:STR_TMP -Priority Foreground -RetryInterval 60 -RetryTimeout 60 -ErrorAction Stop;exit 0}catch{Write-Host ('BITS: '+$_.Exception.Message);exit 1}"
call :VALIDATE_STR_BINARY
if !errorlevel! EQU 0 goto :INSTALL_STR_COMMIT
if exist "%STR_TMP%" del /f /q "%STR_TMP%" >nul 2>&1
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;Invoke-WebRequest -Uri $env:STR_DOWNLOAD_URL -OutFile $env:STR_TMP -UseBasicParsing -TimeoutSec 45 -ErrorAction Stop;exit 0}catch{Write-Host ('PowerShell: '+$_.Exception.Message);exit 1}"
call :VALIDATE_STR_BINARY
if !errorlevel! EQU 0 goto :INSTALL_STR_COMMIT
:INSTALL_STR_FAILURE
if exist "%STR_TMP%" del /f /q "%STR_TMP%" >nul 2>&1
if exist "%STR_DIR%" rmdir "%STR_DIR%" >nul 2>&1
echo [ERREUR] SetTimerResolution : telechargement impossible avec curl, BITS et PowerShell.
set "STR_TMP="
set "STR_DOWNLOAD_URL="
exit /b 1
:INSTALL_STR_COMMIT
move /Y "%STR_TMP%" "%STR_EXE%" >nul 2>&1
if not exist "%STR_EXE%" goto :INSTALL_STR_FAILURE
set "STR_TMP="
set "STR_DOWNLOAD_URL="
exit /b 0

:VALIDATE_STR_BINARY
if not exist "%STR_TMP%" exit /b 1
for %%A in ("%STR_TMP%") do if %%~zA LSS 10000 exit /b 1
powershell -NoProfile -Command "$p=$env:STR_TMP;try{$b=[IO.File]::ReadAllBytes($p);if($b.Length -lt 10000 -or $b[0] -ne 77 -or $b[1] -ne 90){exit 1};$o=[BitConverter]::ToInt32($b,60);if($o -lt 64 -or $o+4 -gt $b.Length -or $b[$o] -ne 80 -or $b[$o+1] -ne 69 -or $b[$o+2] -ne 0 -or $b[$o+3] -ne 0){exit 1};exit 0}catch{exit 1}" >nul 2>&1
exit /b !errorlevel!

:CREATE_STR_STARTUP_SHORTCUT
powershell -NoProfile -Command "$ErrorActionPreference='Stop';try{$d=Split-Path -Parent $env:STR_STARTUP_LNK;New-Item -ItemType Directory -Path $d -Force|Out-Null;$w=New-Object -ComObject WScript.Shell;$s=$w.CreateShortcut($env:STR_STARTUP_LNK);$s.TargetPath=$env:STR_EXE;$s.Arguments='--resolution 5070 --no-console';$s.WorkingDirectory=$env:STR_DIR;$s.Description='SetTimerResolution - WindowsOptimizer';$s.Save();$v=$w.CreateShortcut($env:STR_STARTUP_LNK);if(-not (Test-Path -LiteralPath $env:STR_STARTUP_LNK) -or $v.TargetPath -ne $env:STR_EXE -or $v.Arguments -ne '--resolution 5070 --no-console'){exit 1};exit 0}catch{exit 1}" >nul 2>&1
exit /b !errorlevel!

:REMOVE_STR_AUTOSTART_TASK
set "STR_TASK_NAME=WindowsOptimizer SetTimerResolution"
powershell -NoProfile -Command "Unregister-ScheduledTask -TaskName $env:STR_TASK_NAME -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
set "STR_TASK_NAME="
exit /b 0

:RUN_EDGE_UNINSTALLER
pushd "%~1" >nul 2>&1
if !errorlevel! NEQ 0 exit /b 1
for /d %%i in (*) do (
    if exist "%%i\Installer\setup.exe" (
        set "EDGE_UNINSTALLER_FOUND=1"
        "%%i\Installer\setup.exe" --uninstall --system-level --force-uninstall >nul 2>&1
    )
)
popd >nul 2>&1
exit /b 0

:REMOVE_EDGE_TASKBAR_LINKS
powershell -NoProfile -Command "Get-ChildItem -Path (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk') -ErrorAction SilentlyContinue | ForEach-Object { try { $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName); if ($sh.TargetPath -match 'msedge\.exe') { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue } } catch {} }" >nul 2>&1
exit /b

:SET_EXISTING_SERVICE_START
REM  %~1 = nom du service ; %~2 = valeur Start. Une cle absente est ignoree, jamais creee.
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1
if !errorlevel! NEQ 0 (
    set /a "SERVICE_CONFIG_SKIPPED+=1"
    exit /b 0
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start /t REG_DWORD /d %~2 /f >nul 2>&1
exit /b 0

:SET_DEVICE_MSI_PROFILE
REM  %~1 = classe PnP (Display, Net ou USB) ; %~2 = PROFIL_USAGE (0=Gaming, 1=Normal).
REM  Gaming capture l'etat exact de chaque peripherique avant sa premiere modification,
REM  y compris ceux ajoutes entre deux executions, puis demande MSI=1.
REM  Normal restaure valeur, type et absence par peripherique. Sans sauvegarde, il ne
REM  supprime rien : plusieurs pilotes de cette installation stock portent deja MSI=1.
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$class='%~1';$gaming=('%~2'-eq'0');$dir=Join-Path $env:ProgramData 'WindowsOptimizer';$file=Join-Path $dir ('msi_'+$class+'_baseline.clixml');$devices=@(Get-PnpDevice -Class $class -ErrorAction Stop);if($gaming){New-Item -ItemType Directory -Path $dir -Force|Out-Null;$items=if(Test-Path -LiteralPath $file){@(Import-Clixml -LiteralPath $file)}else{@()};$known=@{};foreach($item in $items){$known[[string]$item.Path]=$true};foreach($d in $devices){$p='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$d.InstanceId+'\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties';if(-not(Test-Path -LiteralPath $p)-or$known.ContainsKey($p)){continue};$k=Get-Item -LiteralPath $p;$present=$k.GetValueNames()-contains'MSISupported';$items+=[pscustomobject]@{Path=$p;Present=$present;Kind=if($present){[string]$k.GetValueKind('MSISupported')}else{$null};Value=if($present){$k.GetValue('MSISupported',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}else{$null}};$known[$p]=$true};$items|Export-Clixml -LiteralPath $file -Force;foreach($d in $devices){$p='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$d.InstanceId+'\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties';if(Test-Path -LiteralPath $p){New-ItemProperty -LiteralPath $p -Name MSISupported -PropertyType DWord -Value 1 -Force|Out-Null}};exit 0};if(-not(Test-Path -LiteralPath $file)){exit 0};$items=@(Import-Clixml -LiteralPath $file);foreach($item in $items){if(-not(Test-Path -LiteralPath $item.Path)){continue};if($item.Present){$k=Get-Item -LiteralPath $item.Path;$kind=[Microsoft.Win32.RegistryValueKind]$item.Kind;$k.SetValue('MSISupported',$item.Value,$kind)}else{Remove-ItemProperty -LiteralPath $item.Path -Name MSISupported -ErrorAction SilentlyContinue}};Remove-Item -LiteralPath $file -Force;exit 0" >nul 2>&1
exit /b !errorlevel!

REM  Parametres : %~1 = PROFIL_POWER (0=MaxPerf, 1=Eco).
REM               %~2 = PROFIL_USAGE (0=Gaming, 1=Normal).
REM  Gaming+MaxPerf (0,0) : RSC/LSO OFF, InterruptModeration ON, delais pilote au minimum annonce, EEE/Wake OFF.
REM  Normal+MaxPerf (0,1) : RSC/LSO et InterruptModeration ON, ITR defaut, PowerManagement pilote au stock (1/1/1).
REM  Eco (1,*) : RSC/LSO/checksum et InterruptModeration ON, PowerManagement ON, economie pilote conservee.
REM  ARP/NS Offload : OFF en Gaming+MaxPerf, ON en Normal et Eco. WakeOnPattern : OFF sauf Normal (stock mesure 1/1/1).
REM  Toutes les modifications sont groupees avant un unique redemarrage de chaque carte.
REM  Source unique de verite pour la section 5.7 et la convergence reseau manuelle de la section 7.
:SET_NIC_PROFILE
REM Ne supprime pas de proprietes driver non gerees : elles peuvent etre stock OEM.
REM  Realtek : conserver les overrides cibles InterruptModerationLevel=0 (Low)
REM  et IntMitiInterval=0. Ne pas reutiliser l'ancien ITR=200 non declare par le pilote.
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$gaming=('%~1'-eq'0'-and'%~2'-eq'0');$adapters=@(Get-NetAdapter -Physical|Where-Object{$_.AdminStatus-eq'Up'-and$_.PnPDeviceID-match'^PCI\\VEN_10EC&'});foreach($a in $adapters){$w=Get-CimInstance Win32_NetworkAdapter|Where-Object{$_.PNPDeviceID-eq$a.PnPDeviceID}|Select-Object -First 1;if(-not$w){continue};$k='{0:0000}'-f[int]$w.DeviceID;$r='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'+$k;if($gaming){Remove-ItemProperty -LiteralPath $r -Name 'ITR','TxIntDelay' -ErrorAction SilentlyContinue;New-ItemProperty -LiteralPath $r -Name 'IntMitiInterval' -PropertyType DWord -Value 0 -Force|Out-Null;New-ItemProperty -LiteralPath $r -Name 'InterruptModerationLevel' -PropertyType String -Value '0' -Force|Out-Null}else{Remove-ItemProperty -LiteralPath $r -Name 'ITR','TxIntDelay','IntMitiInterval','InterruptModerationLevel' -ErrorAction SilentlyContinue}};exit 0" >nul 2>&1
if !errorlevel! NEQ 0 exit /b 1
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue';$eco=('%~1'-eq'1');$gaming=('%~1'-eq'0'-and'%~2'-eq'0');$script:failed=$false;$managed=@('*FlowControl','*GreenGbe','*RscIPv6','*PacketCoalescing','EnableExtraPowerSaving','*EEE','AdvancedEEE','EnableGreenEthernet','PowerSavingMode','GigaLite','ReduceSpeedOnPowerDown','*WakeOnMagicPacket','S5WakeOnLan','*ShutdownLinkSpeed','S3S4WolLinkSpeed','EnableDynamicPowerGating','AutoPowerSaveModeEnabled','EnableConnectedPowerGating','*NicAutoPowerSaver','TxIntDelay','MIMOPowerSaveMode','uAPSDSupport','FatChannelIntolerant','*ReceiveBuffers','*TransmitBuffers','PendingReceives','PendingTransmits','ITR','*InterruptModeration');function SetP($a,$kw,$vals,$cache){if(-not $cache.ContainsKey($kw)){return};$p=$cache[$kw];$ok=$false;foreach($v in $vals){$valid=@($p.ValidRegistryValues);if($null-ne$p.ValidRegistryValues-and $valid.Count-gt 0-and $valid-notcontains[string]$v){continue};try{Set-NetAdapterAdvancedProperty -Name $a -RegistryKeyword $kw -RegistryValue $v -AllProperties -NoRestart -ErrorAction Stop;$script:changed=$true;$ok=$true;break}catch{}};if(-not $ok){$script:failed=$true}};function SetMinP($a,$kw,$cache){$p=$cache[$kw];if(-not $p){return};$nums=@();if($null-ne$p.NumericParameterMinValue-and $p.NumericParameterMaxValue-gt 0){$nums+=[int]$p.NumericParameterMinValue};$nums+=@($p.ValidRegistryValues|Where-Object{[string]$_-match'^\d+$'}|ForEach-Object{[int]$_});if($nums.Count){$v=(($nums|Measure-Object -Minimum).Minimum).ToString();SetP $a $kw @($v) $cache}};function ResetP($a,$kw,$cache){$p=$cache[$kw];if(-not $p){return};try{if($p.DisplayName){$p|Reset-NetAdapterAdvancedProperty -NoRestart -ErrorAction Stop}else{$d=@($p.DefaultRegistryValue);if($d.Count-eq 0-or $null-eq $d[0]){return};Set-NetAdapterAdvancedProperty -Name $a -RegistryKeyword $kw -RegistryValue $d -AllProperties -NoRestart -ErrorAction Stop};$script:changed=$true}catch{$script:failed=$true}};function SetF($get,$set,$n){$f=& $get -Name $n -ErrorAction SilentlyContinue;if($null-eq$f){return};try{& $set -Name $n -NoRestart -ErrorAction Stop;$script:changed=$true}catch{$script:failed=$true}};function SetPMFlags($n,$r,$cache,$ecoMode,$gamingMode){$pm=$null;try{$pm=Get-NetAdapterPowerManagement -Name $n -ErrorAction Stop}catch{};$map=[ordered]@{'ArpOffload'='*PMARPOffload';'NSOffload'='*PMNSOffload';'WakeOnPattern'='*WakeOnPattern';'SelectiveSuspend'='*SelectiveSuspend'};foreach($item in $map.GetEnumerator()){$param=$item.Key;$kw=$item.Value;$ndi=$null;if($r){$ndi=$r+'\Ndi\Params\'+$kw};$state=$null;if($pm){$state=$pm.PSObject.Properties[$param].Value};$supported=$cache.ContainsKey($kw)-or($ndi-and(Test-Path -LiteralPath $ndi))-or($state-and([string]$state-ne'Unsupported'));if(-not $supported){continue};$desired=if($gamingMode){'Disabled'}elseif($ecoMode-and $param-eq'WakeOnPattern'){'Disabled'}else{'Enabled'};$target=if($desired-eq'Enabled'){'1'}else{'0'};$ok=$false;$args=@{Name=$n;NoRestart=$true;ErrorAction='Stop'};$args[$param]=$desired;try{Set-NetAdapterPowerManagement @args;$ok=$true;$script:changed=$true}catch{};if($ndi-and(Test-Path -LiteralPath $ndi)){$v=$null;try{$v=Get-ItemPropertyValue -LiteralPath $r -Name $kw -ErrorAction Stop}catch{};if([string]$v-ne$target){try{New-ItemProperty -LiteralPath $r -Name $kw -PropertyType String -Value $target -Force -ErrorAction Stop|Out-Null;$v=Get-ItemPropertyValue -LiteralPath $r -Name $kw -ErrorAction Stop;$ok=([string]$v-eq$target);$script:changed=$true}catch{$ok=$false}}else{$ok=$true}};if(-not $ok){$script:failed=$true}}};try{$adapters=@(Get-NetAdapter -Physical -ErrorAction Stop|Where-Object{$_.AdminStatus-eq'Up'})}catch{exit 1};foreach($adapter in $adapters){$script:changed=$false;$n=$adapter.Name;$props=@{};try{Get-NetAdapterAdvancedProperty -Name $n -AllProperties -ErrorAction Stop|ForEach-Object{if($_.RegistryKeyword){$props[$_.RegistryKeyword]=$_}}}catch{$script:failed=$true};$w=Get-CimInstance Win32_NetworkAdapter -ErrorAction SilentlyContinue|Where-Object{$_.PNPDeviceID-eq$adapter.PnPDeviceID}|Select-Object -First 1;$r=$null;if($w){$k='{0:0000}'-f[int]$w.DeviceID;$r='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'+$k};if($eco){foreach($kw in $managed){ResetP $n $kw $props}}elseif(-not $gaming){foreach($kw in @('*RscIPv6','ITR','TxIntDelay','*InterruptModeration')){ResetP $n $kw $props}};if(($eco-or(-not $gaming))-and $r){Remove-ItemProperty -Path $r -Name 'ITR','TxIntDelay' -ErrorAction SilentlyContinue;$script:changed=$true};SetF 'Get-NetAdapterRss' 'Enable-NetAdapterRss' $n;if($eco-or(-not $gaming)){SetF 'Get-NetAdapterRsc' 'Enable-NetAdapterRsc' $n;SetF 'Get-NetAdapterLso' 'Enable-NetAdapterLso' $n}else{SetF 'Get-NetAdapterRsc' 'Disable-NetAdapterRsc' $n;SetF 'Get-NetAdapterLso' 'Disable-NetAdapterLso' $n};foreach($kw in @('*IPChecksumOffloadIPv4','*TCPChecksumOffloadIPv4','*TCPChecksumOffloadIPv6','*UDPChecksumOffloadIPv4','*UDPChecksumOffloadIPv6')){SetP $n $kw @('3') $props};if($eco){SetF 'Get-NetAdapterPowerManagement' 'Enable-NetAdapterPowerManagement' $n}elseif($gaming){SetF 'Get-NetAdapterPowerManagement' 'Disable-NetAdapterPowerManagement' $n;foreach($kw in @('*FlowControl','*GreenGbe','*PacketCoalescing','EnableExtraPowerSaving','*EEE','AdvancedEEE','EnableGreenEthernet','PowerSavingMode','GigaLite','ReduceSpeedOnPowerDown','*WakeOnMagicPacket','S5WakeOnLan','*ShutdownLinkSpeed','S3S4WolLinkSpeed','EnableDynamicPowerGating','AutoPowerSaveModeEnabled','EnableConnectedPowerGating','*NicAutoPowerSaver')){SetP $n $kw @('0') $props};SetP $n '*RscIPv6' @('0') $props;SetP $n '*InterruptModeration' @('1') $props;if($r){foreach($kw in @('ITR','TxIntDelay')){if(-not(Test-Path -LiteralPath ($r+'\Ndi\Params\'+$kw))){Remove-ItemProperty -LiteralPath $r -Name $kw -ErrorAction SilentlyContinue;$props.Remove($kw)|Out-Null;$script:changed=$true}}};foreach($kw in @('ITR','*InterruptModerationRate','InterruptModerationRate','RxIntDelay','TxIntDelay')){SetMinP $n $kw $props};if($adapter.InterfaceDescription-match'Intel|Wireless|Wi-Fi|802\.11'){SetP $n 'MIMOPowerSaveMode' @('3') $props;SetP $n 'uAPSDSupport' @('0') $props;SetP $n 'FatChannelIntolerant' @('0') $props};foreach($kw in @('*ReceiveBuffers','*TransmitBuffers')){$p=$props[$kw];if($p-and $p.NumericParameterMaxValue-gt 0){$v=[math]::Min([int]$p.NumericParameterMaxValue,2048).ToString();SetP $n $kw @($v) $props}};foreach($kw in @('PendingReceives','PendingTransmits')){$p=$props[$kw];if($p-and $p.NumericParameterMaxValue-gt 0){$v=[math]::Min([int]$p.NumericParameterMaxValue,64).ToString();SetP $n $kw @($v) $props}}}else{foreach($kw in @('*FlowControl','*GreenGbe','*PacketCoalescing','EnableExtraPowerSaving','*EEE','AdvancedEEE','EnableGreenEthernet','PowerSavingMode','GigaLite','ReduceSpeedOnPowerDown','*WakeOnMagicPacket','S5WakeOnLan','*ShutdownLinkSpeed','S3S4WolLinkSpeed','EnableDynamicPowerGating','AutoPowerSaveModeEnabled','EnableConnectedPowerGating','*NicAutoPowerSaver')){ResetP $n $kw $props}};SetP $n '*InterruptModeration' @('1') $props;SetPMFlags $n $r $props $eco $gaming;if($script:changed){try{Restart-NetAdapter -Name $n -Confirm:$false -ErrorAction Stop}catch{$script:failed=$true}}};if($script:failed){exit 1};exit 0" >nul 2>&1
exit /b !errorlevel!

:SET_NIC_PROFILE_CONVERGENCE
REM Passe de convergence : inclut les cartes physiques deconnectees/desactivees.
REM Les commandes qui exigent une interface active sont sautees pour ne pas la reveiller ;
REM les valeurs persistantes du pilote restent toutefois alignees avec le profil cible.
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$eco=('%~1'-eq'1');$gaming=('%~1'-eq'0'-and'%~2'-eq'0');$script:failed=$false;try{$adapters=@(Get-NetAdapter -Physical -ErrorAction Stop)}catch{exit 1};foreach($a in $adapters){$up=($a.AdminStatus-eq'Up');$props=@{};try{Get-NetAdapterAdvancedProperty -Name $a.Name -AllProperties -ErrorAction Stop|ForEach-Object{if($_.RegistryKeyword){$props[$_.RegistryKeyword]=$_}}}catch{$script:failed=$true};function SetP($kw,$val){$p=$props[$kw];if(-not$p){return};$valid=@($p.ValidRegistryValues);if($null-ne$p.ValidRegistryValues-and$valid.Count-gt 0-and$valid-notcontains[string]$val){return};try{Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue $val -AllProperties -NoRestart -ErrorAction Stop}catch{$script:failed=$true}};function ResetP($kw){$p=$props[$kw];if(-not$p){return};try{if($p.DisplayName){$p|Reset-NetAdapterAdvancedProperty -NoRestart -ErrorAction Stop}elseif($null-ne$p.DefaultRegistryValue){Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue $p.DefaultRegistryValue -AllProperties -NoRestart -ErrorAction Stop}}catch{$script:failed=$true}};if($eco-or-not$gaming){foreach($kw in @('*RscIPv6','ITR','TxIntDelay','*InterruptModerationRate','InterruptModerationRate','RxIntDelay')){ResetP $kw}};if($eco-or-not$gaming){ResetP '*FlowControl'}else{SetP '*FlowControl' '0'};SetP '*InterruptModeration' '1';$w=Get-CimInstance Win32_NetworkAdapter -ErrorAction SilentlyContinue|Where-Object{$_.PNPDeviceID-eq$a.PnPDeviceID}|Select-Object -First 1;$r=$null;if($w){$k='{0:0000}'-f[int]$w.DeviceID;$r='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'+$k};if($a.PnPDeviceID-match'^PCI\\VEN_10EC&'-and$r){if($gaming){Remove-ItemProperty -LiteralPath $r -Name 'ITR','TxIntDelay' -ErrorAction SilentlyContinue;New-ItemProperty -LiteralPath $r -Name 'IntMitiInterval' -PropertyType DWord -Value 0 -Force|Out-Null;New-ItemProperty -LiteralPath $r -Name 'InterruptModerationLevel' -PropertyType String -Value '0' -Force|Out-Null}else{Remove-ItemProperty -LiteralPath $r -Name 'ITR','TxIntDelay','IntMitiInterval','InterruptModerationLevel' -ErrorAction SilentlyContinue}};if($r){$arpNs=if($gaming){'0'}else{'1'};foreach($name in @('*PMARPOffload','*PMNSOffload','*WakeOnPattern')){$ndi=$r+'\Ndi\Params\'+$name;if(Test-Path -LiteralPath $ndi){$value=if($name-eq'*WakeOnPattern'){if($eco-or$gaming){'0'}else{'1'}}else{$arpNs};New-ItemProperty -LiteralPath $r -Name $name -PropertyType String -Value $value -Force|Out-Null}}};if($up){if($eco-or-not$gaming){Enable-NetAdapterRsc -Name $a.Name -NoRestart -ErrorAction SilentlyContinue;Enable-NetAdapterLso -Name $a.Name -NoRestart -ErrorAction SilentlyContinue}else{Disable-NetAdapterRsc -Name $a.Name -NoRestart -ErrorAction SilentlyContinue;Disable-NetAdapterLso -Name $a.Name -NoRestart -ErrorAction SilentlyContinue};$args=@{Name=$a.Name;NoRestart=$true;ErrorAction='SilentlyContinue'};if($eco){$args['ArpOffload']='Enabled';$args['NSOffload']='Enabled';$args['WakeOnPattern']='Disabled'}elseif($gaming){$args['ArpOffload']='Disabled';$args['NSOffload']='Disabled';$args['WakeOnPattern']='Disabled'}else{$args['ArpOffload']='Enabled';$args['NSOffload']='Enabled';$args['WakeOnPattern']='Enabled'};Set-NetAdapterPowerManagement @args}};if($script:failed){exit 1};exit 0" >nul 2>&1
exit /b !errorlevel!

REM  Parametre : %~1 = PROFIL_POWER (0=MaxPerf, 1=Eco).
REM              %~2 = 1 pour laisser la section appelante activer le plan une seule fois.
REM  MaxPerf (0) : desactive la gestion d'energie USB (WMI "Autoriser l'arret",
REM    USB Selective Suspend, USB 3 LPM, DisableSelectiveSuspend).
REM  Eco (1) : restaure la gestion d'energie USB (annule les surcharges MaxPerf).
REM  Source unique pour la section 5.8 et les branches USB MaxPerf/Eco de la section 7.
:SET_USB_POWER
if "%~1"=="1" (
    REM Eco : restaurer la gestion d'energie USB - desactive les surcharges MaxPerf
    powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $usb=(Get-PNPDevice -Class USB -ErrorAction SilentlyContinue).InstanceId; Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -Filter 'Enable=false' -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -replace '_0$' -in $usb } | Set-CimInstance -Property @{Enable = $true} -ErrorAction SilentlyContinue" >nul 2>&1
    call :SET_POWERCFG_ACDC 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
    call :SET_POWERCFG_ACDC 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 2
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f >nul 2>&1
    if "%~2"=="1" exit /b 0
    powercfg /setactive SCHEME_CURRENT >nul 2>&1
    exit /b 0
)
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $usb=(Get-PNPDevice -Class USB -ErrorAction SilentlyContinue).InstanceId; Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -Filter 'Enable=true' -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -replace '_0$' -in $usb } | Set-CimInstance -Property @{Enable = $false} -ErrorAction SilentlyContinue" >nul 2>&1
call :SET_POWERCFG_ACDC 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
call :SET_POWERCFG_ACDC 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
if "%~2"=="1" exit /b 0
powercfg /setactive SCHEME_CURRENT >nul 2>&1
exit /b 0

:RUN_REMOTE_PS
set "REMOTE_PS_PROVIDER="
if /i "%~1"=="https://get.activated.win" set "REMOTE_PS_PROVIDER=Microsoft Activation Scripts (MAS)"
if /i "%~1"=="https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1" set "REMOTE_PS_PROVIDER=Chris Titus Tech WinUtil"
if not defined REMOTE_PS_PROVIDER (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Source distante non autorisee ou non identifiee.%COLOR_RESET%
    exit /b 1
)
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Source distante autorisee : !REMOTE_PS_PROVIDER!.%COLOR_RESET%
set "REMOTE_PS_FILE=%TEMP%\WindowsOptimizer_remote_%RANDOM%_%RANDOM%.ps1"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%~1' -OutFile $env:REMOTE_PS_FILE -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $env:REMOTE_PS_FILE).Length -lt 500){exit 2}; $sig=Get-AuthenticodeSignature -LiteralPath $env:REMOTE_PS_FILE; if($sig.SignerCertificate -and $sig.Status.ToString() -ne 'Valid'){exit 4}; $fs=[IO.File]::OpenRead($env:REMOTE_PS_FILE); $b=New-Object byte[] 256; $n=$fs.Read($b,0,256); $fs.Close(); $head=([Text.Encoding]::ASCII.GetString($b,0,$n)).TrimStart(); if($head.StartsWith('<html') -or $head.StartsWith('<?xml') -or ($head.Length -gt 1 -and $head[0] -eq [char]60 -and $head[1] -eq [char]33)){exit 3}; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    if exist "%REMOTE_PS_FILE%" del /f /q "%REMOTE_PS_FILE%" >nul 2>&1
    set "REMOTE_PS_FILE="
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%REMOTE_PS_FILE%"
set "REMOTE_PS_RC=!errorlevel!"
del /f /q "%REMOTE_PS_FILE%" >nul 2>&1
set "REMOTE_PS_FILE="
if "!REMOTE_PS_RC!"=="0" (
    set "REMOTE_PS_RC="
    set "REMOTE_PS_PROVIDER="
    exit /b 0
)
set "REMOTE_PS_RC="
set "REMOTE_PS_PROVIDER="
exit /b 1
