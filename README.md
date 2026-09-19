<div align="center">

# WINDOWS OPTIMIZER

### 🚀 Optimisation modulaire pour Windows 10 & 11

*Choisissez des profils clairs pour les performances, la latence et la confidentialité.*

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)![Version](https://img.shields.io/badge/Version-2026.08-orange?style=for-the-badge)![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Conçu pour le jeu, le multitâche et la confidentialité.**<br />*Code source public • Script unique • Réglages explicites*

</div>

---

## 📌 Sommaire

- [📖 À propos du projet](#-%C3%A0-propos-du-projet)
- [🚀 Démarrage rapide](#-d%C3%A9marrage-rapide)
- [🛠️ Guide des fonctionnalités](#%EF%B8%8F-guide-des-fonctionnalit%C3%A9s)
- [❓ FAQ (Foire aux questions)](#-faq-foire-aux-questions)

---

## 📖 À propos du projet

**Windows Optimizer** regroupe dans un batch portable des profils de performance et des outils de maintenance pour Windows 10 et 11.

Ce script privilégie une configuration lisible et des profils explicites pour Windows 10 et 11. Le résultat dépend toutefois de la version de Windows, des pilotes, du matériel et des logiciels installés. Créez un point de restauration et lisez les avertissements avant les options sensibles (sécurité, Edge, OneDrive et nettoyage avancé).

---

## 🚀 Démarrage rapide

```powershell
irm https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1 | iex
```

Collez cette commande dans **PowerShell non administrateur**. Le launcher télécharge et contrôle le batch publié sur `main`, précharge le timer dans son dossier temporaire, le normalise en CRLF puis l'ouvre dans une fenêtre CMD administrateur dédiée, comme lors d'un lancement manuel. Acceptez la demande UAC : appartenir au groupe Administrateurs ne suffit pas sans jeton élevé. Le dossier temporaire est supprimé à la fin.

Depuis un clone local, cette commande vérifie le batch publié sans demander l'UAC ni exécuter l'optimiseur :

```powershell
.\launcher.ps1 -VerifyOnly
```

> Le launcher n'utilise pas un `All in One.cmd` placé à côté de lui : la commande `irm` et `.\launcher.ps1` utilisent le même batch publié. Pour tester la copie locale, ouvrez directement `All in One.cmd` en administrateur. Le mode `-VerifyOnly` affiche la source et le SHA-256 contrôlés.

### Premier parcours

1. Appuyez sur **[R]** pour créer un point de restauration.
2. Appuyez sur **[O]** pour le parcours complet.
3. Choisissez l'usage, l'énergie, puis les cinq choix complémentaires proposés : protections Windows, Defender, animations, fonctions IA et UAC.
4. Les sections sont ensuite exécutées une fois, sans nouvelle question hors contrôles et confirmations dédiés.
5. Un redémarrage est **recommandé** après un parcours complet et devient nécessaire lorsque Windows, un réglage de sécurité/pilote ou un installateur le signale.
6. La durée dépend du PC, des options choisies et de la connexion.

---

## 🛠️ Guide des fonctionnalités

### 🌟 Système de Profils à 2 Axes (All-in-One [O])

L'option **[O] Tout optimiser** repose sur **deux axes indépendants** qui définissent 4 combinaisons possibles. Le script vous pose quelques questions (profil + options) et en déduit automatiquement la configuration demandée.

Le parcours automatique enchaîne ensuite les sections sans nouvelle question et affiche un résumé final. Les prérequis, téléchargements, installateurs et confirmations destructives conservent leurs contrôles dédiés.

Les sections granulaires reprennent la même logique : **Mémoire** et **Réseau** demandent les deux axes, tandis que **Disques/GPU/Système/Input** demandent l'usage. Le menu **Protections Sécurité** propose séparément trois niveaux explicites.

> Les mentions **stock mesuré** correspondent à l'installation propre Windows 11 25H2 build `26200.8037` utilisée comme référence pour cet audit. Les états dépendants d'un pilote ou d'un périphérique, notamment MSI, sont sauvegardés puis restaurés individuellement au lieu d'être généralisés à tous les PC.
>
> Normal/Eco restaure les réglages exclusifs gérés par ces profils ; ce n'est pas une remise à zéro intégrale de Windows. Les choix destructifs (désinstallations, suppressions de fichiers, caches, télémétrie et services) restent explicitement hors d'une restauration automatique universelle.

#### Axe 1 — Usage (`PROFIL_USAGE`)

> *Pilote la **latence applicative** : périphériques d'entrée, pile TCP, latence GPU.*

|  Choix |   Profil | Réglages clés                                                                                                                                                                                                                                                                                                  |
|:-------:|:----------:|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **[1]** | **GAMING** | Réduit la latence du GPU, des entrées et du réseau : VRR/Auto HDR OFF, pile TCP Gaming (activation de BBR2 tentée, Pacing et ECN), accélération souris OFF et réglages MSI compatibles. Nagle/DelACK et RSC/LSO ne sont coupés qu'avec MaxPerf ; Eco conserve les offloads réseau.                             |
| **[2]** | **NORMAL** | Restaure la pile TCP et l'énergie GPU au stock mesuré : cubic, Pacing/ECN OFF, Nagle/DelACK natifs et propriétés réseau du pilote réinitialisées. Les états MSI capturés et les réglages NVIDIA touchés par Gaming sont restaurés de façon ciblée. L'accélération souris reste désactivée par choix du script, sauf en **Normal + Eco sur portable** où le comportement Windows stock est conservé. |

#### Axe 2 — Énergie (`PROFIL_POWER`)

> *Pilote **l'énergie, le niveau de tuning NIC et le plan d'alimentation**.*

|  Choix |    Profil | Réglages clés                                                                                                                                                                                                                                    |
|:-------:|:------------:|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **[1]** |   **ECO**  | Plan Équilibré sans supprimer les plans OEM, hibernation et démarrage rapide disponibles, compression mémoire active et économies d'énergie réseau/USB restaurées. Les propriétés réseau modifiées par MaxPerf reviennent au défaut du pilote.   |
| **[2]** | **MAX PERF** | Plan Ultimate Performance, économies d'énergie réseau/USB ciblées désactivées et compression mémoire coupée au-delà de 8 Go de RAM. En Gaming, le tuning réseau devient plus agressif. Le preset timer reste expérimental et réversible via Eco. |

> **Sur PC fixe comme portable** : les deux questions sont posées, pour permettre un desktop silencieux/économe ou un laptop branché en **MAX PERF**.
> **Sur PC portable** : la combinaison **GAMING + ECO** est autorisée avec un avertissement — Nagle/DelACK revient au comportement Windows natif (batterie avant tout), tandis qu'initialRTO=3000 et maxsynretransmissions=2 restent appliqués par l'axe Gaming ; les optimisations GPU/input/CPU restent agressives.
>
> Les quatre combinaisons sont convergentes : changer de profil annule explicitement les réglages exclusifs laissés par le profil précédent.
> Le changement manuel Eco/Performance Max resynchronise aussi `DisablePagingExecutive`, FTH et la compression mémoire. La passe de convergence réseau renvoie désormais une erreur lorsqu'une carte ne peut pas appliquer ses propriétés.

| Combinaison          | Comportement principal                                                                                                                                                                                                                                                                          |
|----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Gaming + MaxPerf** | Réglages de latence les plus agressifs : Nagle/DelACK et RSC/LSO coupés, Interrupt Moderation active avec les délais exposés réglés au minimum annoncé par le pilote. Sur Realtek, le script applique aussi le niveau `Low` (`InterruptModerationLevel=0`) et l'intervalle `IntMitiInterval=0`. |
| **Gaming + Eco**     | Réglages gaming GPU/input, mais comportement réseau natif pour Nagle/DelACK et offloads conservés afin de privilégier autonomie et stabilité.                                                                                                                                                   |
| **Normal + MaxPerf** | Plan et énergie MaxPerf sans les réglages réseau gaming agressifs ; RSC/LSO et propriétés de latence exclusives sont restaurés.                                                                                                                                                                 |
| **Normal + Eco**     | Configuration la plus conservatrice : comportement réseau natif, gestion d'énergie active et plan Équilibré. Sur portable, `SEMgrSvc` reste en Manual, `DiagLog` reste actif et le comportement pointeur Windows est conservé.                                                                  |

#### Règle d'attribution (design interne)

Chaque réglage est principalement piloté par **un seul axe**, sauf les exceptions explicites ci-dessous :

- **Latence applicative** (input, I/O, stack TCP Nagle/timers, low-latency GPU) → `PROFIL_USAGE`
- **Énergie / tuning NIC / plan d'alimentation** → `PROFIL_POWER`

Exceptions réseau :

- **RSC/LSO/RscIPv6** : coupés uniquement en **GAMING + MAX PERF** (préservent débit/stabilité en Normal/Eco).
- **initialRTO / maxsynretransmissions** : 3000 ms / 2 en Gaming ; 1000 ms / 4 en Normal, conformément à l'état stock Windows 11 25H2 mesuré. La documentation `netsh` liste encore 3000/2 comme valeurs par défaut, mais les builds clients Windows 11 observés utilisent 1000/4. `initialRTO` ne règle pas le RTO des paquets après connexion.
- **Congestion / heuristics** : Gaming demande BBR2 sur Internet, InternetCustom, Datacenter, DatacenterCustom et Compat avec `forcews=enabled`. Normal restaure `cubic` et `forcews=default`. Le paramètre WSH n'est plus utilisé par Windows. Le loopback Large MTU est désactivé en Gaming et réactivé en Normal.
- **Nagle/DelACK** : agressif en Gaming+MaxPerf, natif Windows en Eco et en Normal+MaxPerf.

### ⚙️ Optimisations Granulaires

- **[1] Système** : Optimisation du noyau (Kernel), de la planification CPU et suppression de la télémétrie. Sous Windows 11, tous les profils désactivent les suggestions et les applications récemment ajoutées (`Start_IrisRecommendations=0`, `ShowRecentList=0`) ; Gaming masque aussi « Recommandations » et « Tout », tandis que Normal supprime uniquement ces politiques de masquage. Sur **portable + Normal + Eco**, `DiagLog` reste actif et `SEMgrSvc` reste en démarrage manuel afin de préserver les diagnostics/batterie et la page moderne Alimentation et batterie. La recherche, les fichiers récents de l’Explorateur et les Jump Lists restent disponibles. La section pose aussi des réglages navigateur communs aux profils : QUIC et accélération matérielle activés, DNS sur HTTPS Cloudflare en mode `allow` (chiffré quand disponible, repli DNS normal sur les réseaux filtrés), démarrage rapide et arrière-plan Edge conservés par choix, et un refus NTFS posé sur la base du Store (`store.db`, SID universel) pour couper ses suggestions dans la recherche — réversible en retirant ce refus.
- **[2] Mémoire** : Ajustement de la gestion RAM et de la compression mémoire selon l'énergie, avec Prefetch piloté par l'usage.
- **[3] Disques** : TRIM et maintenance Windows conservés ; chemins longs activés en Gaming et rendus à `LongPathsEnabled=0` en Normal, comme sur le stock mesuré.
- **[4] GPU** : Configuration des priorités graphiques et des options de latence prises en charge par le pilote.
- **[5] Réseau** : pile TCP Gaming ou stock mesuré en Normal, puis réglages de la carte selon l'énergie. Eco privilégie stabilité et autonomie ; Gaming+MaxPerf applique les options de latence les plus agressives que le pilote expose. En Gaming, une stratégie QoS marque aussi le trafic UDP/TCP de Fortnite en DSCP 46.
- **[6] Input** : Ajustement de la réponse clavier/souris, des files d'entrée et du mode MSI des contrôleurs compatibles.
- **[7] Énergie** : Gestion des plans d'alimentation et déblocage de l'Ultimate Performance, avec choix d'usage pour appliquer le bon tuning NIC.
- **[8] Sécurité** : Choix entre 3 modes pour VBS/HVCI/CFG/SEHOP, mitigations processeur, LSA/Credential Guard, hyperviseur BCD et liste de pilotes vulnérables.

| Mode                          |  Sécurité VBS / HVCI  | Anti-Cheats (Valorant / FACEIT) | Usage Recommandé                                               |
|-------------------------------|:----------------------:|:-------------------------------:|----------------------------------------------------------------|
| **1 - Défaut Windows**        | ✅ Selon l'état Windows |          ✅ Compatible  | Capture restaurée ; sinon base stock Windows 11 25H2 appliquée |
| **2 - Gaming (Recommandé) ★** |        ✅ Activé |     ✅ Compatibilité élevée  | Équilibre performances / sécurité pour tous types de jeux      |
| **3 - Performance Max ⚠️**    |      ❌ Désactivé  |        ⚠️ Selon les jeux | Réglages les plus agressifs, avec sécurité réduite             |

> ### 💡 Vue d'ensemble des 3 modes
>
> * **Gaming (Recommandé ★)** : Conserve **VBS / HVCI** et **LSA Protection** (`RunAsPPL=2` sans verrou UEFI) pour limiter les conflits avec les anti-cheats modernes, laisse **CFG** à `NOTSET` (défaut Windows), désactive **SEHOP**, réduit les mitigations CPU et demande la désactivation de la blocklist.
> * **Défaut Windows** : restaure le snapshot capturé avant un profil de sécurité. Sans snapshot, il applique la base stock mesurée (FeatureSettings=0, RunAsPPL/RunAsPPLBoot=2, blocklist de pilotes=1) et retire les overrides de l'outil.
> * **Performance Max ⚠️ (Déconseillé)** : Désactive VBS, HVCI et SEHOP, conserve CFG et **LSA Protection** (`RunAsPPL=2` sans verrou UEFI), réduit les mitigations CPU et demande la désactivation de la blocklist.

> ### 🔍 Notes & Précisions techniques
>
> * **Champs modifiés** : les modes *Gaming* et *Performance Max* modifient uniquement CFG et SEHOP dans `MitigationOptions` pour préserver les autres mitigations de processus. *Défaut Windows* restaure les valeurs capturées ou applique la base stock 25H2 lorsqu'aucun snapshot n'existe.
> * **Mitigations CPU (Spectre/Meltdown)** : `33554435/3` (0x2000003) correspond aux modes *Gaming* et *Perf Max*. Le mode *Défaut Windows* ne force plus `0/3` : il restaure l'état précédent ou laisse Windows gérer l'absence d'override.
> * **Blocklist de pilotes** : *Gaming* conserve HVCI actif. Si HVCI, Smart App Control ou le mode S restent actifs, Windows peut continuer d'imposer la blocklist même si la désactivation a été demandée.
> * **Application automatique** : dans **Tout optimiser**, la question *Protections Windows* applique directement les réglages *Défaut Windows* en usage Normal ou *Gaming* en usage Gaming. Elle ne demande pas de choisir un second mode de sécurité. *Performance Max* reste accessible séparément depuis le menu Sécurité.

### 🧰 Outils & Utilitaires

- **[N] Nettoyage Avancé** : Nettoyage système en 26 étapes : temporaires, corbeille, dumps, caches Windows/applications, journaux archivés, npm, OneDrive/Defender et autres diagnostics. `Windows.old` n'est supprimé qu'après une confirmation séparée.
- **[R] Point de Restauration** : Crée un point de restauration système avant toute modification.
- **[G] Gestion Windows** : Menu dédié (Defender, UAC, animations, IA/Widgets, Edge, OneDrive…).
- **[W] MAS** : Lance le script officiel MAS depuis son URL de mise à jour continue. À utiliser dans le respect des licences Windows/Office.
- **[T] WinUtil** : Lance la dernière version officielle disponible de WinUtil.
- **[Q] Quitter** : Ferme le script.

### 📂 Gestion Windows & Maintenance (Menu [G])

| Touche  | Fonction             | Description                                                                                                                                                            |
|:-------:|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **[1]** | **Windows Defender** | Activation ou désactivation étendue. La réactivation conserve les règles ASR et CFA existantes, réactive les protections principales et signale un état final partiel. |
| **[2]** | **UAC**              | Gestion fine des notifications du Contrôle de Compte Utilisateur.                                                                                                      |
| **[3]** | **Animations**       | Choix entre une interface visuelle riche ou ultra-réactive.                                                                                                            |
| **[4]** | **IA & Widgets**     | Activation ou désactivation de Copilot et des Widgets sur Windows 11. Recall dépend de la version/édition de Windows et peut être absent ou non pris en charge.        |
| **[5]** | **OneDrive**         | Désinstallation complète, arrêt de la synchronisation et suppression des dossiers OneDrive restants, dont `%USERPROFILE%\OneDrive`.                                    |
| **[6]** | **Microsoft Edge**   | Désinstallation de Microsoft Edge avec WebView2 préservé. Recherche, Widgets, météo et certaines PWA peuvent être affectés.                                            |
| **[7]** | **Runtimes**         | Installation du Visual C++ v14 actuel et de DirectX June 2010.                                                                                                         |
| **[8]** | **Bloatwares**       | Suppression des apps préinstallées inutiles (News, Solitaire, Skype, etc.).                                                                                            |
| **[M]** | **Retour**           | Retour au menu principal.                                                                                                                                              |

## ❓ FAQ (Foire aux questions)

### 🏠 Installation & Sécurité

**Q : La commande** `irm` **ne démarre pas le launcher ?**

R : Exécutez-la dans **Windows PowerShell** ou **PowerShell**, pas dans `cmd.exe`. En cas d'erreur réseau ou d'URL, la commande affiche immédiatement l'erreur de `Invoke-RestMethod`. Depuis un clone, lancez `.\launcher.ps1 -VerifyOnly` pour contrôler le launcher et le batch sans UAC ni modification système.

**Q : Est-ce que ce script peut provoquer une incompatibilité ?**
R : Oui, comme tout outil qui modifie des stratégies, services, pilotes ou paramètres réseau. Créez d'abord un point de restauration, choisissez le profil Normal/Eco en cas de doute et évitez les options de sécurité ou de désinstallation dont vous n'avez pas besoin.

**Q : Mon antivirus détecte le script, pourquoi ?**  
R : Les commandes d'administration, les téléchargements et les modifications de sécurité peuvent déclencher une alerte. Ne supposez pas automatiquement qu'il s'agit d'un faux positif : vérifiez le dépôt, le diff et les fichiers téléchargés avant exécution.

**Q : Puis-je lancer le script plusieurs fois ?**  
R : Oui pour les profils principaux : Gaming/Normal et Performance Max/Eco remplacent leurs réglages exclusifs et nettoient plusieurs vestiges connus. Un parcours **Tout optimiser** n'exécute chaque section qu'une fois, mais vous pouvez relancer ensuite une section depuis le menu. Les suppressions, désinstallations, caches et autres actions destructives ne sont pas toutes répétables ni réversibles. Un point de restauration ne récupère pas nécessairement les fichiers supprimés, les désinstallations, la corbeille, les caches ou `Windows.old`.

### 🎮 Performance & Gaming

**Q : Quel gain de FPS puis-je espérer ?**  
R : Le gain varie selon le matériel et la charge. Il peut surtout se manifester par une latence ou une stabilité plus régulière ; aucun gain de FPS n'est garanti.

**Q : Que fait le preset timer de Performance Max ?**
R : Tous les profils suppriment les overrides BCD `useplatformclock`/`useplatformtick`/`tscsyncpolicy`. Performance Max ajoute `disabledynamictick=yes` et lance `SetTimerResolution` via un raccourci du dossier de démarrage, tandis qu'Eco supprime aussi cet override, retire le raccourci et réactive HPET s'il avait été désactivé par une ancienne version du script. Microsoft classe ces options comme des réglages de débogage : le preset reste expérimental et aucun gain universel n'est garanti. Un redémarrage est nécessaire après le changement.

**Q : Pourquoi modifier les mitigations Spectre/Meltdown (Option 8) ?**
R : Certaines protections ajoutent une charge selon le processeur et la charge de travail. Gaming conserve VBS/HVCI, laisse CFG au défaut Windows, désactive SEHOP, réduit les mitigations CPU et demande la désactivation de la blocklist. HVCI peut néanmoins maintenir cette blocklist active. Performance Max désactive VBS/HVCI/SEHOP, laisse CFG au défaut Windows, réduit les mitigations CPU et demande aussi la désactivation de la blocklist. Défaut Windows restaure le snapshot de sécurité ou applique la base stock 25H2 mesurée sans snapshot. Les trois modes suppriment la surcharge BCD `hypervisorlaunchtype` lorsqu'ils la gèrent ; les stratégies et verrous externes restent prioritaires.

**Q : Changer plusieurs fois de mode de sécurité laisse-t-il les anciens réglages actifs ?**
R : Le premier passage Gaming ou Performance Max capture les valeurs ciblées et la valeur BCD avant modification. Défaut Windows réimporte ensuite ce snapshot de façon ciblée ; sans snapshot, il retire les overrides connus puis applique les quelques valeurs stock mesurées et explicitement gérées (`FeatureSettings=0`, `RunAsPPL=2`, `RunAsPPLBoot=2`, blocklist=1). Une stratégie d'entreprise ou un verrou UEFI peut cependant réimposer une valeur extérieure au script.

**Q : Performance Max désactive-t-il toutes les protections ?**
R : Non. Performance Max désactive VBS, HVCI, SEHOP et Credential Guard local/policy, laisse CFG à `NOTSET` (dont le défaut Windows effectif est ON), demande la désactivation de la blocklist, réduit les mitigations CPU, mais conserve LSA Protection avec `RunAsPPL=2` sans verrou UEFI et laisse les Kernel Shadow Stacks inchangées. Smart App Control, le mode S ou une stratégie peuvent maintenir la blocklist active. La valeur BCD `hypervisorlaunchtype` est supprimée (`deletevalue`). Une ancienne configuration Credential Guard verrouillée en UEFI peut nécessiter une procédure avec confirmation physique pour retirer ce verrou.

**Q : Quelle différence entre Gaming et Performance Max pour les anti-cheats ?**
R : Gaming conserve VBS/HVCI et laisse CFG au défaut Windows afin de limiter les incompatibilités. Performance Max désactive VBS/HVCI ; sa compatibilité dépend donc du jeu, de l'anti-cheat et de leur version. Certains exigent aussi TPM, Secure Boot, la virtualisation ou IOMMU.

**Q : Est-ce compatible avec tous les jeux en ligne ?**
R : Aucune compatibilité universelle ne peut être garantie. Le mode Gaming conserve VBS/HVCI/CFG pour limiter les conflits avec les anti-cheats modernes, mais désactive SEHOP — sans garantir les exigences futures de chaque jeu ou anti-cheat.

### 🌐 Maintenance & Divers

**Q : Est-ce que le nettoyage (Option N) supprime mes documents ?**  
R : Il ne cible pas directement les dossiers Documents/Images/Vidéos actuels. Il vide toutefois la corbeille et supprime des caches, dumps, rapports d'erreur et journaux archivés. Si `Windows.old` existe, sa suppression définitive est proposée séparément et peut inclure d'anciennes données utilisateur. Les journaux Event Viewer actifs, l'historique Windows Update et les autres fichiers de récupération sont conservés.

**Q : Puis-je réinstaller OneDrive ou Edge plus tard ?**  
R : Oui. OneDrive se réinstalle via `winget install Microsoft.OneDrive` ou depuis le site Microsoft. Edge peut être réinstallé manuellement, mais les politiques Edge Update posées lors de sa suppression peuvent devoir être retirées si l'installateur les respecte. Les données supprimées pendant la désinstallation ne sont pas récupérées.

**Q : Quels "Bloatwares" sont supprimés ?**  
R : Le script cible une liste explicite d'applications préinstallées non essentielles et vérifie leur suppression. Leur absence peut néanmoins modifier certaines intégrations Windows.

#### 🗑️ Supprimé

| Catégorie          | Applications                                                                                 |
|--------------------|----------------------------------------------------------------------------------------------|
| **Jeux & Pubs**    | Candy Crush (Saga & Soda), Solitaire Collection.                                             |
| **Social / Liens** | Skype, People, Microsoft Family.                                                             |
| **Utilitaires**    | Cartes (Maps), Feedback Hub, Get Help, Get Started, Mixed Reality Portal, Assistance rapide. |
| **Services**       | Office Hub (Web stub), OneConnect (Forfaits mobiles), Bing News (Actualités).                |

#### ✅ Conservé

| Catégorie        | Applications                                                   |
|------------------|----------------------------------------------------------------|
| **Gaming**       | Suite **Xbox** (Game Bar, App), DirectX, Game Mode.            |
| **Quotidien**    | Météo, Sports, Finances, Alarmes, Caméra, Enregistreur vocal.  |
| **Multimédia**   | Musique (Groove), Films et TV, Photos, Paint.                  |
| **Productivité** | Calculatrice, Bloc-notes, Courrier & Calendrier, Sticky Notes. |
| **Système**      | Store, Sécurité Windows, Terminal, Capture.                    |

**Q : Dois-je redémarrer après l'optimisation ?**
R : Un redémarrage est recommandé après un parcours complet. Il est nécessaire si le script, Windows ou un installateur le signale, notamment pour certains changements VBS/HVCI/SEHOP, pilotes ou alimentation.

### 🛡️ Sécurité & fiabilité

**Q : Comment les téléchargements distants sont-ils vérifiés ?**
R : Le launcher n'accepte que le dépôt officiel WindowsOptimizer (branche `main` ou commit SHA-1 explicite), impose HTTPS, un délai de téléchargement, le format ASCII/CRLF et des marqueurs internes du batch. Son mode `-VerifyOnly` teste la chaîne sans élévation ni modification système. NVIDIA Profile Inspector, son profil et SetTimerResolution utilisent la même racine de publication. SetTimerResolution est téléchargé dans un fichier temporaire, vérifié comme exécutable PE puis déplacé dans `Program Files` ; `curl`, BITS et PowerShell sont essayés en secours. MAS et WinUtil restent des outils externes explicitement sélectionnés, limités à leurs deux URLs autorisées ; le fichier téléchargé est refusé s'il s'agit d'une page HTML/XML ou si sa signature Authenticode existe sans être valide. Visual C++ et DirectX sont contrôlés par taille et signature Authenticode Microsoft avant exécution. Les outils du dépôt sont contrôlés surtout par source, chemin, taille et compatibilité, sans validation Authenticode systématique.

**Q : Certains outils sont-ils exécutés automatiquement ?**
R : NVIDIA Profile Inspector et son profil peuvent être exécutés automatiquement en Gaming sur un GPU NVIDIA compatible. SetTimerResolution peut être installé, ajouté au démarrage et lancé en MaxPerf. La configuration O&O, les modèles de `Game Configs\` et les autres outils Timer & Interrupt ne sont pas lancés automatiquement par le batch actuel.

**Q : Credential Guard et LSA peuvent-ils rester actifs malgré le script ?**
R : Oui. Gaming et Performance Max conservent LSA Protection avec `RunAsPPL=1` (PPL actif sans verrou UEFI — la valeur `2` pose un verrou UEFI quasi irréversible), suppriment `RunAsPPLBoot` et désactivent Credential Guard avec `LsaCfgFlags=0`. Défaut Windows restaure la capture précédente ; sans capture, il applique la même base : `RunAsPPL=1` et `RunAsPPLBoot` supprimé. Une stratégie d'entreprise ou un verrou UEFI antérieur peut néanmoins imposer un autre état.

**Q : Quelles fonctionnalités essentielles sont conservées ?**
R : Windows Update, Microsoft Store et WebView2 ne sont pas volontairement supprimés. Les fonctions dépendantes d'Edge, OneDrive ou d'une autre application retirée peuvent néanmoins changer.

---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
