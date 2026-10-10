<div align="center">

# WINDOWS OPTIMIZER

### 🚀 Optimisation modulaire pour Windows 10 & 11

*Des profils de performance et des outils de maintenance dans un script portable.*

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)

</div>

## 🚀 Démarrage rapide

Collez cette commande dans **PowerShell**, puis acceptez la demande d'administration :

```powershell
irm https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1 | iex
```

Le launcher télécharge le script publié sur `main` et l'ouvre dans une fenêtre administrateur. Vous pouvez aussi [télécharger All in One.cmd](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et l'exécuter en tant qu'administrateur.

1. Appuyez sur **[R]** pour créer un point de restauration.
2. Appuyez sur **[O]** pour **Tout optimiser**, ou choisissez une section du menu.
3. Choisissez votre usage et votre profil d'énergie, puis les options proposées pour les protections Windows, Defender, les animations, l'IA et l'UAC.
4. Le parcours complet installe automatiquement les runtimes Visual C++ et DirectX manquants depuis Microsoft, puis applique les sections.
5. Redémarrez après le parcours, notamment si le script ou un installateur le demande.

> Le script modifie réellement Windows. Les options de sécurité réduisent certaines protections ; les désinstallations et le nettoyage peuvent supprimer des données. Un point de restauration ne remplace pas une sauvegarde de vos fichiers.

### Valorant au lancement

**À chaque lancement**, si Valorant possède des fichiers de configuration, le profil de performance est appliqué à tous les comptes déjà présents pour l'utilisateur Windows courant, ainsi qu'au fichier commun. Le jeu doit être fermé.

Les réglages du profil passent notamment en plein écran, sans VSync et en qualité minimale. **La résolution, l'échelle de rendu, les options de résolution dynamique et les réglages du moniteur sont conservés**, comme les paramètres extérieurs au profil.

Chaque fichier reçoit une sauvegarde initiale `.winopt-backup` dans `%LOCALAPPDATA%\VALORANT\Saved\Config`. Pour restaurer un fichier, recopiez sa sauvegarde sur le `.ini` correspondant, jeu fermé. Relancer l'optimiseur réapplique le profil : pour conserver vos réglages restaurés, évitez de le relancer.

Pour un nouveau compte, connectez-vous une première fois, fermez le jeu et relancez WindowsOptimizer. Aucun service en arrière-plan n'est installé. Le gain de FPS et la prise en compte de chaque réglage par Valorant ne sont pas garantis.

## 🛠️ Profils et fonctionnalités

### Usage et énergie

Les deux choix sont indépendants et disponibles sur PC fixe comme portable.

| Choix | Rôle |
|---|---|
| **Gaming** | Applique les réglages orientés jeu et latence pour le GPU, les entrées et le réseau. |
| **Normal** | Restaure les réglages exclusifs gérés par le profil Gaming. |
| **Eco** | Utilise le plan Équilibré et privilégie les économies d'énergie. |
| **Performance Max** | Privilégie les performances, avec davantage de consommation et de chaleur possibles. Le preset timer est expérimental. |

Vous pouvez combiner Gaming avec Eco, ou Normal avec Performance Max. **Normal + Eco** est le choix le plus conservateur. Changer de profil restaure les réglages exclusifs pris en charge, mais ne remet pas tout Windows à zéro et ne réinstalle pas les applications supprimées.

### Menu principal

| Touche | Section | Fonction |
|---|---|---|
| **[O]** | Tout optimiser | Enchaîne les sections avec les choix du parcours. |
| **[1]** | Système | Réglages système, confidentialité, services et suggestions Windows. |
| **[2]** | Mémoire | Gestion de la RAM et de la compression mémoire selon les profils. |
| **[3]** | Disques | Réglages de stockage ; TRIM et maintenance Windows conservés. |
| **[4]** | GPU | Réglages graphiques et de latence compatibles avec le matériel. |
| **[5]** | Réseau | Réglages TCP et de la carte réseau selon l'usage et l'énergie. |
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
| **Gaming** | Active VBS et l'intégrité de la mémoire (HVCI), même si ces protections étaient coupées, tout en réduisant certaines autres protections. |
| **Performance Max** | Désactive notamment VBS et HVCI et réduit d'autres protections. Ce mode est déconseillé pour un usage courant. |

La compatibilité dépend du jeu et de l'anti-cheat : certains exigent VBS/HVCI, TPM ou Secure Boot. Les stratégies d'entreprise et les verrous du firmware peuvent empêcher certains changements.

Dans **Tout optimiser**, activer l'option Protections Windows applique **Gaming** pour l'usage Gaming ou **Défaut Windows** pour l'usage Normal. Le mode de sécurité Performance Max se choisit séparément dans le menu [8].

### Gestion Windows — menu [G]

| Touche | Option | Effet |
|---|---|---|
| **[1]** | Windows Defender | Active ou désactive les protections ; un état partiel est signalé si toutes les modifications ne sont pas appliquées. |
| **[2]** | UAC | Modifie les notifications du contrôle de compte utilisateur. |
| **[3]** | Animations | Active ou désactive les animations de l'interface. |
| **[4]** | IA et Widgets | Gère Copilot, l'IA du Bloc-notes, les Widgets et Recall selon la version de Windows. Désactiver Recall supprime ses instantanés enregistrés. |
| **[5]** | OneDrive | Désinstalle OneDrive et arrête la synchronisation. Le dossier local OneDrive est supprimé, sauf si Bureau, Documents ou Images y sont rangés. |
| **[6]** | Microsoft Edge | Désinstalle Edge en conservant WebView2. Certaines fonctions Windows et applications web peuvent être affectées. |
| **[7]** | Runtimes | Installe les runtimes Visual C++ et DirectX manquants. |
| **[8]** | Bloatwares | Supprime une liste d'applications préinstallées, dont Actualités, Solitaire et Skype si elles sont présentes. |
| **[M]** | Retour | Revient au menu principal. |

## ❓ Questions fréquentes

**Quel gain de FPS attendre ?**

Le résultat dépend du matériel, des pilotes, des logiciels et de la charge. Aucun gain de FPS n'est garanti.

**Quels outils se lancent automatiquement ?**

Le profil Valorant s'applique au lancement. En Gaming, NVIDIA Profile Inspector et son profil peuvent être exécutés sur un GPU NVIDIA compatible. En Performance Max, SetTimerResolution peut être installé, lancé et ajouté au démarrage ; Eco retire ce démarrage automatique. Les ressources O&O, Fortnite et les autres outils Timer & Interrupt ne sont pas exécutés automatiquement.

**Puis-je revenir en arrière ?**

Les profils Normal/Eco et Défaut Windows restaurent les réglages qu'ils prennent en charge. Ils n'annulent pas toutes les actions du script. Les fichiers supprimés, la corbeille vidée, les instantanés Recall et les données retirées lors d'une désinstallation nécessitent une sauvegarde pour être récupérés. Supprimer `Windows.old` retire aussi la possibilité de revenir à la précédente installation de Windows par ce dossier.

**Puis-je réinstaller OneDrive ou Edge ?**

Oui, depuis Microsoft. Les politiques de mise à jour posées lors de la suppression d'Edge peuvent devoir être retirées avant sa réinstallation. Réinstaller ne récupère pas les données supprimées.

**La commande de lancement échoue ou l'antivirus affiche une alerte ?**

Utilisez PowerShell, pas l'invite de commandes. Vérifiez la connexion et le message d'erreur. En cas d'alerte antivirus, examinez le code et les téléchargements avant de poursuivre : ne supposez pas qu'il s'agit d'un faux positif.

Depuis une copie de `launcher.ps1`, vous pouvez vérifier le téléchargement publié sans lancer l'optimiseur ni demander l'administration :

```powershell
.\launcher.ps1 -VerifyOnly
```

Ce mode affiche la source et un SHA-256 informatif. Le launcher utilise toujours le batch publié, même si un `All in One.cmd` se trouve à côté de lui.

---

<div align="center">

**Développé avec passion par Kayler**

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
