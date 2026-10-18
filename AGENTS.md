# WindowsOptimizer

Optimiseur Windows 11 tenu en **trois fichiers** : `All in One.cmd` (un batch unique de plusieurs milliers de lignes, ASCII strict, fins de ligne CRLF), `launcher.ps1` (telechargement et elevation) et `README.md` (page utilisateur et contrat de publication). Le reste (`Tools/`, `Game Configs/`, `LICENSE`, `.gitattributes`, `.gitignore`) n'est que ressources et metadonnees.

Langue : tout est en francais (observe : README avec accents ; ce fichier et le batch en ASCII sans accent). Le README s'adresse aux utilisateurs ; les regles pour agents vivent ici.

**Mesure, gain, duree, resultat de VM ou du PC de jeu** : lire d'abord `~/projects/winopt-bench/AGENTS.md` avant de citer ou de produire une preuve. Il exclut `pc-gaming` de toute connexion jusqu'a demande explicite, impose un seul operateur par VM, et pose qu'un resultat VM prouve la mecanique, jamais un gain en jeu.

## Verification

Ce projet n'a pas de suite de tests : les controles ci-dessous en tiennent lieu. Les executer avant de conclure.

Sur hp-dev, depuis la racine du worktree, le controle statique seul est disponible sans SSH ni commande VM :

```bash
REPO="$PWD" ~/vms/winopt-lab/check.sh --local
```

Il verifie ASCII/CRLF et la structure du batch (labels, cibles et parentheses). Cette preuve partielle ne valide ni PowerShell, ni le launcher, ni une execution dans Windows invite ; les controles correspondants ci-dessous restent necessaires.

**Contrat de format.** Sur la copie de travail, ASCII 7 bits et CRLF : la commande doit retourner `0`.

```powershell
powershell -NoProfile -Command "try{$b=[IO.File]::ReadAllBytes('All in One.cmd');for($i=0;$i-lt$b.Length;$i++){if($b[$i]-eq0-or$b[$i]-gt127){exit 44};if(($b[$i]-eq10-and($i-eq0-or$b[$i-1]-ne13))-or($b[$i]-eq13-and($i+1-ge$b.Length-or$b[$i+1]-ne10))){exit 42}};exit 0}catch{exit 43}"
```

`44` = octet non ASCII, `42` = ligne LF, `43` = fichier illisible. Ecrire les commentaires du batch en ASCII, sans accent ni guillemet typographique : l'echec n'apparait qu'a la lecture par le visiteur, une fois publie.

**Le `42` sur la copie publiee est normal : ne pas le "corriger".** `.gitattributes` impose `*.cmd text eol=crlf`, donc git stocke le batch en LF et `raw.githubusercontent.com` sert ce LF. Le batch le detecte, le recopie en CRLF dans `%TEMP%` puis se relance ; les deux chemins sont testes. Forcer du CRLF dans `.gitattributes` casserait la publication. Seul le `44` est un refus reel, sans reparation.

Cette commande duplique celle du batch, qui se parametre par `%WINOPT_SELF%` et se tait avec `>nul 2>&1` pour rester copiable ici. Si l'une des deux evolue, mettre les deux a jour dans le meme commit.

**Launcher**, sur la copie publiee, dans un dossier temporaire contenant `launcher.ps1` seul :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher.ps1 -VerifyOnly
```

Ne lance rien, affiche la source et le SHA-256 informatif (le launcher n'epingle aucun SHA). Tester la copie locale et la copie distante separement.

Apres une edition de structure (label, `goto`, bloc `if`), verifier que chaque `goto` et chaque `call :` pointe vers un label existant, que la profondeur de parentheses est **nulle a chaque label** et que les blocs `if/else` se ferment. L'equilibre global ne prouve rien : un `)` orphelin peut etre compense ailleurs.

## Regles du projet

- Le README fait partie du contrat : garder le code, la documentation et la publication alignes. Tout chiffre annonce dans le README se mesure sur le code ou sur une reponse HTTP, jamais a l'estime (methodes : section Chiffres).
- `All in One.cmd` est volontairement un script unique, dense et portable. Preserve ce choix : pas de sur-ingenierie, de couches inutiles ni de multiplication de fichiers. Le fichier se parcourt par label, jamais par numero de ligne.
- Windows 11 est la seule cible prise en charge et le seul critere courant de validation. Les chemins Windows 10 herites ne promettent aucune compatibilite. La VM ne couvre pas : un portable, du vrai materiel GPU et reseau, la desactivation effective de Defender, MAS et WinUtil.
- Une restauration "par defaut" restaure un etat capture ou applique un fallback Windows documente. Supprimer une valeur n'est pas toujours l'inverse correct.
- Pour les tweaks Windows, faire une recherche Web recente et croiser les sources : la documentation Microsoft peut etre incomplete, imprecise, ancienne ou trop prudente. Comprendre le mecanisme reel, puis confronter documentation, forums techniques, tests reproductibles et retours terrain. Les sources d'un reglage vont dans le commentaire du batch ou dans la section Sources, jamais dans le README.
- Ne pas changer une valeur ni un axe de l'auteur sans le lui signaler, meme quand la logique interne du script plaide pour l'autre choix.

## Publication

`main` est la branche de publication : les utilisateurs et le launcher en lisent directement les fichiers bruts.

- Chemins publics, a ne pas renommer ni deplacer sans version coordonnee batch + launcher + README : `launcher.ps1` (commande du README), `All in One.cmd` (telecharge par le launcher), `Tools/Timer & Interrupt/SetTimerResolution.exe`, `Tools/NVIDIA Inspector/nvidiaProfileInspector.exe` et `Kaylers_profile.nip` (repli du batch par `WINOPT_RELEASE_BASE_URL`). Les batchs deja distribues appellent ces URL et le raw GitHub ne redirige pas. Apres tout changement de chemin, `curl -sI` sur l'ancienne et la nouvelle URL.
- `Game Configs/`, `LICENSE` et `.gitignore` peuvent bouger sans effet sur une URL.
- Sans appelant dans le batch ni le launcher (a ne pas supposer mort sans l'accord de l'auteur) : `Game Configs/Fortnite/`, `Tools/O&O ShutUp10/ooshutup10_kayler.cfg`, `GoInterruptPolicy.exe` et `MeasureSleep.exe`. Le profil Valorant execute est le bloc embarque du batch (`::VALPS`), pas `Game Configs/Valorant/` : modifier l'un sans l'autre les fait diverger.
- Les binaires de `Tools/` n'ont pas de fichier de provenance (source, version, licence non documentees).

## Chiffres

Methodes pour remesurer un chiffre cite (README ou autre) des que le code change, depuis la racine du depot, sous bash (`f="All in One.cmd"`). Le fichier de travail est en CRLF : retirer le `\r` (`tr -d '\r'`) avant tout motif ancre sur une fin de ligne. Aucune valeur n'est conservee ici : elle date vite, et Git garde l'historique. `winopt-bench` mesure des experiences, pas la structure du batch : ces methodes restent donc ici.

- **Version minimale Visual C++, resolution SetTimerResolution, seuil de RAM de la compression memoire** : `grep -n 'Version minimale' "$f"`, `grep -n '5275' "$f"`, `grep -n 'RAM depasse' "$f"`.
- **Etapes du nettoyage avance** : `grep -c 'set /a "CLEAN_STEP+=1"' "$f"` et `grep -oE 'CLEAN_TOTAL=[0-9]+' "$f"` doivent donner le meme nombre.
- **Invocations PowerShell** (indicateur de lenteur en VM), hors commentaires `REM`/`::`, sans tenir compte de la casse : `grep -viE '^\s*(@?rem|::)(\s|$)' "$f" | grep -oiE 'powershell(\.exe)?"? +-' | wc -l`. Une invocation dans une boucle ou un helper compte une fois ; un `where powershell` ou un `echo` qui cite PowerShell n'en est pas une. Un chiffre releve avec un filtre sensible a la casse (`grep -vE`) n'est pas comparable.
- **Ecritures de registre de vie privee, sections 1.4 et 1.5** (de `REM  1.4 - ` a `REM  1.6 - `) : `sed -n '/^REM  1.4 - /,/^REM  1.6 - /p' "$f" | grep '^\s*reg add' | grep -v Autologger | grep -vc 'ContentDeliveryManager" /v %%V'`, plus les valeurs de la boucle Content Delivery Manager (meme plage, `grep -E '^for %%V in \('`, liste passee a `wc -w`). Autologgers WMI : noms de la boucle `for %%L in (` plus `grep -oE 'Autologger\\[A-Za-z]+"'` sur la meme plage, sans doublon.
- **Taches planifiees desactivees** : `tr -d '\r' < "$f" | sed -n '/^for %%T in ($/,/^) do set "WINOPT_TELEMETRY_TASKS/p' | grep -c '^\s*"Microsoft'`. Combien existent depend du Windows : `Get-ScheduledTask` fait foi, ou hors ligne `iconv -f UTF-16 -t UTF-8 ~/vms/win11/states/0_stock/tasks.txt` (format `\Chemin\Nom|Etat`).
- **Taille des runtimes** : `curl -sIL <url> | grep -i '^content-length'` (derniere valeur) sur les URL du batch (`grep -n 'directx_Jun2010_redist.exe\|vc_redist' "$f"`). Les fichiers VC++ viennent d'un lien `aka.ms` qui suit la derniere version : les tailles bougent.
- **Valeurs de registre suivies et comparaisons de VM** : `~/vms/win11/states/0_stock/reg.json` (JSON avec BOM : `encoding='utf-8-sig'`) ; `python3 ~/vms/winopt-lab/cmp.py <tagA> <tagB> [x]`. Les lignes `absent -> cle absente` et `cle absente -> absent` ne sont que des cles vides : `cmp.py A B x | grep -cE ': absent -> cle absente|: cle absente -> absent'`.
- **Durees** : `runs/<nom>.timeline` de la VM, premiere colonne = secondes depuis le lancement, a la ligne `Voulez-vous redemarrer maintenant`, depuis un Windows neuf (`stock`). Une duree de VM ne dit rien d'un gain en jeu (regle du banc).
- Ne pas citer comme releve du jour un chiffre qui demande une VM ou du materiel et n'a pas ete remesure.

## Sources des reglages

Sources consultees le 16 octobre 2026 et confrontees aux reglages du script (les essais Windows verifient les chemins decrits, sans demontrer un gain de performances). La relecture du registre prouve le stockage, pas la prise en compte de toutes les politiques ni un gain RAM/FPS.

- [Diagnostics Windows, niveaux et éditions](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system#allowtelemetry) ; [gestion des connexions et de la personnalisation](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services).
- [Widgets](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-newsandinterests) ; [Copilot actuel et limites de la politique legacy](https://learn.microsoft.com/en-us/windows/client-management/manage-windows-copilot).
- [Diagnostics Edge](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/diagnosticdata), [personnalisation](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/personalizationreportingenabled), [arrière-plan](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/backgroundmodeenabled) et [Chrome BackgroundModeEnabled](https://chromeenterprise.google/policies/#BackgroundModeEnabled).
- Croisement communautaire : [Win11Debloat](https://github.com/Raphire/Win11Debloat), [WinUtil](https://github.com/ChrisTitusTech/winutil). Leurs listes ne prouvent ni le besoin de désactiver une fonction ni un gain de performance.

## Gardes

- **Ne pas lancer `All in One.cmd` sur une vraie machine** pour le tester : il applique de vrais reglages systeme. Les executions completes se font dans la VM de test `~/vms/win11/`. Windows 10 est hors perimetre ; ne jamais faire tourner `~/vms/win11/` et `~/vms/win10/` simultanement. Ne pas arreter ni reinitialiser une VM utilisee par un autre fil.
- Outils communs dans `~/vms/winopt-lab/`, `VM=win11` par defaut : `vm.sh start|stop|status`, `lab.sh reset|prep|state|snapshot`, `suite.sh <nom> "<motif=>touche | ...>" [reset|reset=rt] [reboot]`, `cmp.py <tagA> <tagB>`, et `check.sh` qui rejoue tous les controles ci-dessus, y compris dans la VM si elle tourne (controle statique seul : `--local`), et qui revient a un instantane neuf. Instantane `rt` : Windows neuf plus runtimes VC++ et DirectX officiels, prepare par `rt_install.ps1` ; il saute les runtimes pour iterer vite. Mesures de duree et tout changement des runtimes : toujours `stock`. `-VerifyOnly` et les controles ci-dessus sont sans effet de bord.
- Demander une confirmation explicite, si l'action n'est pas deja autorisee dans le perimetre courant, avant `commit --amend` sur un commit publie, `reset --hard`, suppression de fichier, et toute operation touchant `main` ou une ressource distante. Ne pas ecarter un fichier inconnu : c'est peut-etre un travail en cours.

## Methodes

Verifiees sur ce depot. Revalider leur utilite : corroborer les conseils issus de sessions independantes ; un defaut reproductible ou une limite couteuse a manquer n'attend pas deux incidents. Supprimer sur preuve de nuisance, remplacement fiable ou absence d'utilite.

- **Executer plutot que relire.** Syntaxe, parentheses, encodage et logique se controlent par un programme, jamais a l'oeil. Un helper teste sur une cle scratch revele ce qu'un test de syntaxe laisse passer.
- **Le script se pilote dans une vraie console, touche par touche.** Fournir les touches par fichier fausse le test : les programmes lances avalent les touches en attente. Par SSH, `choice.exe` refuse les chiffres et le script meurt au redemarrage de la carte reseau. `drive.py` ecrit chaque touche dans la console par un agent, invite par invite.
- **Une commande dont la sortie est masquee peut attendre le clavier.** `net stop` demande confirmation quand un service dependant tourne ; le nettoyage restait fige. Chercher tout processus enfant encore vivant quand une etape ne finit pas.
- **Une valeur stock se mesure sur un Windows neuf.** `pc-gaming` porte l'etat Gaming + Performance max : une valeur que le script ecrit n'y prouve rien (et ce PC est exclu de toute connexion, voir la route vers le banc).
- **Verifier un changement d'etat par relecture de la valeur stockee**, pas par le code de retour : `bcdedit /deletevalue` renvoie 1 sur une valeur deja absente, une ecriture refusee (UCPD, strategie de groupe) ne renvoie rien d'exploitable, et un helper qui calcule un code d'erreur sans appelant qui le lit laisse le succes annonce inconditionnellement.
- **Une cle absente ne prouve pas un no-op.** `reg add` cree tout le chemin : l'absence dit que l'ecriture n'a pas eu lieu ou a ete refusee. Rejouer l'ecriture et lire le message (`MsMpEngCP.exe` : acces refuse).
- **Un fichier destine a Windows s'ecrit par heredoc ou par programme.** Dans une commande shell de l'agent, la redirection vers `nul` suivie de `2>&1` peut etre reecrite en chemin Unix avant execution ; le fichier produit echoue alors sans raison apparente.
- **Un `)` dans le texte d'un `echo` ferme le bloc qui le contient.** `cmd` arrete alors le script sur place (« etait inattendu »). L'equilibre des parentheses ne le voit pas : dans un bloc, ecrire le texte sans parentheses ou les echapper par `^(` `^)`, et rejouer le bloc avec des `echo` a la place des commandes.
- **Un fragment de test s'extrait par label en debut de ligne.** Chercher `:LABEL` sans le saut de ligne qui precede tombe sur un `call :LABEL` et embarque du vrai code : un tel test a deja rejoue des sections entieres sur `pc-gaming`. Avant d'envoyer un fragment, verifier sa taille, l'absence de `HKLM`/`HKCR`/`powercfg` et que chaque `call :` vise un label du fragment.
- **Un appel qui touche l'interface se teste en session interactive.** Par SSH, `SystemParametersInfo` echoue en 1459 ; une tache planifiee `/it` ponctuelle donne le vrai resultat.

Ne pas recopier ici les pieges techniques (SID pour `icacls`, Latin-1, `NetCfgInstanceId`) : le batch les commente deja sur place, la ou ils expliquent le pourquoi.
