# WindowsOptimizer

Travaille simplement, avec des corrections locales et proportionnees.

Optimiseur Windows 10/11 tenu en **trois fichiers** : `All in One.cmd` (un batch unique de plusieurs milliers de lignes, ASCII strict, fins de ligne CRLF), `launcher.ps1` (telechargement et elevation) et `README.md` (contrat de publication). `Tools/` et `Game Configs/` ne sont que des ressources.

## Verification

Ce projet n'a pas de suite de tests : les deux controles ci-dessous en tiennent lieu. Les executer avant de conclure.

**Contrat de format.** Le batch refuse de s'executer si le fichier contient un octet > 0x7F ou une ligne LF isolee, et se relance seul pour se corriger. Doit retourner `0` :

```powershell
powershell -NoProfile -Command "try{$b=[IO.File]::ReadAllBytes('All in One.cmd');for($i=0;$i-lt$b.Length;$i++){if($b[$i]-eq0-or$b[$i]-gt127){exit 44};if(($b[$i]-eq10-and($i-eq0-or$b[$i-1]-ne13))-or($b[$i]-eq13-and($i+1-ge$b.Length-or$b[$i+1]-ne10))){exit 42}};exit 0}catch{exit 43}"
```

`44` = octet non ASCII, `42` = ligne LF, `43` = fichier illisible. Ecrire les commentaires du batch en ASCII, sans accent ni guillemet typographique : l'echec n'apparait qu'a la lecture par le visiteur, une fois publie.

Cette commande duplique celle du batch, qui se parametre par `%WINOPT_SELF%` et se tait avec `>nul 2>&1` pour rester copiable ici. Si l'une des deux evolue, mettre les deux a jour dans le meme commit.

**Launcher**, sur la copie publiee, dans un dossier temporaire contenant `launcher.ps1` seul :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher.ps1 -VerifyOnly
```

Ne lance rien, affiche la source et le SHA-256 informatif. Tester la copie locale et la copie distante separement.

Apres une edition de structure (label, `goto`, bloc `if`), verifier que chaque `goto` et chaque `call :` pointe vers un label existant, que la profondeur de parentheses est **nulle a chaque label** et que les blocs `if/else` se ferment. L'equilibre global ne prouve rien : un `)` orphelin peut etre compense ailleurs.

## Regles du projet

- Le README fait partie du contrat : garder le code, la documentation et la publication alignes. Tout chiffre annonce dans le README se mesure sur le code ou sur une reponse HTTP, jamais a l'estime.
- `All in One.cmd` est volontairement un script unique, dense et portable. Preserve ce choix : pas de sur-ingenierie, de couches inutiles ni de multiplication de fichiers. Le fichier se parcourt par label, jamais par numero de ligne.
- Le launcher n'epingle aucun SHA : `-VerifyOnly` affiche seulement un SHA-256 informatif du batch prepare.
- Le script n'a jamais ete execute en entier sur une machine reelle. Les parcours manuel et `Tout optimiser`, ainsi que les transitions Normal/Gaming et Eco/Performance Max dans les deux sens, restent non verifies : c'est le premier manque a couvrir.
- Une restauration "par defaut" restaure un etat capture ou applique un fallback Windows documente. Supprimer une valeur n'est pas toujours l'inverse correct.
- Pour les tweaks Windows, faire une recherche Web recente et croiser les sources : la documentation Microsoft peut etre incomplete, imprecise, ancienne ou trop prudente. Comprendre le mecanisme reel, puis confronter documentation, forums techniques, tests reproductibles et retours terrain.

## Gardes

- **Ne pas lancer `All in One.cmd`** pour le tester : il applique de vrais reglages systeme. `-VerifyOnly` et les controles ci-dessus sont sans effet de bord.
- Demander une confirmation explicite avant toute action difficile a reverser ou visible ailleurs : `git push`, `commit --amend` sur un commit publie, `reset --hard`, suppression de fichier, et toute operation touchant `main` ou une ressource distante. `main` est la branche de publication.
- Ne pas contourner un controle de securite pour aller plus vite, et ne pas ecarter un fichier inconnu : c'est peut-etre un travail en cours.
- Ne pas changer une valeur ni un axe de l'auteur sans le lui signaler, meme quand la logique interne du script plaide pour l'autre choix.
- Ne pas annoncer un travail termine sans tests qui l'ont ete.

## Methodes

Verifiees sur ce depot. Une regle qui ne s'est pas reproduite deux fois est un candidat a la suppression.

- **Executer plutot que relire.** Syntaxe, parentheses et encodage se controlent par un programme. Trois bugs n'apparurent qu'a l'execution : `%*` est substitue une seule fois a l'analyse (un helper ne peut donc pas executer un corps de boucle), `set "X=Y"` sur une ligne `if ... else` casse l'analyse de cmd, et un `pushd` non depile sur un chemin de sortie. Un helper teste sur une cle scratch revele aussi des erreurs de logique qu'un test de syntaxe laisse passer.
- **Un "defaut mesure" sur une machine que le script a deja modifiee est circulaire.** La valeur de reference de `Win32PrioritySeparation` a ete lue ainsi ; seul un croisement avec la documentation a tranche.
- **Mesurer avant d'optimiser.** Un ralentissement suppose peut ne pas exister : `Invoke-WebRequest` s'est revele aussi rapide que `curl` sur 95 Mo, et le correctif aurait ete cosmetique.
- **Verifier un changement d'etat par relecture de la valeur stockee**, pas par le code de retour de l'ecriture : une ecriture refusee (UCPD, strategie de groupe) ne renvoie rien d'exploitable. Un helper qui calcule un code d'erreur sans appelant qui le lit laisse le succes annonce inconditionnellement.
- **Regarder `git status` avant commit** : un artefact d'outillage a deja fini dans le depot via une redirection shell.

Les pieges techniques (SID plutot que nom de groupe pour `icacls`, Latin-1 pour reecrire un fichier systeme, `NetCfgInstanceId` pour resoudre une sous-cle de classe) sont commentes sur place dans le batch. Ce sont des notes de code : les laisser la ou elles expliquent le pourquoi.

Propose les ameliorations utiles en expliquant simplement leur interet, sans compliquer le projet.
