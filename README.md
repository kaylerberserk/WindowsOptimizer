<div align="center">

# ⚡ WINDOWS OPTIMIZER

### 🚀 Le script ultime d'optimisation pour Windows 10 & 11
*Maximisez vos performances, réduisez votre latence et reprenez le contrôle sur votre système.*

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2026.04-orange?style=for-the-badge)](https://github.com/kaylerberserk/WindowsOptimizer)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Conçu pour le Gaming Compétitif, le Multitâche intensif et la Confidentialité.**  
*100% Transparent • Open Source • Entièrement Réversible*

</div>

---

## 📌 Sommaire
- [📖 À propos du projet](#-à-propos-du-projet)
- [🚀 Démarrage Rapide](#-démarrage-rapide)
- [🛠️ Guide des Fonctionnalités](#️-guide-des-fonctionnalités)
- [🛡️ Sécurité & Fiabilité](#-sécurité--fiabilité)
- [❓ FAQ (Foire Aux Questions)](#-faq-foire-aux-questions)

---

## 📖 À propos du projet

**Windows Optimizer** est un script d'automatisation professionnel conçu pour transformer une installation Windows standard en une station de travail ou de jeu haute performance. 

Ce script se distingue par sa **stabilité** et sa **polyvalence** : il est universel et a été rigoureusement testé sur tous les environnements, du PC de Gaming au poste de Bureautique, en passant par les Machines Virtuelles (VM). Contrairement aux versions "Lite" modifiées de Windows, ce script ne supprime aucun composant système vital, garantissant un système complet mais parfaitement optimisé.

---

## 🚀 Démarrage Rapide (Moins de 5 minutes)

1. **Téléchargement** : Accédez au fichier [**All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et cliquez sur le bouton **Download**.
2. **Exécution** : Clic droit sur le fichier → **Exécuter en tant qu'administrateur**.
3. **Sécurité** : Appuyez sur **[R]** pour créer un point de restauration avant toute modification.
4. **Optimisation** : Choisissez votre profil (**[D]** pour Bureau, **[L]** pour Portable).
5. **Redémarrage** : Un redémarrage est nécessaire pour appliquer l'ensemble des changements.

---

## 🛠️ Guide des Fonctionnalités

### 🌟 Profils Automatiques (All-in-One)

| Touche | Profil | Objectif |
|:---:|:---:|---|
| **[D]** | **Optimize All (Desktop)** | Performance brute, latence minimale et plan "Ultimate Performance". |
| **[L]** | **Optimize All (Laptop)** | Équilibre optimisé entre puissance et autonomie (économie d'énergie préservée). |

### ⚙️ Optimisations Granulaires

- **[0] Legacy Cleanup** : Nettoyage des anciens tweaks obsolètes pour éviter les conflits système.
- **[1] Système** : Optimisation du noyau (Kernel), de la planification CPU et suppression de la télémétrie.
- **[2] Mémoire** : Ajustement de la gestion RAM pour éliminer les micro-saccades (stuttering).
- **[3] Disques** : Optimisation des accès I/O pour accélérer le chargement des jeux et logiciels.
- **[4] GPU** : Configuration des priorités graphiques et réduction du délai d'affichage (latency).
- **[5] Réseau** : Optimisation de la pile TCP/IP pour réduire le ping et stabiliser la connexion.
- **[6] Input** : Optimisation de la fréquence d'interrogation pour une souris et un clavier plus réactifs.
- **[7] Énergie** : Gestion des plans d'alimentation et déblocage de l'Ultimate Performance.
- **[8] Sécurité** : Gestion des mitigations processeur (Spectre/Meltdown) pour regagner des cycles CPU.
- **[9] Bloatwares** : (Menu [G]) Suppression des applications préinstallées inutiles.

### 📂 Gestion Windows & Maintenance (Menu [G])

- **Windows Defender** : Activation ou désactivation complète de l'antivirus intégré.
- **UAC** : Gestion fine des notifications du Contrôle de Compte Utilisateur.
- **VBS / HVCI** : Gestion de l'Isolation du noyau (Memory Integrity) pour les FPS ou la compatibilité Anti-Cheat.
- **Animations** : Choix entre une interface visuelle riche ou ultra-réactive.
- **IA & Widgets** : Suppression de Copilot, Recall et des widgets Windows 11.
- **Applications** : Désinstallation propre de OneDrive et Microsoft Edge.
- **Bloatwares** : Suppression en un clic des applications Windows inutiles (News, Météo, etc.).
- **Runtimes** : Installation des bibliothèques essentielles (Visual C++ 2005-2022, DirectX).
- **[N] Nettoyage Avancé** : Grand ménage en 15 étapes des fichiers temporaires, caches et logs.
- **[W] MAS** : Lien vers l'outil d'activation communautaire pour Windows et Office.
- **[T] WinUtil** : Accès à la boîte à outils de maintenance de Chris Titus Tech.

---

## 🛡️ Sécurité & Fiabilité

- **Compatible Anti-Cheat** : Le script propose une configuration optimisée qui maintient l'intégrité du système (**HVCI** et **CFG**) requise par les anti-cheats modernes tels que **Vanguard**, **FaceIT** et **Ricochet**.
- **Réversibilité** : Chaque modification est traçable. L'option **[R]** permet de créer un point de restauration instantané et les paramètres système peuvent être restaurés via les menus dédiés.
- **Transparence** : Code source 100% ouvert, auditable et sans binaire tiers ou script obfusqué.
- **Zéro perte de fonctions** : Les fonctionnalités vitales (Windows Update, Microsoft Store) restent opérationnelles. Les "Bloatwares" supprimés sont uniquement les apps préinstallées non-essentielles.

---

## ❓ FAQ (Foire Aux Questions)

### 🏠 Installation & Sécurité

**Q : Est-ce que ce script va "casser" mon Windows ?**  
R : Non. Contrairement aux ISO modifiées, ce script n'altère pas les fichiers système. L'option **[R]** assure une sécurité totale en cas de besoin de retour en arrière.

**Q : Mon antivirus détecte le script, pourquoi ?**  
R : C'est un faux positif. Le script manipule des clés de registre système, ce qui est jugé "suspect" par certains moteurs, bien que les actions soient bénéfiques.

**Q : Puis-je lancer le script plusieurs fois ?**  
R : Oui, le script vérifie l'état actuel avant d'appliquer un changement. Le relancer après une mise à jour majeure de Windows est d'ailleurs recommandé.

### 🎮 Performance & Gaming

**Q : Quel gain de FPS puis-je espérer ?**  
R : Le gain varie selon votre matériel, mais vous constaterez surtout une meilleure stabilité du framerate (moins de drops) et une réponse plus instantanée de vos périphériques.

**Q : Pourquoi désactiver les mitigations Spectre/Meltdown (Option 8) ?**  
R : Ces protections ajoutent une charge au processeur. En les désactivant, on regagne de la performance brute, mais c'est une option réservée aux utilisateurs qui acceptent le risque de sécurité associé.

**Q : Est-ce sûr pour le jeu en ligne ?**  
R : Absolument. Le script n'interfère jamais avec les fichiers de jeu. Pour les titres exigeants (Valorant/FaceIT), utilisez le profil de compatibilité dans le menu VBS/HVCI pour respecter les exigences de leurs anti-cheats.

### 🌐 Maintenance & Divers

**Q : Est-ce que le nettoyage (Option N) supprime mes documents ?**  
R : Absolument pas. Il cible uniquement les fichiers temporaires, caches de mises à jour et logs système qui encombrent votre disque.

**Q : Puis-je réinstaller OneDrive ou Edge plus tard ?**  
R : Oui, ils peuvent être réinstallés via le site officiel de Microsoft à tout moment.

**Q : Quels "Bloatwares" sont supprimés ?**  
R : Le script effectue un nettoyage ciblé pour supprimer les éléments publicitaires ou non-essentiels, tout en garantissant la stabilité du système.

### 🗑️ Ce qui est rigoureusement SUPPRIMÉ :
| Catégorie | Applications Supprimées (Bloatwares) |
| :--- | :--- |
| **Jeux & Pubs** | Candy Crush (Saga & Soda), Solitaire Collection. |
| **Social / Liens** | Skype, People, Microsoft Family, Your Phone (Lien avec le téléphone). |
| **Utilitaires** | Cartes (Maps), Feedback Hub, Get Help, Get Started, Mixed Reality Portal, Assistance rapide. |
| **Services** | Office Hub (Web stub), OneConnect (Forfaits mobiles), Bing News (Actualités). |

### ✅ Ce qui est rigoureusement CONSERVÉ :
| Catégorie | Applications Maintenues (Sécurisées) |
| :--- | :--- |
| **Gaming** | Toute la suite **Xbox** (Game Bar, App), DirectX, Game Mode. |
| **Quotidien** | Météo, Sports, Finances, Alarmes, Caméra, Enregistreur vocal. |
| **Multimédia** | Musique (Groove), Films et TV, Photos, Paint. |
| **Productivité** | Calculatrice, Bloc-notes, Courrier & Calendrier, Sticky Notes. |
| **Système** | Store, Edge, OneDrive, Sécurité Windows, Terminal, Capture. |

**Q : Combien de temps dure l'optimisation ?**  
R : Moins de 5 minutes selon les options choisies et la vitesse de votre matériel.
---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
