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

Le lanceur télécharge la version publiée du script et l'ouvre dans une fenêtre administrateur. Vous pouvez aussi [télécharger All in One.cmd](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et l'exécuter en tant qu'administrateur.

1. Appuyez sur **[R]** pour créer un point de restauration.
2. Appuyez sur **[O]** pour **Tout optimiser**, ou choisissez une section du menu.
3. Choisissez votre usage et votre profil d'énergie, puis les options proposées pour les protections Windows, Microsoft Defender (antivirus), les animations, les fonctions IA et les confirmations administrateur (UAC).
4. Le parcours complet installe automatiquement les composants Visual C++ et DirectX manquants depuis Microsoft, puis applique les sections.
5. Redémarrez après le parcours, notamment si le script ou un installateur le demande.

> Le script modifie réellement Windows. Les options de sécurité réduisent certaines protections ; les désinstallations et le nettoyage peuvent supprimer des données. Un point de restauration ne remplace pas une sauvegarde de vos fichiers.

## 🛠️ Profils et fonctionnalités

### Usage et énergie

Les deux choix sont indépendants et disponibles sur PC fixe comme portable.

| Choix | Rôle |
|---|---|
| **Gaming** | Applique les réglages orientés jeu et latence pour la carte graphique, le clavier, la souris et le réseau. |
| **Normal** | Restaure les réglages exclusifs gérés par le profil Gaming. |
| **Eco** | Utilise le plan Équilibré et privilégie les économies d'énergie. |
| **Performance Max** | Privilégie les performances, avec davantage de consommation et de chaleur possibles. Le réglage des minuteries système reste expérimental. |

Vous pouvez combiner Gaming avec Eco, ou Normal avec Performance Max. **Normal + Eco** est le choix le plus conservateur. Changer de profil restaure les réglages exclusifs pris en charge, mais ne remet pas tout Windows à zéro et ne réinstalle pas les applications supprimées.

### Menu principal

| Touche | Section | Fonction |
|---|---|---|
| **[O]** | Tout optimiser | Enchaîne les sections avec les choix du parcours. |
| **[1]** | Système | Réglages système, confidentialité, services et suggestions Windows. |
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
| **[8]** | Bloatwares | Supprime une liste d'applications préinstallées, dont Actualités, Solitaire et Skype si elles sont présentes. |
| **[M]** | Retour | Revient au menu principal. |

## ❓ Questions fréquentes

**Avec quelles versions de Windows est-il compatible ?**

Windows 10 et 11. Certaines options dépendent de la version de Windows, du matériel et des pilotes. Sur un PC professionnel ou géré par une organisation, des règles peuvent empêcher les modifications.

**Quel profil choisir ?**

En cas de doute, choisissez **Normal + Eco**. Pour jouer, choisissez **Gaming**, puis Eco pour limiter la consommation ou Performance Max pour privilégier les performances. Sur portable, Performance Max peut augmenter la chauffe et réduire l'autonomie. Le mode de sécurité Performance Max est un choix séparé et déconseillé pour un usage courant.

**Quel gain de FPS attendre ?**

Le résultat dépend du matériel, des pilotes, des logiciels et de la charge. Aucun gain de FPS n'est garanti : comparez vos jeux avant et après avec les mêmes réglages.

**Est-ce sans risque pour mon PC ?**

Des incompatibilités sont possibles après des changements de services, de réseau ou de sécurité. Créez un point de restauration et sauvegardez vos fichiers avant de commencer. Vous pouvez appliquer les sections séparément et éviter les désinstallations ou les options sensibles dont vous n'avez pas besoin.

**Est-ce compatible avec Valorant, FACEIT et les autres anti-cheats ?**

La compatibilité dépend du jeu et des exigences de son anti-cheat. Le mode de sécurité Gaming active VBS et l'intégrité de la mémoire ; Performance Max les désactive et peut empêcher certains jeux de démarrer. Aucun mode ne garantit la compatibilité avec tous les jeux.

**Faut-il désactiver Defender ou l'UAC ?**

Non, ces choix sont facultatifs. Gardez l'antivirus et les confirmations administrateur actifs pour un usage courant : les désactiver réduit la protection du PC.

**Puis-je relancer le script ou changer de profil ?**

Oui. Les profils remplacent leurs réglages exclusifs pris en charge. Relancer le script ne restaure toutefois pas les fichiers ou applications supprimés et réapplique les actions automatiques décrites ci-dessous.

**Dois-je redémarrer ?**

Un redémarrage est recommandé après un parcours complet et nécessaire quand le script, Windows ou un installateur le demande. Certains changements ne prennent effet qu'après le redémarrage.

**Le nettoyage supprime-t-il mes documents ?**

Il ne cible pas les dossiers Documents, Images ou Vidéos actuels, mais vide la corbeille et supprime des caches et fichiers de diagnostic. La suppression de `Windows.old`, proposée séparément, peut effacer d'anciennes données et retire la possibilité de revenir à la précédente installation de Windows par ce dossier.

**Quelles applications sont supprimées ?**

L'option Bloatwares cible une liste d'applications préinstallées, notamment Actualités, Solitaire, Skype, Cartes et Candy Crush si elles sont présentes. Edge et OneDrive ont leurs propres options de désinstallation. Windows Update, le Microsoft Store et WebView2 ne sont pas volontairement supprimés.

**Quels outils se lancent automatiquement ?**

Le profil Valorant s'applique au lancement, jeu fermé, sans changer la résolution. En Gaming, NVIDIA Profile Inspector et son profil peuvent être exécutés sur un GPU NVIDIA compatible. Avec le profil d'énergie Performance Max, SetTimerResolution peut être installé, lancé et ajouté au démarrage ; Eco retire ce démarrage automatique. Les ressources O&O, Fortnite et les autres outils Timer & Interrupt ne sont pas exécutés automatiquement.

**Puis-je revenir en arrière ?**

Les profils Normal/Eco et Défaut Windows restaurent les réglages qu'ils prennent en charge. Ils ne remettent pas tout Windows à zéro. Un point de restauration peut aider pour les changements système ; les fichiers supprimés, la corbeille vidée et les données retirées lors d'une désinstallation nécessitent une sauvegarde pour être récupérés.

**Puis-je réinstaller OneDrive ou Edge ?**

Oui, depuis Microsoft. Les politiques de mise à jour posées lors de la suppression d'Edge peuvent devoir être retirées avant sa réinstallation. Réinstaller ne récupère pas les données supprimées.

**Pourquoi la commande de lancement ne fonctionne-t-elle pas ?**

Exécutez-la dans PowerShell, pas dans l'invite de commandes. Vérifiez la connexion Internet, acceptez la demande d'administration et consultez le message d'erreur. Vous pouvez aussi télécharger le script et le lancer en tant qu'administrateur.

Pour vérifier uniquement le téléchargement depuis une copie de `launcher.ps1`, utilisez `.\launcher.ps1 -VerifyOnly` dans PowerShell. Ce mode ne lance pas l'optimiseur et affiche la source ainsi qu'un SHA-256 informatif. Le lanceur utilise toujours le script publié, même si un `All in One.cmd` se trouve à côté de lui.

**Pourquoi mon antivirus affiche-t-il une alerte ?**

Les commandes d'administration et les modifications de sécurité peuvent déclencher une alerte. Ne supposez pas qu'il s'agit d'un faux positif : examinez le code et les fichiers téléchargés avant de poursuivre.

---

<div align="center">

**Développé avec passion par Kayler**

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
