<div align="center">

# WINDOWS OPTIMIZER

### 🚀 Optimisation modulaire pour Windows 11

*Des profils de performance et des outils de maintenance dans un script portable.*

![Windows](https://img.shields.io/badge/Windows-11-0078D6?style=for-the-badge&logo=windows&logoColor=white)

</div>

Windows 11 est la seule cible prise en charge.

## 🚀 Démarrage rapide

Collez cette commande dans **PowerShell**, puis acceptez la demande d'administration :

```powershell
irm https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1 | iex
```

Le lanceur télécharge la version publiée du script et l'ouvre dans une fenêtre administrateur. Vous pouvez aussi [télécharger All in One.cmd](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et l'exécuter en tant qu'administrateur.

### Premier parcours

1. Créez un point de restauration avec **[R]**.
2. Choisissez **[O] Tout optimiser** : les questions commencent directement, sans choix préalable « Recommandé / Avancé ».
3. Indiquez si vous jouez sur ce PC, puis votre priorité d'énergie : **Eco / Équilibré** pour limiter la chauffe et préserver l'autonomie sur portable, ou **Performance Max** pour privilégier la performance. Les deux choix restent indépendants, sur PC fixe comme portable.
4. Répondez aux cinq questions sur les protections Windows, Defender, les animations, l'IA et l'UAC. **N** conserve l'option concernée ; **M** annule. Les réductions de sécurité restent déconseillées et demandées séparément.
5. Vérifiez le récapitulatif : **O** lance les sections avec ces choix, **R** repose les cinq questions, **M** annule. Aucun profil ni option de ce parcours n'est appliqué avant cette validation. Les profils modifient des réglages globaux Windows/pilotes et n'offrent pas un retour arrière complet ; aucun gain universel de performances n'est établi.
6. Pour ne régler que la confidentialité, les navigateurs, les Widgets et les composants de jeux, **[G] → [P]** pose quatre questions, puis affiche un récapitulatif. Ces réglages de registre disposent de la sauvegarde ciblée décrite ci-dessous. Les sections **[1] à [7]** restent accessibles séparément, après avertissement.

### Préférences Windows avec sauvegarde — [G] → [P]

Certains choix de confidentialité, de navigateurs et de Widgets utilisent des stratégies **pour tous les comptes Windows**. La capture appartient au compte qui exécute le processus élevé ; sa restauration peut également modifier les réglages des autres comptes. Des captures prises par plusieurs comptes peuvent se contredire : elles ne constituent pas des états indépendants pour chaque utilisateur.

Les valeurs `HKCU`, les applications retirées individuellement et les fichiers Valorant visent le **compte qui exécute le processus élevé**, affiché avant les choix. Si l'UAC utilise les identifiants d'un autre administrateur, c'est son profil qui est concerné, pas celui de la personne connectée. Utilisez le compte dont le profil doit changer.

Le parcours **[G] → [P]** préserve Defender, SmartScreen, l'UAC, VBS/HVCI, les pilotes GPU/réseau, les préférences d'affichage et d'accessibilité, les plans d'alimentation, la compression mémoire et la veille. Il ne supprime aucune application, ne désactive aucun service ni tâche, et ne modifie pas `hosts` ou le nettoyage automatique.

| Choix | Effet et limite |
|---|---|
| Confidentialité | Diagnostics facultatifs, identifiant publicitaire, personnalisation, suggestions et highlights de recherche réduits. `AllowTelemetry=1` sur Home/Pro et `0` sur Enterprise/Education ; un `0` préexistant est conservé. Home et certaines stratégies ont des limites d'application. Edge `DiagnosticData=0` et `PersonalizationReportingEnabled=0`, Chrome `MetricsReportingEnabled=0`. Cela ne prouve pas l'absence de toute collecte. |
| Navigateurs | Edge : démarrage rapide et arrière-plan coupés, préchargements limités. Chrome : mode arrière-plan coupé. Les extensions/notifications après fermeture peuvent s'arrêter et l'ouverture suivante peut être plus lente. WebView2 reste disponible pour les applications. |
| Widgets | Stratégie Windows 11 `Dsh\AllowNewsAndInterests=0`. Sur certaines versions, Windows refuse l'écriture même en administrateur : le script le signale, sans désactiver une protection pour forcer le réglage. |
| Runtimes, facultatifs | Vérification/installation des redistribuables Visual C++ et DirectX officiels signés. Les logiciels installés ne sont pas annulés par la restauration des valeurs. |

**[G] → [9] → [1]** restaure uniquement les valeurs ou absences sauvegardées par ce parcours de préférences. La première capture est conservée sous `%ProgramData%\WindowsOptimizer\Backups\recommended-<SID>.json`, même après restauration, pour permettre un nouvel essai. Elle est liée au PC et à l'utilisateur du processus élevé, même lorsque les valeurs sauvegardées sont communes à tous les comptes. Une capture manquante, incompatible ou illisible bloque l'action ; un type de registre inattendu est préservé et signalé. Cette sauvegarde ne remplace pas les sauvegardes de fichiers ni un point de restauration. Chaque valeur est sauvegardée à sa première application, puis n'est plus renouvelée : un groupe choisi lors d'un passage ultérieur est capturé dans son état de ce moment-là.

**Pour un PC ayant déjà exécuté l'ancien script**, cette capture décrit son état déjà modifié. **[G] → [9] → [2]** propose de retirer le refus NTFS Everyone sur `store.db` et de réactiver les tâches fonctionnelles précédemment ciblées : famille, synchronisation, Work Folders, licences et diagnostics utiles. Sans capture ancienne, ce sont des corrections proposées, pas une restauration exacte. Les refus Everyone personnalisés sur ce fichier seraient aussi retirés ; la confirmation le précise. Les autres anciens réglages restent à traiter séparément. Defender, UAC et protections noyau ont chacun leur action de récupération distincte. Aucun mode ne récupère les données supprimées.

**Tout optimiser** installe toujours les runtimes manquants sans question supplémentaire : détection et installation s'exécutent en arrière-plan pendant les sections système/mémoire/disques/GPU, puis le parcours attend avant le réseau. Les signatures Microsoft sont vérifiées avant exécution. Les journaux d'échec restent sous `%TEMP%\WinOpt_Runtimes_*\runtime.log`. Le menu runtimes et les préférences **[G] → [P]** utilisent le premier plan. Visual C++ est considéré présent à partir de la version 14.40 pour chaque architecture, DirectX June 2010 seulement si toutes ses DLL sont présentes (d3dx9/10/11, D3DCompiler, XAudio2, XInput…) ; sinon l'installateur officiel est lancé.

---

## 🛠️ Guide des fonctionnalités

Si les composants ne peuvent pas être installés en arrière-plan, le script reprend au premier plan. Les contrôles de signature et d’installation restent actifs ; en cas d’échec, le résumé indique le journal conservé dans `%TEMP%\WinOpt_Runtimes_*\runtime.log`. Le menu **[7] Runtimes** conserve son affichage détaillé au premier plan.

> Le script modifie réellement Windows. Les options de sécurité réduisent certaines protections ; les désinstallations et le nettoyage peuvent supprimer des données. Un point de restauration ne remplace pas une sauvegarde de vos fichiers.

## 🛠️ Profils et fonctionnalités

### Usage et énergie — Tout optimiser

**[O] Tout optimiser** pose directement les questions d’usage et d’énergie, puis les cinq questions Windows. Les sections **[1] à [7]** demandent les profils utiles à leur section. Ces profils changent des réglages globaux Windows/pilotes ; les conséquences sont indiquées avant validation. Les deux axes Usage/Énergie sont indépendants et disponibles sur PC fixe comme portable.

| Choix | Rôle |
|---|---|
| **Gaming** | Applique les réglages orientés jeu et latence pour la carte graphique, le clavier, la souris et le réseau. |
| **Normal** | Restaure les réglages exclusifs gérés par le profil Gaming. |
| **Eco** | Utilise le plan Équilibré et privilégie les économies d'énergie. |
| **Performance Max** | Privilégie les performances, avec davantage de consommation et de chaleur possibles. Le réglage des minuteries système reste expérimental. |

Vous pouvez combiner Gaming avec Eco, ou Normal avec Performance Max. **Normal + Eco** est la combinaison la plus conservatrice parmi ces profils. Changer de profil restaure les réglages exclusifs pris en charge, mais ne remet pas tout Windows à zéro et ne réinstalle pas les applications supprimées.

### Effets à connaître dans les profils

- Système : réduit les suggestions, les fichiers récents de l'Explorateur, l'historique de recherche, AutoPlay et les diagnostics/personnalisation Edge ; coupe l'atténuation audio pendant les appels. Les Jump Lists, l'indexation et la recherche Windows restent disponibles. Normal/Eco ne rétablit pas tous ces réglages communs. Les tâches absentes et refusées sont distinguées ; un refus de service ou de tâche rend le bilan partiel. Les instances de tâches déjà lancées ne sont pas interrompues.
- Navigateurs : accélération matérielle et QUIC activés, DNS sur HTTPS Cloudflare en mode automatic avec repli normal, préchargements Edge et activité Edge/Chrome après fermeture conservés. **[G] → [P]** permet de limiter cet arrière-plan.
- Portable Normal + Eco : DiagLog et le service d'alimentation moderne sont préservés. Le refus NTFS sur la base du Store, les changements COM de F1, le nettoyage automatique et les modifications forcées d'hibernation/Modern Standby sont retirés des profils.
- Réseau Gaming + Performance Max : économies d'énergie réduites et réglages de latence appliqués aux propriétés exposées par le pilote, dont MIMO sans économie, U-APSD désactivé et mode 40 MHz non bloqué sur les adaptateurs Intel compatibles. Le résultat dépend du pilote ; aucun gain universel n'est établi.
- Performance Max : compression mémoire coupée au-delà de 8 Go de RAM, économies HIPM/DIPM et parking des disques désactivés ; Eco rend ces deux réglages de stockage à Windows. Le preset timer reste expérimental et réversible via Eco.

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

Le profil d'énergie **Performance Max** et le mode de sécurité du même nom sont deux choix distincts.

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
<summary><strong>Avec quelles versions de Windows est-il compatible ?</strong></summary>

Windows 11 uniquement. Certaines options dépendent de la version de Windows, du matériel et des pilotes. Sur un PC professionnel ou géré par une organisation, des règles peuvent empêcher les modifications.

</details>

<details>
<summary><strong>Quel profil choisir ?</strong></summary>

Choisissez **[O] Tout optimiser**, puis répondez aux questions. **Gaming** convient aussi à un PC qui sert à jouer et à travailler ; **Normal** vise un usage sans jeu. **Eco / Équilibré** préserve les économies d'énergie ; **Performance Max** peut augmenter la chauffe et réduire l'autonomie. Gardez Defender, l'UAC et les protections actuelles en cas de doute. Les réglages globaux de ces profils ne sont pas tous réversibles ; pour seulement modifier des préférences avec sauvegarde ciblée, utilisez **[G] → [P]**. Le mode de sécurité Performance Max reste un choix séparé du menu **[8]**, déconseillé pour un usage courant.

</details>

<details>
<summary><strong>Quel gain de FPS attendre ?</strong></summary>

Le résultat dépend du matériel, des pilotes, des logiciels et de la charge. Aucun gain de FPS n'est garanti : comparez vos jeux avant et après avec les mêmes réglages.

</details>

<details>
<summary><strong>Est-ce sans risque pour mon PC ?</strong></summary>

Des incompatibilités sont possibles après des changements de services, de réseau ou de sécurité. Créez un point de restauration et sauvegardez vos fichiers avant de commencer. Vous pouvez appliquer les sections séparément et éviter les désinstallations ou les options sensibles dont vous n'avez pas besoin.

</details>

<details>
<summary><strong>Est-ce compatible avec Valorant, FACEIT et les autres anti-cheats ?</strong></summary>

La compatibilité dépend du jeu et des exigences de son anti-cheat. Le mode de sécurité Gaming active VBS et l'intégrité de la mémoire ; Performance Max les désactive et peut empêcher certains jeux de démarrer. Aucun mode ne garantit la compatibilité avec tous les jeux.

</details>

<details>
<summary><strong>Faut-il désactiver Defender ou l'UAC ?</strong></summary>

Non, ces choix sont facultatifs. Gardez l'antivirus et les confirmations administrateur actifs pour un usage courant : les désactiver réduit la protection du PC.

</details>

<details>
<summary><strong>Puis-je relancer le script ou changer de profil ?</strong></summary>

Oui. Les profils remplacent leurs réglages exclusifs pris en charge. Relancer le script ne restaure toutefois pas les fichiers ou applications supprimés et réapplique les actions automatiques décrites ci-dessous.

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

<details>
<summary><strong>Quels outils se lancent automatiquement ?</strong></summary>

L'ouverture du script ne modifie pas Valorant. **[G] → [V]** permet d'appliquer le profil fourni, jeu fermé, à tous les comptes Valorant du profil Windows élevé affiché : plein écran, qualité minimale, VSync/HDR désactivés, résolution et clés non ciblées conservées. La restauration remplace les fichiers entiers par leur première sauvegarde `.winopt-backup` et écrase les modifications ultérieures. En Gaming, NVIDIA Profile Inspector et son profil peuvent être exécutés sur un GPU NVIDIA compatible. Avec le profil d'énergie Performance Max, SetTimerResolution peut être installé, lancé et ajouté au démarrage avec `--resolution 5275` (0,5275 ms demandée, réglage expérimental) ; Eco retire ce démarrage automatique. Les ressources O&O, Fortnite et les autres outils Timer & Interrupt ne sont pas exécutés automatiquement.

</details>

<details>
<summary><strong>Puis-je revenir en arrière ?</strong></summary>

**[G] → [9] → [1]** restaure les valeurs sauvegardées des préférences **[G] → [P]**. Les profils avancés Normal/Eco et Défaut Windows restaurent seulement les réglages qu'ils prennent en charge. Ils ne remettent pas tout Windows à zéro. Un point de restauration peut aider pour les changements système ; les fichiers supprimés, la corbeille vidée et les données retirées lors d'une désinstallation nécessitent une sauvegarde pour être récupérés.

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

</div>

### Références vérifiées pour les changements

Sources consultées le 16 octobre 2026 et confrontées aux réglages du script. Les essais Windows vérifient les chemins décrits, sans démontrer un gain de performances :

- [Diagnostics Windows, niveaux et éditions](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system#allowtelemetry) ; [gestion des connexions et de la personnalisation](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services).
- [Widgets](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-newsandinterests) ; [Copilot actuel et limites de la politique legacy](https://learn.microsoft.com/en-us/windows/client-management/manage-windows-copilot).
- [Diagnostics Edge](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/diagnosticdata), [personnalisation](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/personalizationreportingenabled), [arrière-plan](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/backgroundmodeenabled) et [Chrome BackgroundModeEnabled](https://chromeenterprise.google/policies/#BackgroundModeEnabled).
- Croisement communautaire : [Win11Debloat](https://github.com/Raphire/Win11Debloat), [WinUtil](https://github.com/ChrisTitusTech/winutil). Leurs listes ne prouvent ni le besoin de désactiver une fonction ni un gain de performance.

La relecture du registre prouve le stockage, pas la prise en compte de toutes les politiques ni un gain RAM/FPS. Vérifiez aussi `edge://policy`, `chrome://policy` et les Paramètres Windows. Les stratégies d'entreprise et certaines protections Windows peuvent imposer une autre valeur ; aucun contournement automatique n'est effectué.
