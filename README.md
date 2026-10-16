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

L'ouverture du script ne modifie plus les fichiers de Valorant. Le menu **[G] → [V]** permet d'appliquer explicitement le profil fourni ou de restaurer les fichiers `.winopt-backup`, jeu fermé. Le profil concerne tous les comptes Valorant trouvés dans le profil du compte Windows élevé affiché : plein écran, qualité minimale, VSync/HDR désactivés ; les résolutions et autres clés non ciblées sont conservées. La restauration remplace les fichiers entiers par leur sauvegarde initiale et écrase donc les modifications ultérieures. Aucun gain de FPS n'est garanti.

### Premier parcours

1. Créez un point de restauration avec **[R]**.
2. Choisissez **[O] → [1] Recommandé** pour un PC de jeu, de bureau et d'usage général.
3. Choisissez séparément confidentialité, navigateurs en arrière-plan, Widgets et runtimes. Le récapitulatif précède toute écriture de ce parcours ; **M** ou l'annulation finale ne change aucun de ces réglages.
4. Le parcours sauvegarde les valeurs ciblées avant écriture, puis les relit. Une valeur refusée est signalée et rend le résultat partiel. La prise en compte par Windows ou le navigateur reste dépendante de sa version, de son édition et des stratégies prioritaires.
5. Fermez et rouvrez les navigateurs. Une reconnexion ou un redémarrage peut être requis pour les Widgets.
6. **[O] → [2] Avancé** conserve les anciens profils Gaming/Normal et Performance max/Eco, après un avertissement explicite. Les sections **[1] à [7]** sont également avancées.

### Parcours recommandé et retour arrière

Certains choix de confidentialité, de navigateurs et de Widgets utilisent des stratégies **pour tous les comptes Windows**. La capture appartient au compte qui exécute le processus élevé ; sa restauration peut également modifier les réglages des autres comptes. Des captures prises par plusieurs comptes peuvent se contredire : elles ne constituent pas des états indépendants pour chaque utilisateur.

Les valeurs `HKCU`, les applications retirées individuellement et les fichiers Valorant visent le **compte qui exécute le processus élevé**, affiché avant les choix. Si l'UAC utilise les identifiants d'un autre administrateur, c'est son profil qui est concerné, pas celui de la personne connectée. Utilisez le compte dont le profil doit changer.

Le parcours recommandé préserve Defender, SmartScreen, l'UAC, VBS/HVCI, les pilotes GPU/réseau, les préférences d'affichage et d'accessibilité, les plans d'alimentation, la compression mémoire et la veille. Il ne supprime aucune application, ne désactive aucun service ni tâche, et ne modifie pas `hosts` ou le nettoyage automatique.

| Choix | Effet et limite |
|---|---|
| Confidentialité | Diagnostics facultatifs, identifiant publicitaire, personnalisation, suggestions et highlights de recherche réduits. `AllowTelemetry=1` sur Home/Pro et `0` sur Enterprise/Education ; un `0` préexistant est conservé. Home et certaines stratégies ont des limites d'application. Edge `DiagnosticData=0` et `PersonalizationReportingEnabled=0`, Chrome `MetricsReportingEnabled=0`. Cela ne prouve pas l'absence de toute collecte. |
| Navigateurs | Edge : démarrage rapide et arrière-plan coupés, préchargements limités. Chrome : mode arrière-plan coupé. Les extensions/notifications après fermeture peuvent s'arrêter et l'ouverture suivante peut être plus lente. WebView2 reste disponible pour les applications. |
| Widgets | Stratégie Windows 11 `Dsh\AllowNewsAndInterests=0` ; Windows 10 `Windows Feeds\EnableFeeds=0`. Sur certaines versions, Windows refuse l'écriture même en administrateur : le script le signale, sans désactiver une protection pour forcer le réglage. |
| Runtimes, facultatifs | Vérification/installation des redistribuables Visual C++ et DirectX officiels signés. Les logiciels installés ne sont pas annulés par la restauration des valeurs. |

**[G] → [9] → [1]** restaure uniquement les valeurs ou absences sauvegardées par ce nouveau parcours. La première capture est conservée sous `%ProgramData%\WindowsOptimizer\Backups\recommended-<SID>.json`, même après restauration, pour permettre un nouvel essai. Elle est liée au PC et à l'utilisateur du processus élevé, même lorsque les valeurs sauvegardées sont communes à tous les comptes. Une capture manquante, incompatible ou illisible bloque l'action ; un type de registre inattendu est préservé et signalé. Cette sauvegarde ne remplace pas les sauvegardes de fichiers ni un point de restauration. Une nouvelle exécution conserve cette même base initiale ; elle ne la renouvelle pas automatiquement.

**Pour un PC ayant déjà exécuté l'ancien script**, cette capture décrit son état déjà modifié. **[G] → [9] → [2]** propose de retirer le refus NTFS Everyone sur `store.db` et de réactiver les tâches fonctionnelles précédemment ciblées : famille, synchronisation, Work Folders, licences et diagnostics utiles. Sans capture ancienne, ce sont des corrections proposées, pas une restauration exacte. Les refus Everyone personnalisés sur ce fichier seraient aussi retirés ; la confirmation le précise. Les autres anciens réglages restent à traiter séparément. Defender, UAC et protections noyau ont chacun leur action de récupération distincte. Aucun mode ne récupère les données supprimées.

Le parcours avancé installe toujours les runtimes manquants sans question supplémentaire : détection et installation s'exécutent en arrière-plan pendant les sections système/mémoire/disques/GPU, puis le parcours attend avant le réseau. Les signatures Microsoft sont vérifiées avant exécution. Les journaux d'échec restent sous `%TEMP%\WinOpt_Runtimes_*\runtime.log`. Le menu runtimes et le parcours recommandé utilisent le premier plan. Le comportement de détection VC++/DirectX n'est pas modifié.

---

## 🛠️ Guide des fonctionnalités

### 🌟 Profils avancés à deux axes ([O] → [2])

Le parcours **[O] → [2] Avancé** repose sur **deux axes indépendants** qui définissent 4 combinaisons possibles. Le script vous pose quelques questions (profil + options) et en déduit automatiquement la configuration demandée.

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
| **[1]** |   **ECO**  | Plan Équilibré sans supprimer les plans OEM, hibernation et démarrage rapide préservés, compression mémoire active et économies d'énergie réseau/USB restaurées. Les propriétés réseau modifiées par MaxPerf reviennent au défaut du pilote.   |
| **[2]** | **MAX PERF** | Plan Ultimate Performance, économies d'énergie réseau/USB ciblées désactivées et compression mémoire coupée au-delà de 8 Go de RAM. En Gaming, le tuning réseau devient plus agressif. Le preset timer reste expérimental et réversible via Eco. |

> **Sur PC fixe comme portable** : les deux questions sont posées, pour permettre un desktop silencieux/économe ou un laptop branché en **MAX PERF**.
> **Sur PC portable** : la combinaison **GAMING + ECO** est autorisée avec un avertissement — l'avertissement est en réalité posé sur **tout** PC, pas seulement les portables. Nagle/DelACK revient au comportement Windows natif (batterie avant tout), tandis qu'initialRTO=3000 et maxsynretransmissions=2 restent appliqués par l'axe Gaming ; les optimisations GPU/input/CPU restent agressives.
>
> Les quatre combinaisons remplacent leurs valeurs exclusives gérées. Elles ne retrouvent pas nécessairement les préférences personnalisées antérieures.
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

- **[1] Système** : Optimisation du noyau (Kernel), de la planification CPU et réduction des diagnostics et suggestions, avec limites selon édition. Sous Windows 11, tous les profils désactivent les suggestions et les applications récemment ajoutées (`Start_IrisRecommendations=0`, `ShowRecentList=0`) ; Gaming masque aussi « Recommandations » et « Tout », tandis que Normal supprime uniquement ces politiques de masquage. Sur **portable + Normal + Eco**, `DiagLog` reste actif et `SEMgrSvc` reste en demarrage manuel afin de preserver les diagnostics/batterie et la page moderne Alimentation et batterie. **Ce que la section retire volontairement** : les suggestions dans la zone de recherche et dans le menu Démarrer (`DisableSearchBoxSuggestions=1`, `DisableSearchSuggestions=1`) ainsi que la liste des fichiers récents de l'Explorateur (`ShowFrequent=0`). Seuls les Jump Lists, l'indexation Windows et la recherche comme fonction de Windows restent disponibles. Les tâches de diagnostic sont traitées en un seul passage avec relecture de leur état ; les tâches absentes et les refus sont distingués, et un refus rend le bilan système partiel. Les instances déjà en cours ne sont pas interrompues. La section pose aussi des réglages navigateur communs aux profils : QUIC et accélération matérielle activés, préchargement des pages activé et verrouillé dans Edge (`NetworkPredictionOptions=0`), DNS sur HTTPS Cloudflare en mode `automatic` (chiffré quand disponible, repli DNS normal sur les réseaux filtrés), démarrage rapide et arrière-plan Edge conservés dans ce profil avancé. Le parcours recommandé propose de les couper. Le refus NTFS sur la base du Store, la modification des inscriptions COM pour F1, la politique de nettoyage automatique et les changements forcés d’hibernation/Modern Standby sont retirés des profils.
- **[2] Mémoire** : Ajustement de la gestion RAM et de la compression mémoire selon l'énergie, avec Prefetch piloté par l'usage.
- **[3] Disques** : TRIM et maintenance Windows conservés ; chemins longs activés en Gaming et rendus à `LongPathsEnabled=0` en Normal, comme sur le stock mesuré.
- **[4] GPU** : Configuration des priorités graphiques et des options de latence prises en charge par le pilote.
- **[5] Réseau** : pile TCP Gaming ou stock mesuré en Normal, puis réglages de la carte selon l'énergie. Eco privilégie stabilité et autonomie ; Gaming+MaxPerf applique les options de latence les plus agressives que le pilote expose. En Gaming, une stratégie QoS marque aussi le trafic UDP/TCP de Fortnite en DSCP 46.
- **[6] Input** : Ajustement de la réponse clavier/souris, des files d'entrée et du mode MSI des contrôleurs compatibles.
- **[7] Énergie** : Gestion des plans d'alimentation et déblocage de l'Ultimate Performance, avec choix d'usage pour appliquer le bon tuning NIC.
- **[8] Sécurité** : Choix entre 3 modes pour VBS/HVCI/CFG/SEHOP, mitigations processeur, LSA/Credential Guard, hyperviseur BCD et liste de pilotes vulnérables.

| Mode                          |  Sécurité VBS / HVCI  | Anti-Cheats (Valorant / FACEIT) | Usage Recommandé                                               |
|-------------------------------|:----------------------:|:-------------------------------:|----------------------------------------------------------------|
| **1 - Défaut Windows**        | ✅ Selon l'état Windows |          Selon Windows/jeu  | Capture restaurée ; sinon base stock Windows 11 25H2 appliquée |
| **2 - Gaming (avancé)** |        ✅ Activé |     ⚠️ Selon les jeux  | Réduction des protections CPU, SEHOP et pilotes      |
| **3 - Performance Max ⚠️**    |      ❌ Désactivé  |        ⚠️ Selon les jeux | Réglages les plus agressifs, avec sécurité réduite             |

> ### 💡 Vue d'ensemble des 3 modes
>
> * **Gaming (avancé)** : **Active** VBS / HVCI — y compris sur une machine où ils étaient coupés — et conserve **LSA Protection** (`RunAsPPL=2`, c'est-à-dire PPL actif **sans** écriture de variable UEFI — valeur que Microsoft n'applique qu'à partir du build 22H2) pour limiter les conflits avec les anti-cheats modernes, laisse **CFG** à `NOTSET` (défaut Windows), désactive **SEHOP**, réduit les mitigations CPU et demande la désactivation de la blocklist.
> * **Défaut Windows** : restaure le snapshot capturé avant un profil de sécurité. Sans snapshot, il applique la base stock mesurée (FeatureSettings=0, `RunAsPPL=2`, `RunAsPPLBoot` supprimé, blocklist de pilotes=1) et retire les overrides de l'outil.
> * **Performance Max ⚠️ (Déconseillé)** : Désactive VBS, HVCI et SEHOP, conserve CFG et **LSA Protection** (`RunAsPPL=2`, PPL actif sans écriture de variable UEFI), réduit les mitigations CPU et demande la désactivation de la blocklist.

> ### 🔍 Notes & Précisions techniques
>
> * **Champs modifiés** : les modes *Gaming* et *Performance Max* modifient uniquement CFG et SEHOP dans `MitigationOptions` pour préserver les autres mitigations de processus. *Défaut Windows* restaure les valeurs capturées ou applique la base stock 25H2 lorsqu'aucun snapshot n'existe.
> * **Mitigations CPU (Spectre/Meltdown)** : `33554435/3` (0x2000003) correspond aux modes *Gaming* et *Perf Max*. Le mode *Défaut Windows* ne force plus `0/3` : il restaure l'état précédent ou laisse Windows gérer l'absence d'override.
> * **Blocklist de pilotes** : *Gaming* conserve HVCI actif. Si HVCI, Smart App Control ou le mode S restent actifs, Windows peut continuer d'imposer la blocklist même si la désactivation a été demandée.
> * **Application automatique** : dans **Tout optimiser → Avancé**, la question *Protections Windows* applique directement les réglages *Défaut Windows* en usage Normal ou *Gaming* en usage Gaming. Elle ne demande pas de choisir un second mode de sécurité. *Performance Max* reste accessible séparément depuis le menu Sécurité.

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
| **[4]** | **IA & Widgets**     | Activation ou désactivation de Copilot, de l'IA du Bloc-notes et des Widgets sur Windows 11. Recall dépend de la version/édition de Windows ; le désactiver supprime les instantanés déjà enregistrés. |
| **[5]** | **OneDrive**         | Désinstallation complète et arrêt de la synchronisation. `%USERPROFILE%\OneDrive` est supprimé, sauf si Bureau, Documents ou Images y sont rangés : le dossier est alors conservé. |
| **[6]** | **Microsoft Edge**   | Désinstallation de Microsoft Edge avec WebView2 préservé. Recherche, Widgets, météo et certaines PWA peuvent être affectés.                                            |
| **[7]** | **Runtimes**         | Installation du Visual C++ v14 actuel et de DirectX June 2010. Les téléchargements VC++ x86/x64 sont parallélisés quand les deux manquent et leurs signatures sont vérifiées dans un seul processus PowerShell ; DirectX utilise `curl` en priorité avec BITS/PowerShell en secours. |
| **[8]** | **Applications** | Choix individuel pour le compte élevé affiché ; ancien lot pour tous les comptes accessible par **[A] Avancé**. |
| **[9]** | **Récupération** | Restauration du parcours recommandé, corrections ciblées des anciens blocages et accès aux réactivations de sécurité. |
| **[V]** | **Valorant** | Application explicite du profil fourni ou restauration des fichiers sauvegardés, jeu fermé. |
| **[M]** | **Retour**           | Retour au menu principal.                                                                                                                                              |

## ❓ FAQ (Foire aux questions)

### 🏠 Installation & Sécurité

**Q : La commande** `irm` **ne démarre pas le launcher ?**

R : Exécutez-la dans **Windows PowerShell** ou **PowerShell**, pas dans `cmd.exe`. En cas d'erreur réseau ou d'URL, la commande affiche immédiatement l'erreur de `Invoke-RestMethod`. Depuis un clone, lancez `.\launcher.ps1 -VerifyOnly` pour contrôler le launcher et le batch sans UAC ni modification système.

**Q : Est-ce que ce script peut provoquer une incompatibilité ?**
R : Oui, comme tout outil qui modifie des stratégies, services, pilotes ou paramètres réseau. Créez d'abord un point de restauration, choisissez le parcours **[O] → [1] Recommandé** en cas de doute et évitez les options de sécurité ou de désinstallation dont vous n'avez pas besoin.

**Q : Mon antivirus détecte le script, pourquoi ?**  
R : Les commandes d'administration, les téléchargements et les modifications de sécurité peuvent déclencher une alerte. Ne supposez pas automatiquement qu'il s'agit d'un faux positif : vérifiez le dépôt, le diff et les fichiers téléchargés avant exécution.

**Q : Puis-je lancer le script plusieurs fois ?**  
R : Oui pour les profils principaux : Gaming/Normal et Performance Max/Eco remplacent leurs réglages exclusifs et nettoient plusieurs vestiges connus. Un parcours **Tout optimiser → Avancé** n'exécute chaque section qu'une fois, mais vous pouvez relancer ensuite une section depuis le menu. Les suppressions, désinstallations, caches et autres actions destructives ne sont pas toutes répétables ni réversibles. Un point de restauration ne récupère pas nécessairement les fichiers supprimés, les désinstallations, la corbeille, les caches ou `Windows.old`.

### 🎮 Performance & Gaming

**Q : Quel gain de FPS puis-je espérer ?**  
R : Le gain varie selon le matériel et la charge. Il peut surtout se manifester par une latence ou une stabilité plus régulière ; aucun gain de FPS n'est garanti.

**Q : Que fait le preset timer de Performance Max ?**
R : Les profils avancés suppriment les overrides BCD `useplatformclock`/`useplatformtick`/`tscsyncpolicy`. Performance Max ajoute `disabledynamictick=yes` et lance `SetTimerResolution` via un raccourci du dossier de démarrage, tandis qu'Eco supprime aussi cet override, retire le raccourci et réactive HPET s'il avait été désactivé par une ancienne version du script. Microsoft classe ces options comme des réglages de débogage : le preset reste expérimental et aucun gain universel n'est garanti. Un redémarrage est nécessaire après le changement.

**Q : Pourquoi modifier les mitigations Spectre/Meltdown (Option 8) ?**
R : Certaines protections ajoutent une charge selon le processeur et la charge de travail. Gaming active VBS/HVCI (même s'ils étaient coupés), laisse CFG au défaut Windows, désactive SEHOP, réduit les mitigations CPU et demande la désactivation de la blocklist. HVCI peut néanmoins maintenir cette blocklist active. Performance Max désactive VBS/HVCI/SEHOP, laisse CFG au défaut Windows, réduit les mitigations CPU et demande aussi la désactivation de la blocklist. Défaut Windows restaure le snapshot de sécurité ou applique la base stock 25H2 mesurée sans snapshot. Les trois modes suppriment la surcharge BCD `hypervisorlaunchtype` lorsqu'ils la gèrent ; les stratégies et verrous externes restent prioritaires.

**Q : Changer plusieurs fois de mode de sécurité laisse-t-il les anciens réglages actifs ?**
R : Le premier passage du profil de sécurité Gaming ou Performance Max capture les valeurs ciblées et la valeur BCD avant modification. Défaut Windows réimporte ensuite ce snapshot de façon ciblée ; sans snapshot, il retire les overrides connus puis applique les quelques valeurs stock mesurées et explicitement gérées (`FeatureSettings=0`, `RunAsPPL=2`, `RunAsPPLBoot` supprimé, blocklist=1). Une stratégie d'entreprise peut cependant réimposer une valeur extérieure au script.

**Q : Performance Max désactive-t-il toutes les protections ?**
R : Non. Performance Max désactive VBS, HVCI, SEHOP et Credential Guard local/policy, laisse CFG à `NOTSET` (dont le défaut Windows effectif est ON), demande la désactivation de la blocklist, réduit les mitigations CPU, mais conserve LSA Protection avec `RunAsPPL=2` (PPL actif sans écriture de variable UEFI) et laisse les Kernel Shadow Stacks inchangées. Smart App Control, le mode S ou une stratégie peuvent maintenir la blocklist active. La valeur BCD `hypervisorlaunchtype` est supprimée (`deletevalue`). Une ancienne configuration Credential Guard verrouillée en UEFI peut nécessiter une procédure avec confirmation physique pour retirer ce verrou.

**Q : Quelle différence entre Gaming et Performance Max pour les anti-cheats ?**
R : Gaming active VBS/HVCI et laisse CFG au défaut Windows afin de limiter les incompatibilités. Performance Max désactive VBS/HVCI ; sa compatibilité dépend donc du jeu, de l'anti-cheat et de leur version. Certains exigent aussi TPM, Secure Boot, la virtualisation ou IOMMU.

**Q : Est-ce compatible avec tous les jeux en ligne ?**
R : Aucune compatibilité universelle ne peut être garantie. Le mode Gaming active VBS/HVCI et conserve CFG pour limiter les conflits avec les anti-cheats modernes, mais désactive SEHOP — sans garantir les exigences futures de chaque jeu ou anti-cheat.

### 🌐 Maintenance & Divers

**Q : Est-ce que le nettoyage (Option N) supprime mes documents ?**  
R : Il ne cible pas directement les dossiers Documents/Images/Vidéos actuels. Il vide toutefois la corbeille et supprime des caches, dumps, rapports d'erreur et journaux archivés. Si `Windows.old` existe, sa suppression définitive est proposée séparément et peut inclure d'anciennes données utilisateur. Les journaux Event Viewer actifs, l'historique Windows Update et les autres fichiers de récupération sont conservés.

**Q : Puis-je réinstaller OneDrive ou Edge plus tard ?**  
R : Oui. OneDrive se réinstalle via `winget install Microsoft.OneDrive` ou depuis le site Microsoft. Edge peut être réinstallé manuellement, mais les politiques Edge Update posées lors de sa suppression peuvent devoir être retirées si l'installateur les respecte. Les données supprimées pendant la désinstallation ne sont pas récupérées.

**Q : Quels "Bloatwares" sont supprimés ?**  
R : **[G] → [8]** propose séparément Copilot moderne, Clipchamp, Teams, le nouvel Outlook, Solitaire et News pour le compte élevé affiché. Une application utile au quotidien n’est pas retirée parce qu’elle est installée. La présence puis l’absence sont relues ; les autres comptes et le provisionnement sont conservés. La désinstallation peut perdre des données locales ; le Microsoft Store permet une réinstallation, sans récupération automatique de ces données. Les fonctions Copilot d’Edge, du Web et de Microsoft 365 sont distinctes de l’application moderne. L’ancien lot ci-dessous reste accessible par **[A] Avancé** avec sa confirmation pour tous les utilisateurs.

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
R : Le launcher n'accepte que le dépôt officiel WindowsOptimizer (branche `main` ou commit SHA-1 explicite), impose HTTPS, un délai de téléchargement, le format ASCII/CRLF et des marqueurs internes du batch. Son mode `-VerifyOnly` teste la chaîne sans élévation ni modification système. NVIDIA Profile Inspector, son profil et SetTimerResolution utilisent la même racine de publication. SetTimerResolution est téléchargé dans un fichier temporaire, vérifié comme exécutable PE puis déplacé dans `Program Files` ; `curl`, BITS et PowerShell sont essayés en secours. Les runtimes Visual C++ et DirectX utilisent désormais la même stratégie réseau rapide (`curl` en priorité, BITS puis PowerShell en secours), avec téléchargement parallèle x86/x64 pour VC++ lorsque les deux architectures manquent. Chaque exécutable runtime est contrôlé par taille et signature Authenticode Microsoft avant exécution. MAS et WinUtil restent des outils externes explicitement sélectionnés, limités à leurs deux URLs autorisées ; le fichier téléchargé est refusé s'il s'agit d'une page HTML/XML ou si sa signature Authenticode existe sans être valide. Les outils du dépôt sont contrôlés surtout par source, chemin, taille et compatibilité, sans validation Authenticode systématique.

**Q : Visual C++ réclame un ancien fichier MSI introuvable ?**
R : Le cache d'installation de l'ancienne version est incomplet. Le script conserve les journaux VC++ dans `%TEMP%\WinOpt_VC14_<architecture>_*.log` et signale un échec de l'installateur même si des DLL sont présentes. Récupérez le redistribuable Microsoft correspondant exactement à la version demandée et utilisez-le pour réparer l'installation, puis réessayez le paquet actuel. Si la désinstallation est elle aussi bloquée, consultez [l'outil de dépannage Microsoft](https://support.microsoft.com/help/17588) pour retirer uniquement l'entrée défectueuse avant de réinstaller. Les quatre composants « X86 Minimum Runtime », « X86 Additional Runtime », « X64 Minimum Runtime » et « X64 Additional Runtime » sont distincts : traitez uniquement ceux qui réclament un MSI absent, avec la version indiquée par la fenêtre, puis réinstallez le redistribuable de chaque architecture concernée. Ne supprimez pas tout `Package Cache` ni les autres versions de Visual C++. Les runtimes déjà détectés sont conservés : ce parcours n'effectue pas leur mise à jour forcée et ne garantit pas l'intégrité de leur cache MSI.

**Q : Certains outils sont-ils exécutés automatiquement ?**
R : NVIDIA Profile Inspector et son profil peuvent être exécutés automatiquement en Gaming sur un GPU NVIDIA compatible. SetTimerResolution peut être installé, ajouté au démarrage et lancé en MaxPerf. La configuration O&O, les modèles de `Game Configs\` et les autres outils Timer & Interrupt ne sont pas lancés automatiquement par le batch actuel.

**Q : Credential Guard et LSA peuvent-ils rester actifs malgré le script ?**
R : Oui. Gaming et Performance Max conservent LSA Protection avec `RunAsPPL=2` — PPL actif **sans** écriture de variable UEFI, `1` étant au contraire le mode *avec* variable UEFI, non réversible par registre ni par stratégie — suppriment `RunAsPPLBoot` et désactivent Credential Guard avec `LsaCfgFlags=0`. `2` est aussi la valeur stock mesurée sur une installation neuve. ⚠️ Microsoft précise que cette valeur **n'est appliquée qu'à partir du build Windows 11 22H2** : sur Windows 10 ou un Windows 11 antérieur, écrire `2` n'active pas PPL. Le script ne filtre pas sur la version, donc sur ces systèmes le mode announced n'est pas garanti. Défaut Windows restaure la capture précédente ; sans capture, il applique la même base : `RunAsPPL=2` et `RunAsPPLBoot` supprimé. ⚠️ Si une version antérieure du script a déjà été exécutée sur cette machine, `RunAsPPL=1` a pu écrire la variable dans le firmware : vérifier et, le cas échéant, retirer ce verrou avec l'outil `LsaPplConfig.efi` de Microsoft depuis un environnement de récupération. Une stratégie d'entreprise peut néanmoins imposer un autre état.

**Q : Quelles fonctionnalités essentielles sont conservées ?**
R : Windows Update, Microsoft Store et WebView2 ne sont pas volontairement supprimés. Les fonctions dépendantes d'Edge, OneDrive ou d'une autre application retirée peuvent néanmoins changer.

---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>

### Références vérifiées pour les changements

Sources consultées le 16 octobre 2026 et confrontées aux réglages du script. Les essais Windows vérifient les chemins décrits, sans démontrer un gain de performances :

- [Diagnostics Windows, niveaux et éditions](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system#allowtelemetry) ; [gestion des connexions et de la personnalisation](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services).
- [Widgets](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-newsandinterests) ; [Copilot actuel et limites de la politique legacy](https://learn.microsoft.com/en-us/windows/client-management/manage-windows-copilot).
- [Diagnostics Edge](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/diagnosticdata), [personnalisation](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/personalizationreportingenabled), [arrière-plan](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/backgroundmodeenabled) et [Chrome BackgroundModeEnabled](https://chromeenterprise.google/policies/#BackgroundModeEnabled).
- Croisement communautaire : [Win11Debloat](https://github.com/Raphire/Win11Debloat), [WinUtil](https://github.com/ChrisTitusTech/winutil). Leurs listes ne prouvent ni le besoin de désactiver une fonction ni un gain de performance.

La relecture du registre prouve le stockage, pas la prise en compte de toutes les politiques ni un gain RAM/FPS. Vérifiez aussi `edge://policy`, `chrome://policy` et les Paramètres Windows. Les stratégies d'entreprise et certaines protections Windows peuvent imposer une autre valeur ; aucun contournement automatique n'est effectué.
