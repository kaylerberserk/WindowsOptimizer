<div align="center">

# WINDOWS OPTIMIZER

### 🚀 Optimisation modulaire pour Windows 11

*Des profils de performance et des outils de maintenance dans un script portable.*

![Windows](https://img.shields.io/badge/Windows-11-0078D6?style=for-the-badge&logo=windows&logoColor=white)

</div>

Windows 11 est la seule cible prise en charge. Certaines options dépendent de la version de Windows, du matériel et des pilotes ; sur un PC professionnel ou géré par une organisation, des règles peuvent empêcher les modifications.

> Le script modifie réellement Windows. Certaines options réduisent les protections ; les désinstallations et le nettoyage peuvent supprimer des données. Un point de restauration ne remplace pas une sauvegarde de vos fichiers.

## 🚀 Démarrage rapide

Collez cette commande dans **PowerShell**, puis acceptez la demande d'administration :

```powershell
irm https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1 | iex
```

Le lanceur télécharge la version publiée du script et l'ouvre dans une fenêtre administrateur. Vous pouvez aussi [télécharger All in One.cmd](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et l'exécuter en tant qu'administrateur.

### Premier parcours

1. Créez un point de restauration avec **[R]**.
2. Choisissez **[O] Tout optimiser**, puis indiquez votre usage et votre priorité d'énergie. Les [profils](#usage-et-énergie--tout-optimiser) sont indépendants, sur PC fixe comme portable.
3. Répondez aux cinq questions : protections Windows, Defender, animations, IA et UAC. **N** conserve l'option concernée ; **M** annule. Gardez les protections actuelles en cas de doute, y compris pour Defender et l'UAC : les désactiver réduit la protection du PC.
4. Vérifiez le récapitulatif : **O** lance, **R** repose les cinq questions, **M** annule. Aucun choix de ce parcours n'est appliqué avant confirmation.

Pour des préférences limitées avec sauvegarde ciblée, utilisez **[G] → [P]** ci-dessous. Les sections **[1] à [7]** restent accessibles séparément, après avertissement. Les limites du [retour arrière](#retour-arrière) s'appliquent aux profils globaux.

### Préférences Windows avec sauvegarde — [G] → [P]

Les stratégies de confidentialité, de navigateurs et de Widgets peuvent concerner **tous les comptes Windows**. Une restauration peut donc modifier les réglages d'autres comptes ; des captures prises par plusieurs comptes peuvent se contredire.

Les valeurs `HKCU`, les applications retirées individuellement et les fichiers Valorant visent le **compte du processus élevé**, affiché avant les choix. Si l'UAC demande les identifiants d'un autre administrateur, c'est son profil qui change. Utilisez le compte à modifier.

<details>
<summary>Effets des quatre choix, sauvegarde et récupération</summary>

**[G] → [P]** pose quatre questions puis demande confirmation. Il préserve les protections Windows, les pilotes, l'affichage, l'accessibilité, les plans d'alimentation, la compression mémoire et la veille. Il ne supprime aucune application, ne désactive aucun service ni tâche, et ne modifie ni `hosts` ni le nettoyage automatique.

| Choix | Effet et limite |
|---|---|
| Confidentialité | Diagnostics facultatifs, identifiant publicitaire, personnalisation, suggestions et highlights de recherche réduits. `AllowTelemetry=1` sur Home/Pro et `0` sur Enterprise/Education ; un `0` préexistant est conservé. Home et certaines stratégies ont des limites d'application. Edge `DiagnosticData=0` et `PersonalizationReportingEnabled=0`, Chrome `MetricsReportingEnabled=0`. Cela ne prouve pas l'absence de toute collecte. |
| Navigateurs | Edge : démarrage rapide et arrière-plan coupés, préchargements limités. Chrome : mode arrière-plan coupé. Les extensions/notifications après fermeture peuvent s'arrêter et l'ouverture suivante peut être plus lente. WebView2 reste disponible pour les applications. |
| Widgets | Stratégie Windows 11 `Dsh\AllowNewsAndInterests=0`. Sur certaines versions, Windows refuse l'écriture même en administrateur : le script le signale, sans désactiver une protection pour forcer le réglage. |
| Runtimes, facultatifs | Vérification/installation des redistribuables Visual C++ et DirectX officiels signés. Les logiciels installés ne sont pas annulés par la restauration des valeurs. |

La relecture du registre prouve le stockage, pas la prise en compte de toutes les politiques. Vérifiez aussi `edge://policy`, `chrome://policy` et les Paramètres Windows : les stratégies d'entreprise et certaines protections Windows peuvent imposer une autre valeur, sans contournement automatique.

**[G] → [9] → [1]** restaure les valeurs ou absences sauvegardées par ce parcours. Chaque valeur est capturée à sa première application : un groupe choisi plus tard est capturé à ce moment-là. La capture reste sous `%ProgramData%\WindowsOptimizer\Backups\recommended-<SID>.json`, même après restauration. Elle est liée au PC et au compte élevé, y compris pour les stratégies communes à tous les comptes. Une capture absente, incompatible ou illisible bloque la restauration ; un type de registre inattendu est préservé et signalé.

Sur un PC déjà modifié par une version précédente du script, la capture conserve cet état modifié. **[G] → [9] → [2]** propose de retirer le refus NTFS Everyone sur `store.db` et de réactiver les tâches fonctionnelles anciennement ciblées : famille, synchronisation, Work Folders, licences et diagnostics utiles. Ce sont des corrections, sans restauration exacte ni traitement des autres anciens réglages. La confirmation avertit que les refus Everyone personnalisés seraient aussi retirés. Defender, UAC et protections noyau ont des actions de récupération distinctes. Aucun mode ne récupère les données supprimées.

</details>

### Installation des runtimes

<details>
<summary>Installation automatique, contrôles et journaux</summary>

**Tout optimiser** installe les composants manquants en arrière-plan pendant les sections système/mémoire/disques/GPU, puis attend leur fin avant le réseau. Si ce lancement échoue, il reprend au premier plan, comme les menus runtimes et **[G] → [P]**. Les signatures Microsoft et l'installation restent contrôlées ; les échecs indiquent le journal `%TEMP%\WinOpt_Runtimes_*\runtime.log`.

Visual C++ est considéré présent à partir de 14.40 pour chaque architecture ; DirectX June 2010 exige toutes ses DLL. Sinon, l'installateur officiel est lancé.

</details>

## 🛠️ Profils et fonctionnalités

### Usage et énergie — Tout optimiser

Usage et énergie se choisissent séparément. Les profils changent des réglages globaux Windows et pilotes ; les sections **[1] à [7]** demandent seulement les profils utiles.

| Choix | Rôle |
|---|---|
| **Gaming** | Applique les réglages orientés jeu et latence pour la carte graphique, le clavier, la souris et le réseau. |
| **Normal** | Restaure les réglages exclusifs gérés par le profil Gaming. |
| **Eco** | Utilise le plan Équilibré et privilégie les économies d'énergie. |
| **Performance Max** | Privilégie les performances, avec davantage de consommation et de chaleur possibles. Le réglage des minuteries système reste expérimental. |

Gaming convient aussi à un PC utilisé pour jouer et travailler. Vous pouvez le combiner avec Eco, ou choisir Normal avec Performance Max. **Normal + Eco** est le choix le plus conservateur parmi ces profils ; changer de profil ne restaure que ses réglages exclusifs pris en charge, sans remettre Windows à zéro ni réinstaller les applications.

### Effets à connaître dans les profils

- Système : réduit les suggestions, les fichiers récents de l'Explorateur, l'historique de recherche, AutoPlay et les diagnostics/personnalisation Edge ; coupe l'atténuation audio pendant les appels. Les Jump Lists, l'indexation et la recherche Windows restent disponibles. Normal/Eco ne rétablit pas tous ces réglages communs. Les tâches absentes et refusées sont distinguées ; un refus de service ou de tâche rend le bilan partiel. Les instances de tâches déjà lancées ne sont pas interrompues.
- Navigateurs : accélération matérielle et QUIC activés, DNS sur HTTPS Cloudflare en mode automatic avec repli normal, préchargements Edge et activité Edge/Chrome après fermeture conservés. **[G] → [P]** permet de limiter cet arrière-plan.
- Portable Normal + Eco : DiagLog et le service d'alimentation moderne sont préservés. Le refus NTFS sur la base du Store, les changements COM de F1, le nettoyage automatique et les modifications forcées d'hibernation/Modern Standby sont retirés des profils.
- Réseau Gaming + Performance Max : économies d'énergie réduites et réglages de latence appliqués aux propriétés exposées par le pilote, dont MIMO sans économie, U-APSD désactivé et mode 40 MHz non bloqué sur les adaptateurs Intel compatibles. Le résultat dépend du pilote.
- Performance Max : compression mémoire coupée au-delà de 8 Go de RAM, économies HIPM/DIPM et parking des disques désactivés ; Eco rend ces deux réglages de stockage à Windows. Le preset timer reste expérimental et réversible via Eco.
- Performance Max applique aussi un profil de charge Defender : facteur CPU minimal, priorité basse, scans planifiés coupés, analyse réseau, USB et archives désactivée. Les valeurs précédentes sont capturées avant application ; le mode Défaut Windows les rend, ou applique les valeurs par défaut documentées si la capture manque. La protection temps réel n'est pas modifiée.
- Fichier hosts : le bloc de télémétrie fait signaler `hosts` par Defender comme `SettingsModifier:Win32/PossibleHostsFileHijack`, un faux positif documenté par Microsoft. Quand l'écriture du bloc réussit, le script exclut ce seul fichier de l'analyse Defender ; l'exclusion ne couvre ni le dossier `etc` ni un dossier parent, et n'est pas retirée par la restauration.

### Menu principal

| Touche | Section | Fonction |
|---|---|---|
| **[O]** | Tout optimiser | Pose les questions d’usage, d’énergie et d’options Windows, puis demande confirmation. |
| **[1]** | Système, avancé | Réglages système, confidentialité, services et suggestions Windows. |
| **[2]** | Mémoire | Gestion de la RAM et de la compression mémoire selon les profils. |
| **[3]** | Disques | Réglages de stockage ; entretien des SSD et maintenance Windows conservés. |
| **[4]** | GPU | Réglages graphiques et de latence compatibles avec le matériel. |
| **[5]** | Réseau | Réglages de connexion et de la carte réseau selon l'usage et l'énergie. |
| **[6]** | Input | Réglages clavier, souris et contrôleurs compatibles. |
| **[7]** | Énergie | Plans d'alimentation et économies d'énergie. |
| **[8]** | Sécurité | Choix du mode de protections Windows décrit ci-dessous. |
| **[N]** | Nettoyage avancé | Supprime temporaires, caches, rapports et contenu de la corbeille. La suppression de `Windows.old` demande une confirmation séparée. |
| **[R]** | Point de restauration | Crée un point de restauration système. |
| **[G]** | Gestion Windows | Accède aux options de maintenance ci-dessous. |
| **[W]** | MAS | Lance l'outil externe MAS, à utiliser dans le respect des licences Windows/Office. |
| **[T]** | WinUtil | Lance l'outil externe WinUtil. |
| **[Q]** | Quitter | Ferme le script. |

### Protections Windows — menu [8]

Le profil d'énergie **Performance Max** et le mode de sécurité du même nom sont deux choix distincts. Gardez les protections actuelles pour un usage courant.

| Mode | Effet |
|---|---|
| **Défaut Windows** | Restaure les paramètres de sécurité capturés ; sans capture, applique les valeurs de repli prévues par le script. |
| **Gaming** | Active la sécurité basée sur la virtualisation (VBS) et l'intégrité de la mémoire (HVCI), même si ces protections étaient coupées, tout en réduisant certaines autres protections. |
| **Performance Max** | Désactive notamment VBS et HVCI et réduit d'autres protections. Ce mode est déconseillé pour un usage courant. |

La compatibilité dépend du jeu et de l'anti-cheat : certains exigent VBS/HVCI, TPM ou Secure Boot. L'application dépend aussi du matériel et de Windows ; les règles d'entreprise et certains verrouillages peuvent empêcher des changements.

Dans **Tout optimiser**, activer l'option Protections Windows applique **Gaming** pour l'usage Gaming ou **Défaut Windows** pour l'usage Normal. Le mode de sécurité Performance Max se choisit séparément dans le menu [8].

Gaming et Performance Max conservent LSA Protection avec `RunAsPPL=2`, sans écrire de variable UEFI ; cette valeur n'est appliquée qu'à partir de Windows 11 22H2. La première modification des protections capture 32 valeurs ciblées et le réglage BCD ; Défaut Windows restaure cette capture, ou la base Windows mesurée si elle manque. Une ancienne valeur `RunAsPPL=1` peut avoir laissé un verrou UEFI : sa suppression nécessite une procédure Microsoft depuis la récupération. Defender et UAC restent des actions distinctes ; aucune restauration ne récupère les instantanés Recall supprimés.

### Gestion Windows — menu [G]

| Touche | Option | Effet |
|---|---|---|
| **[1]** | Windows Defender | Active ou désactive les protections ; un état partiel est signalé si toutes les modifications ne sont pas appliquées. |
| **[2]** | UAC | Modifie les notifications du contrôle de compte utilisateur. |
| **[3]** | Animations | Active ou désactive les animations de l'interface. |
| **[4]** | IA et Widgets | Gère Copilot, l'IA du Bloc-notes, les Widgets et Recall selon la version de Windows. Désactiver Recall supprime ses instantanés enregistrés. |
| **[5]** | OneDrive | Désinstalle OneDrive et arrête la synchronisation. Le dossier local OneDrive est supprimé, sauf si Bureau, Documents ou Images y sont rangés. |
| **[6]** | Microsoft Edge | Désinstalle Edge en conservant WebView2. Certaines fonctions Windows et applications web peuvent être affectées. |
| **[7]** | Runtimes | Installe les composants Visual C++ et DirectX manquants. |
| **[8]** | Applications | Choix individuels pour le compte élevé affiché ; ancien lot tous comptes via **[A] Avancé**. |
| **[9]** | Récupération | Restaure les préférences sauvegardées, propose les corrections ciblées et les réactivations de sécurité. |
| **[P]** | Préférences Windows | Quatre questions : confidentialité, navigateurs, Widgets et composants de jeux, puis récapitulatif avec sauvegarde ciblée. |
| **[V]** | Valorant | Applique explicitement le profil fourni ou restaure les fichiers sauvegardés, jeu fermé. |
| **[M]** | Retour | Revient au menu principal. |

## ❓ Questions fréquentes

Cliquez sur une question pour afficher sa réponse.

<details>
<summary><strong>Quel gain de FPS attendre ?</strong></summary>

Le résultat dépend du matériel, des pilotes, des logiciels et de la charge. Aucun gain de FPS n'est garanti : comparez vos jeux avant et après avec les mêmes réglages.

</details>

<details>
<summary><strong>Est-ce sans risque pour mon PC ?</strong></summary>

Des incompatibilités sont possibles après des changements de services, de réseau ou de sécurité. Vous pouvez appliquer les sections séparément et éviter les désinstallations ou les options sensibles dont vous n'avez pas besoin.

</details>

<details>
<summary><strong>Est-ce compatible avec Valorant, FACEIT et les autres anti-cheats ?</strong></summary>

La compatibilité dépend du jeu et des exigences de son anti-cheat. Le mode de sécurité Gaming active VBS et l'intégrité de la mémoire ; Performance Max les désactive et peut empêcher certains jeux de démarrer. Aucun mode ne garantit la compatibilité avec tous les jeux.

</details>

<details>
<summary><strong>Puis-je relancer le script ou changer de profil ?</strong></summary>

Oui, mais cela réapplique aussi les [outils automatiques](#outils-automatiques) et ne restaure pas les fichiers ou applications supprimés. Voir les limites du [retour arrière](#retour-arrière).

</details>

<details>
<summary><strong>Dois-je redémarrer ?</strong></summary>

Un redémarrage est recommandé après un parcours complet et nécessaire quand le script, Windows ou un installateur le demande. Certains changements ne prennent effet qu'après le redémarrage.

</details>

<details>
<summary><strong>Le nettoyage supprime-t-il mes documents ?</strong></summary>

Il ne cible pas les dossiers Documents, Images ou Vidéos actuels, mais vide la corbeille et supprime des caches et fichiers de diagnostic. La suppression de `Windows.old`, proposée séparément, peut effacer d'anciennes données et retire la possibilité de revenir à la précédente installation de Windows par ce dossier.

</details>

<details>
<summary><strong>Quelles applications sont supprimées ?</strong></summary>

**[G] → [8]** propose séparément Copilot moderne, Clipchamp, Teams, le nouvel Outlook, Solitaire et News pour le compte élevé affiché. Les autres comptes et le provisionnement sont conservés. Les fonctions Copilot d'Edge, du Web et de Microsoft 365 sont distinctes. **[A] Avancé** conserve l'ancien lot pour tous les utilisateurs avec confirmation, dont Skype, Cartes et Candy Crush si présents. Edge et OneDrive ont leurs options séparées ; Windows Update, Store et WebView2 sont conservés. Une désinstallation peut perdre des données locales : réinstaller depuis le Store ne les récupère pas.

</details>

<a id="outils-automatiques"></a>

<details>
<summary><strong>Quels outils se lancent automatiquement ?</strong></summary>

- **Valorant** ne change qu'avec **[G] → [V]**, jeu fermé : tous les comptes Valorant du profil Windows élevé reçoivent plein écran, qualité minimale et VSync/HDR coupés. Résolution et clés non ciblées sont conservées. La restauration remplace les fichiers entiers par leur première sauvegarde `.winopt-backup`, écrasant les modifications ultérieures.
- **Gaming** peut lancer NVIDIA Profile Inspector et son profil sur un GPU NVIDIA compatible.
- **Performance Max** peut installer, lancer et ajouter SetTimerResolution au démarrage avec `--resolution 5275`, soit 0,5275 ms demandée, expérimental. Eco retire ce démarrage.
- Le profil O&O ShutUp10 (`Tools/`), GoInterruptPolicy, MeasureSleep et les modèles de `Game Configs/` sont fournis dans le dépôt mais ne sont ni exécutés ni appliqués automatiquement.

</details>

<a id="retour-arrière"></a>

<details>
<summary><strong>Puis-je revenir en arrière ?</strong></summary>

**[G] → [9] → [1]** restaure les préférences sauvegardées par **[G] → [P]**. Normal/Eco et Défaut Windows ne restaurent que leurs réglages pris en charge. Aucun parcours ne remet tout Windows à zéro ; les fichiers supprimés et données perdues lors d'une désinstallation exigent une sauvegarde.

Pour le menu « Devenir Propriétaire », une capture ancienne ou altérée dont la provenance ne peut pas être vérifiée est conservée, mais bloque tout nouvel ajout et toute restauration automatique de ce menu. Défaut Windows peut reprendre le nettoyage interrompu d’une restauration déjà vérifiée.

</details>

<details>
<summary><strong>Puis-je réinstaller OneDrive ou Edge ?</strong></summary>

Oui, depuis Microsoft. Les politiques de mise à jour posées lors de la suppression d'Edge peuvent devoir être retirées avant sa réinstallation. Réinstaller ne récupère pas les données supprimées.

</details>

<details>
<summary><strong>Pourquoi la commande de lancement ne fonctionne-t-elle pas ?</strong></summary>

Exécutez-la dans PowerShell, pas dans l'invite de commandes. Vérifiez la connexion Internet, acceptez la demande d'administration et consultez le message d'erreur. Vous pouvez aussi télécharger le script et le lancer en tant qu'administrateur.

Pour vérifier uniquement le téléchargement depuis une copie de `launcher.ps1`, utilisez `.\launcher.ps1 -VerifyOnly` dans PowerShell. Ce mode ne lance pas l'optimiseur et affiche la source ainsi qu'un SHA-256 informatif. Le lanceur utilise toujours le script publié, même si un `All in One.cmd` se trouve à côté de lui.

</details>

<details>
<summary><strong>Pourquoi mon antivirus affiche-t-il une alerte ?</strong></summary>

Les commandes d'administration et les modifications de sécurité peuvent déclencher une alerte. Ne supposez pas qu'il s'agit d'un faux positif : examinez le code et les fichiers téléchargés avant de poursuivre.

</details>

---

<div align="center">

**Développé avec passion par Kayler**

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

Contribuer ou travailler avec un agent : voir [AGENTS.md](AGENTS.md).

</div>
