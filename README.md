<div align="center">

# ⚡ WINDOWS OPTIMIZER (VERSION 2026)

### 🚀 Le framework ultime d'optimisation pour Windows 10 & 11
*Maximisez vos performances, réduisez votre latence et reprenez le contrôle sur votre système.*

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2026.04-orange?style=for-the-badge)](https://github.com/kaylerberserk/WindowsOptimizer)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge)](https://github.com/kaylerberserk/WindowsOptimizer)

**Conçu pour le Gaming Compétitif, le Multitâche intensif et la Vie Privée.**  
*100% Transparent • Open Source • Réversible*

</div>

---

## 📖 À propos du projet

**Windows Optimizer** est un script d'automatisation professionnel (Batch/PowerShell) conçu pour transformer une installation Windows standard en une station de travail ou de jeu haute performance. 

Contrairement à d'autres outils "boîte noire", ce script est entièrement auditable et privilégie la **stabilité** et la **sécurité**. Il est idéal pour les administrateurs système, les joueurs exigeants et toute personne souhaitant une expérience Windows plus fluide et respectueuse de la vie privée.

---

## 🚀 Démarrage Rapide (Moins de 5 minutes)

1. **Téléchargement** : Récupérez le fichier [**All in One.cmd** (Clic droit -> Enregistrer sous)](https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/All%20in%20One.cmd).
2. **Exécution** : Clic droit sur le fichier → **Exécuter en tant qu'administrateur**.
3. **Sécurité** : Appuyez sur **[R]** pour créer un point de restauration avant de commencer.
4. **Optimisation** : Choisissez le profil qui vous correspond (**[D]** pour Bureau, **[L]** pour Portable).
5. **Redémarrage** : Redémarrez votre PC pour finaliser les changements.

---

## 🛠️ Guide Complet des Menus

Le script est structuré en plusieurs sections pour offrir une flexibilité totale.

### 🌟 Options Tout-en-Un (Profils Automatiques)

| Touche | Option | Public Cible | Bénéfices |
|:---:|:---:|---|---|
| **[D]** | **Optimize All (Desktop)** | PC Fixe / Gaming | Performance brute, latence minimale, priorités CPU maximales. |
| **[L]** | **Optimize All (Laptop)** | Ordinateurs Portables | Équilibre entre haute réactivité et préservation de l'autonomie. |

### ⚙️ Optimisations Granulaires (Individuelles)

Pour ceux qui veulent personnaliser leur expérience (Options 0 à 8) :

- **[0] Nettoyage Legacy** : Supprime les traces d'anciennes optimisations pour repartir à zéro.
- **[1] Système** : Optimise le noyau (Kernel), désactive les fonctions de ralentissement et booste la réactivité.
- **[2] Mémoire** : Gestion intelligente de la RAM et du fichier d'échange pour éviter les "stutters" (micro-saccades).
- **[3] Disques** : Activation du TRIM (SSD), du DirectStorage et optimisation des accès fichiers.
- **[4] GPU** : Réglages DirectX (Auto HDR, Flip Model), Low Latency et boost NVIDIA/AMD.
- **[5] Réseau** : Optimisation TCP/IP (BBR2), DNS rapide et réduction du ping en jeu.
- **[6] Input** : Réduction de la latence du clavier et de la souris (Keyboard/Mouse polling).
- **[7] Énergie** : Activation du plan "Performances Ultimes" ou retour aux réglages d'origine.
- **[8] Sécurité** : Toggle pour les protections CPU (Spectre/Meltdown) - *Réservé aux experts.*

### 📂 Gestion Windows (Menu [G])

Contrôlez les composants et applications intégrés de Windows :

- **Windows Defender** : Activer ou désactiver l'antivirus (à utiliser avec précaution).
- **IA & Widgets** : Désactivation de Copilot, Recall et des Widgets Windows 11 pour une vie privée totale.
- **Animations** : Toggle pour les effets visuels de l'interface (fluidité vs esthétique).
- **Désinstalleurs** : Suppression complète et propre de OneDrive et Microsoft Edge.
- **Runtimes** : Installation automatique des composants essentiels (Visual C++ 2015-2022 et DirectX).

### 🧰 Maintenance & Outils

- **[N] Nettoyage Avancé** : Processus en 15 étapes pour libérer plusieurs Go d'espace (Caches, Logs, Windows Update).
- **[R] Point de Restauration** : Création sécurisée d'une sauvegarde système avec horodatage.
- **[W] MAS** : Outil d'activation légitime pour Windows et Office.
- **[T] WinUtil** : Le célèbre outil de Chris Titus Tech pour configurer Windows.

---

## 🛡️ Sécurité & Fiabilité (Compatible Anti-Cheat)

Ce projet est conçu pour être **professionnel** et **sûr**. Il respecte les contraintes des environnements modernes :

- **Anti-Cheat OK** : Le script préserve **HVCI** (Isolation du noyau) et **CFG**. Il est 100% compatible avec **Vanguard (Valorant)**, **EAC (Fortnite)** et **BattlEye**.
- **Réversibilité** : Chaque modification peut être annulée via le point de restauration ou les options de restauration intégrées.
- **Zéro Malware** : Code 100% transparent. Vous pouvez lire chaque ligne de commande avant de l'exécuter.

---

## ❓ FAQ (Foire Aux Questions)

**Q : Est-ce que ce script va casser mon Windows ?**  
**R :** Non. Il utilise des méthodes standards et documentées. De plus, la création d'un point de restauration est intégrée pour une sécurité totale.

**Q : Dois-je relancer le script souvent ?**  
**R :** Une seule fois suffit. Cependant, après une grosse mise à jour de Windows, il peut être utile de le relancer pour réappliquer certaines optimisations.

**Q : Puis-je l'utiliser sur un PC de travail ?**  
**R :** Oui, le profil **[L]** ou les options individuelles sont idéales pour rendre un PC pro plus réactif sans compromettre la stabilité.

---

## 👨‍💻 Note pour les Recruteurs IT

Ce projet illustre des compétences clés en ingénierie système :
- **Scripting Avancé** : Utilisation complexe de Batch et PowerShell.
- **Expertise Système** : Manipulation précise du Registre Windows, des Services et de la pile Réseau.
- **UX / Ergonomie** : Création d'une interface console claire avec gestion des erreurs et barre de progression.
- **Documentation** : Maintenance d'un projet clair, structuré et orienté vers la satisfaction utilisateur.

---

<div align="center">

**Créé avec ❤️ par Kayler**  
*Si ce projet vous aide, n'hésitez pas à laisser une ⭐ sur GitHub !*

[**📥 Télécharger All in One.cmd (Clic droit -> Enregistrer sous)**](https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/All%20in%20One.cmd)
**[⭐ Star le projet si utile](https://github.com/kaylerberserk/WindowsOptimizer)**

</div>
