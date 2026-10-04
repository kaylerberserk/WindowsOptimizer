# WindowsOptimizer

Travaille simplement, avec des corrections locales et proportionnees.

Optimiseur Windows 10/11 tenu en **trois fichiers** : `All in One.cmd` (un batch unique de plusieurs milliers de lignes, ASCII strict, fins de ligne CRLF), `launcher.ps1` (telechargement et elevation) et `README.md` (contrat de publication). `Tools/` et `Game Configs/` ne sont que des ressources.

## Verification

Ce projet n'a pas de suite de tests : les controles ci-dessous en tiennent lieu. Les executer avant de conclure.

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

Ne lance rien, affiche la source et le SHA-256 informatif. Tester la copie locale et la copie distante separement.

Apres une edition de structure (label, `goto`, bloc `if`), verifier que chaque `goto` et chaque `call :` pointe vers un label existant, que la profondeur de parentheses est **nulle a chaque label** et que les blocs `if/else` se ferment. L'equilibre global ne prouve rien : un `)` orphelin peut etre compense ailleurs.

## Regles du projet

- Le README fait partie du contrat : garder le code, la documentation et la publication alignes. Tout chiffre annonce dans le README se mesure sur le code ou sur une reponse HTTP, jamais a l'estime. Valeurs actuelles, a remesurer des que le code change : **79** commandes PowerShell, **66** ecritures de registre de vie privee (**43** directes + **23** dans la boucle Content Delivery Manager, sections 1.4-1.5 uniquement), **26** taches planifiees nommees dans la boucle de desactivation (autre boucle pour la restauration) — **14** d'entre elles existent et sont desactivees sur Windows 11 25H2, **11** n'existent pas sur cette version, `Subscription\EnableLicenseAcquisition` reste active, **6** autologgers WMI, **~120 Mo** de runtimes.
- `All in One.cmd` est volontairement un script unique, dense et portable. Preserve ce choix : pas de sur-ingenierie, de couches inutiles ni de multiplication de fichiers. Le fichier se parcourt par label, jamais par numero de ligne.
- Le launcher n'epingle aucun SHA : `-VerifyOnly` affiche seulement un SHA-256 informatif du batch prepare.
- Le script a ete execute en VM neuve (Windows 11 build 26300) avec releve avant et apres : `Tout optimiser` dans les quatre combinaisons de profils, les sections et menus lances un a un, protections, UAC, animations, IA, applications, nettoyage, OneDrive et Edge. Voir ``. Restent non couverts : Windows 10, un portable, du vrai materiel GPU et reseau, la desactivation effective de Defender, MAS et WinUtil.
- Une restauration "par defaut" restaure un etat capture ou applique un fallback Windows documente. Supprimer une valeur n'est pas toujours l'inverse correct.
- Pour les tweaks Windows, faire une recherche Web recente et croiser les sources : la documentation Microsoft peut etre incomplete, imprecise, ancienne ou trop prudente. Comprendre le mecanisme reel, puis confronter documentation, forums techniques, tests reproductibles et retours terrain.

## Gardes

- **Ne pas lancer `All in One.cmd` sur une vraie machine** pour le tester : il applique de vrais reglages systeme. Les executions completes se font dans la VM de test de hp-dev (`~/vms/winopt/` : `lab.sh reset|prep|state`, `suite.sh <nom> "<motif=>touche | ...>" [reset] [reboot]`), qui revient a un instantane neuf. `-VerifyOnly` et les controles ci-dessus sont sans effet de bord.
- Demander une confirmation explicite avant toute action difficile a reverser ou visible ailleurs : `git push`, `commit --amend` sur un commit publie, `reset --hard`, suppression de fichier, et toute operation touchant `main` ou une ressource distante. `main` est la branche de publication.
- Ne pas contourner un controle de securite pour aller plus vite, et ne pas ecarter un fichier inconnu : c'est peut-etre un travail en cours.
- Ne pas changer une valeur ni un axe de l'auteur sans le lui signaler, meme quand la logique interne du script plaide pour l'autre choix.
- Ne pas annoncer un travail termine sans tests qui l'ont ete.

## Methodes

Verifiees sur ce depot. Revalider avant de les conserver : une regle qui ne s'est pas reproduite deux fois est un candidat a la suppression.

- **Executer plutot que relire.** Syntaxe, parentheses, encodage et logique se controlent par un programme, jamais a l'oeil. Un helper teste sur une cle scratch revele ce qu'un test de syntaxe laisse passer.
- **Le script se pilote dans une vraie console, touche par touche.** Fournir les touches par fichier fausse le test : les programmes lances avalent les touches en attente. Par SSH, `choice.exe` refuse les chiffres et le script meurt au redemarrage de la carte reseau. `drive2.py` ecrit chaque touche dans la console par un agent, invite par invite.
- **Une commande dont la sortie est masquee peut attendre le clavier.** `net stop` demande confirmation quand un service dependant tourne ; le nettoyage restait fige. Chercher tout processus enfant encore vivant quand une etape ne finit pas.
- **Une valeur stock se mesure sur un Windows neuf.** `pc-gaming` porte l'etat Gaming + Performance max : une valeur que le script ecrit n'y prouve rien. Quatre constats de l'audit etaient faux pour cette raison.
- **Le code retour d'une suppression ne dit pas si l'etat voulu est atteint.** `bcdedit /deletevalue` renvoie 1 sur une valeur deja absente ; `Defaut Windows` annoncait un echec pour cela. Relire l'etat final.
- **Un fichier destine a Windows s'ecrit par heredoc ou par programme.** Dans une commande shell de l'agent, la redirection vers `nul` suivie de `2>&1` peut etre reecrite en chemin Unix avant execution ; le fichier produit echoue alors sans raison apparente.
- **Un `)` dans le texte d'un `echo` ferme le bloc qui le contient.** `cmd` arrete alors le script sur place (« etait inattendu »). L'equilibre des parentheses ne le voit pas : dans un bloc, ecrire le texte sans parentheses ou les echapper par `^(` `^)`, et rejouer le bloc avec des `echo` a la place des commandes.
- **Un fragment de test s'extrait par label en debut de ligne.** Chercher `:LABEL` sans le saut de ligne qui precede tombe sur un `call :LABEL` et embarque du vrai code : le 2026-10-03, un tel test a rejoue les sections 1.8 a 1.17 sur `pc-gaming`. Avant d'envoyer un fragment, verifier sa taille, l'absence de `HKLM`/`HKCR`/`powercfg` et que chaque `call :` vise un label du fragment.
- **Une cle absente ne prouve pas un no-op.** `reg add` cree tout le chemin : l'absence dit que l'ecriture n'a pas eu lieu ou a ete refusee. Rejouer l'ecriture et lire le message (`MsMpEngCP.exe` : acces refuse).
- **Un appel qui touche l'interface se teste en session interactive.** Par SSH, `SystemParametersInfo` echoue en 1459 ; une tache planifiee `/it` ponctuelle donne le vrai resultat.
- **Verifier un changement d'etat par relecture de la valeur stockee**, pas par le code de retour de l'ecriture : une ecriture refusee (UCPD, strategie de groupe) ne renvoie rien d'exploitable. Un helper qui calcule un code d'erreur sans appelant qui le lit laisse le succes annonce inconditionnellement.

Ne pas recopier ici les pieges techniques (SID pour `icacls`, Latin-1, `NetCfgInstanceId`) : le batch les commente deja sur place, la ou ils expliquent le pourquoi.

Propose les ameliorations utiles en expliquant simplement leur interet, sans compliquer le projet.
