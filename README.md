<div align="center">

# ⚡ WINDOWS OPTIMIZER

### 🚀 Windows 10/11 Ultimate Performance & Gaming Optimization Script

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2026-orange?style=for-the-badge)](https://github.com/kaylerberserk/Optimizer)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Script batch tout-en-un pour un Windows ultra-rapide et optimisé**  
*Gaming compétitif • Multitâche réactif • Télémétrie bloquée • 100% réversible*

⏱️ **Optimisation complète en moins de 5 minutes**

</div>

---

## 🚀 Démarrage Ultra-Rapide

### 1. Télécharger le script uniquement

**Option A :** Téléchargez juste le fichier `All in One.cmd` depuis ce lien :
> 📥 **[Télécharger All in One.cmd](https://raw.githubusercontent.com/kaylerberserk/Optimizer/main/All%20in%20One.cmd)**

**Option B :** Clonez tout le repository :
```bash
git clone https://github.com/kaylerberserk/Optimizer.git
```

### 2. Exécuter

1. **Clic droit** sur `All in One.cmd` → **"Exécuter en tant qu'administrateur"**
2. **Choisissez votre profil** :
   - `D` → **PC Bureau** (performance maximale)
   - `L` → **PC Portable** (performance + batterie)
   - `G` → Gestion Windows (Defender, UAC, Edge, VC++ Redist, etc.)
   - `1-8` → Optimisations individuelles

### 3. Redémarrer

⏭️ Un redémarrage est recommandé pour appliquer toutes les modifications. **C'est terminé en moins de 5 minutes !**

---

## ✨ Fonctionnalités

| Catégorie | Optimisations |
|-----------|--------------|
| **🖥️ Système** | Priorités CPU, profil gaming, démarrage rapide |
| **🧠 Mémoire** | Fichier d'échange optimisé, Superfetch, cache |
| **💾 Stockage** | SSD/NVMe mode performance, DirectStorage |
| **🎮 Gaming** | GameDVR OFF, timer 0.5ms, input lag minimal ; DirectX : **VRR désactivé** + **Flip Model** (SwapEffect) selon préférences GPU (réduit le stutter sur certaines configs) |
| **🌐 Réseau** | BBR2, DNS optimisé, QoS gaming |
| **⚡ Énergie** | Plan performance, core parking OFF |
| **🛡️ Vie Privée** | Télémétrie OFF, 30+ domaines bloqués |

### 🎯 Gestion Windows (Option G)

| Option | Description |
|--------|-------------|
| Windows Defender | Activer/Désactiver (les politiques sensibles, ex. actions automatiques / quarantaine, ne sont appliquées **que** lors d’une désactivation explicite via ce menu) |
| UAC | Niveau normal ou OFF |
| OneDrive | Désinstallation complète |
| Edge | Désinstallation complète |
| Runtimes | Visual C++ **2015–2022** (V14) + DirectX Redist **June 2010** (option 7) |

---

## ⚠️ Avertissements

### ✅ Sécurité & Compatibilité

| Aspect | Statut |
|--------|--------|
| **Anti-Cheat** | ✅ Compatible avec Vanguard, Easy Anti-Cheat, BattlEye |
| **HVCI/CFG** | ✅ Préservés (requis par les jeux compétitifs) |
| **Windows Hello, Bluetooth, VPN, Xbox** | ✅ Fonctionnent normalement |
| **Réversibilité** | ✅ Oui. Option **R** : point de restauration avec horodatage **indépendant de la locale** et contrôle WMI que la protection système sur **C:** est active avant création. |

### 🔒 Ce que le script modifie

| Domaine | Modifications |
|---------|--------------|
| **Registre Windows** | ~50 clés optimisées |
| **Services Windows** | ~25 services de tracking désactivés |
| **Tâches Planifiées** | ~30 tâches de télémétrie bloquées |
| **Pare-feu** | 30+ domaines Microsoft bloqués |

### 📋 Précautions

- ✅ **Exécuter en tant qu'administrateur** (obligatoire)
- ⏭️ **Point de restauration** → Utilisez l'option R du menu avant d'optimiser (recommandé)
- ⏭️ **Redémarrer** après l'optimisation (recommandé)
- ❌ **Windows S/ARM** : Non compatible
- ❌ **Windows 7/8/8.1** : Non supporté

---

## 📝 FAQ

### 🏠 Questions Générales

**❓ Le script est-il sûr ?**  
✅ **Oui.** Le script est entièrement conçu pour optimiser sans casser votre système. Toutes les modifications sont documentées, réversibles et testées.

**❓ Quelles versions de Windows sont supportées ?**  
✅ Windows 10 (2004+) et Windows 11 (21H2+). Non compatible avec Windows 7, 8, 8.1 ou Windows S.

**❓ Combien de temps dure l'optimisation ?**  
⏱️ **Moins de 5 minutes** pour une optimisation complète.

**❓ Puis-je l'utiliser plusieurs fois ?**  
✅ **Oui.** Le script est idempotent - vous pouvez le relancer autant de fois que vous voulez.

**❓ Que se passe-t-il si je désinstalle OneDrive ?**  
✅ OneDrive est complètement désinstallé proprement. Vos fichiers locaux restent dans votre dossier utilisateur. Vous pouvez le réinstaller depuis microsoft.com si besoin.

**❓ Que se passe-t-il si je désinstalle Edge ?**  
✅ Edge est complètement désinstallé. Windows fonctionne parfaitement sans. Vous pouvez utiliser Chrome, Firefox, Brave, etc.

---

### 🎮 Questions Gaming

**❓ Est-ce que ça marche avec les anti-cheat ?**  
✅ **Oui.** HVCI et CFG préservés. Compatible avec Vanguard (Valorant), Easy Anti-Cheat (Fortnite), VAC (CS2), etc.

**❓ Quelles optimisations gaming sont incluses ?**  
🎯 GameDVR OFF (0% overhead GPU), Timer Resolution 0.5ms pour un input lag minimal, Mode Jeu activé, GPU Scheduling optimisé.

**❓ Puis-je utiliser ce script sur un PC de compétition ?**  
✅ **Oui.** Recommandé pour le gaming compétitif. Les optimisations réduisent la latence de manière mesurable.

**❓ Est-ce que ça améliore mes FPS ?**  
📈 **Oui.** Gains variables selon la config : démarrage des jeux plus rapide, moins de micro-stuttering, ping plus stable.

---

### 💻 Questions Techniques

**❓ Le nettoyage supprime-t-il mes données ?**  
❌ **Non.** Uniquement les fichiers temporaires, logs système, cache Windows. Vos fichiers, mots de passe et paramètres sont préservés.

**❓ Le cache des jeux est-il préservé ?**  
✅ **Oui.** Les shaders de jeux (Forza, Cyberpunk, etc.) sont conservés. Pas de recompilation nécessaire.

**❓ Pourquoi certains services sont-ils désactivés ?**  
Les services désactivés sont principalement de la télémétrie, tracking utilisateur et diagnostics non essentiels. Leur désactivation améliore les performances et la vie privée.

**❓ Quelles données sont collectées par Windows après l'optimisation ?**  
🛡️ **Très peu.** Télémétrie désactivée, 30+ domaines de tracking bloqués, publicités Windows OFF.

---

### 🔒 Questions Vie Privée

**❓ Est-ce que le script est open source ?**  
✅ **Oui.** Le code est entièrement visible et auditable. Aucune modification cachée.

**❓ Puis-je vérifier les modifications avant de les appliquer ?**  
✅ **Oui.** Le fichier `All in One.cmd` est un script texte ouvert : ouvrez-le dans un éditeur, parcourez les sections (menus, `reg`, PowerShell) puis lancez-le quand vous êtes prêt. Les choix du menu s’affichent avant les blocs concernés.

---

## 📦 Contenu du Repository

```
Optimizer/
├── 📜 All in One.cmd              # ⭐ Script principal (téléchargeable seul)
├── 📄 README.md                    # Documentation
├── 📁 Tools/                      # ⚠️ Pour utilisateurs avancés uniquement
│   ├── TCPOptimizer/              # Configuration réseau avancée
│   ├── NVIDIA Inspector/          # Profil GPU optimisé
│   ├── O&O ShutUp10/             # Outil anti-télémétrie GUI
│   └── Timer & Interrupt/         # Outils timer MSI
└── 📁 Game Configs/               # ⚠️ Pour utilisateurs avancés uniquement
    ├── Fortnite/
    └── Valorant/
```

> **ℹ️ Note** : Le script `All in One.cmd` fonctionne **indépendamment**. Vous pouvez le télécharger et l'utiliser sans le reste du repository. Les dossiers `Tools/` et `Game Configs/` sont optionnels et destinés aux utilisateurs avancés.

---

## 📄 License

Ce projet est sous licence **MIT**. Vous pouvez l'utiliser, le modifier et le redistribuer librement.

---

<div align="center">

**Créé par Kayler** avec ❤️ pour la communauté gaming et performance

**[📥 Télécharger All in One.cmd](https://raw.githubusercontent.com/kaylerberserk/Optimizer/main/All%20in%20One.cmd)**  
**[⭐ Star le projet si utile](https://github.com/kaylerberserk/Optimizer)**

</div>
