# Wallpaper Smart

[![Licence : MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Plateforme](https://img.shields.io/badge/platform-Linux-blue)
![Bureau](https://img.shields.io/badge/desktop-GNOME%20%7C%20KDE-orange)
![GTK](https://img.shields.io/badge/GTK-3.x-purple)

Wallpaper Smart est une application Linux (GNOME / KDE) qui change automatiquement le fond d’écran en fonction :

✅ du moment de la journée (aube / midi / coucher / nuit)  
✅ de la météo en temps réel (Open-Meteo)  
✅ d’un système de thèmes basé sur des templates  
✅ d’une interface GTK simple et moderne pour gérer les paramètres  

---

## 🚀 Version

**v1.0.0 (stable)**

Wallpaper Smart est prêt pour la production :
- les services démarrent **à la connexion utilisateur**
- le fond d’écran est appliqué immédiatement au démarrage de la session
- le timer est utilisé uniquement pour les mises à jour périodiques (pas pour l’initialisation)

Règles de versioning utilisées dans ce dépôt :
- `0.0.x` = modifications mineures / correctifs
- `0.x.0` = mises à jour majeures
- `1.0.0` = version stable

---

## 📖 Documentation

🇬🇧 Read in English : [README.md](README.md)  
📄 Journal des modifications : [CHANGELOG.fr.md](CHANGELOG.md)

---

## ✨ Fonctionnalités principales

- 🌗 **Fond d’écran dynamique selon le moment de la journée**
  - aube / midi / coucher / nuit
  - sélection automatique selon l’heure locale

- 🌦️ **Météo en temps réel**
  - clair / nuageux / brouillard / pluie / neige / orage
  - mapping météo configurable
  - repli automatique vers les images `base/` en l’absence de correspondance météo

- 🎨 **Thèmes de fond d’écran (templates)**
  - gérés via `templates/<theme>/<style>/...`
  - détection automatique du style **clair / sombre** (GNOME)
  - variante `base/` **obligatoire**, `meteo/` **optionnelle**
  - validation automatique des thèmes (structure + images requises)
  - sélection du thème via l’interface

- 🌓 **Intégration du style du bureau (GNOME)**
  - bascule automatique entre fonds **clair** et **sombre**
  - réaction instantanée aux changements de style GNOME
  - basé sur **systemd user path + service**
  - aucune action utilisateur requise

- 📍 **Localisation**
  - géolocalisation par IP (**auto_ip**)
  - mode manuel (**fixed**)
  - mode **Ville** avec recherche latitude / longitude via OpenStreetMap (**Nominatim**)
  - presets de grandes capitales avec icône météo en temps réel

- 🌍 **Interface multilingue**
  - Français, Anglais, Allemand, Espagnol, Arabe, Russe, Chinois
  - (selon les fichiers disponibles dans `lang/`)

- 🖥️ **Interface GTK (Wallpaper Smart UI)**
  - aperçu des images avec miniatures
  - sélection rapide des fichiers
  - activation / désactivation des images météo
  - test instantané sans sauvegarde
  - conservation de la sélection après le choix d'image météo
  - carte de thème déplacée vers l'onglet images pour une meilleure organisation

- 📊 **Indicateur d'application (AppIndicator)**
  - icône dans la barre d'état système
  - affichage du moment de la journée, de la météo et de la ville
  - menu rapide pour accéder aux fonctionnalités principales

- ⏱️ **Mises à jour automatiques**
  - le fond est appliqué **à la connexion utilisateur**
  - mises à jour périodiques via **systemd user timer**
  - **précision à la minute** pour les créneaux horaires (aube, midi, coucher, nuit)
  - rafraîchissement instantané lors des changements clair/sombre GNOME
  - repli possible vers cron si systemd n'est pas disponible

- 📍 **Géolocalisation à l’installation (optionnelle)**
  - détection automatique d’une position par défaut lors de `install.sh`
  - désactivable avec `--no-geo`

- ℹ️ **Section À propos**
  - informations sur le projet
  - liens utiles
  - liens de dons (PayPal / BuyMeACoffee)

---

## 🧩 Compatibilité

- ✅ Linux (plusieurs distributions)
- ✅ GNOME (gsettings)
- ✅ KDE Plasma (support par script)
- ✅ GTK3 (interface)
- ✅ systemd user (recommandé)
- ✅ AppIndicator (barre d'état système)

> L'application détecte automatiquement l'environnement (GNOME / KDE) et applique le fond d'écran avec la méthode appropriée.

---

## 📦 Dépendances

Installateur (best-effort) :

- `git`, `bash`, `curl`, `jq`
- `python3`
- `python3-gi` + GTK3 + Cairo (selon la distribution)
- `gir1.2-appindicator3-0.1` (pour l'indicateur d'application dans la barre d'état)
- `xdg-utils`
- KDE : `qdbus` ou `qdbus-qt5` (selon la distribution)

---

## 📁 Structure du projet

```
.
├── install.sh
├── uninstall.sh
├── src/
│   ├── wallpaper-smart.sh
│   ├── wallpaper-smart-ui
│   ├── wallpaper-smart.service
│   ├── wallpaper-smart.timer
│   ├── wallpaper-smart-mkplaceholders.sh
│   ├── wallpaper-smart-on-style-change.sh
│   ├── wallpaper-smart-style-hook.service
│   └── wallpaper-smart-style-hook.path
│
├── wallpaper/
│   └── templates/
│       └── default/
│           ├── dark/
│           │   ├── base/        # Obligatoire
│           │   │   ├── aube.png
│           │   │   ├── midi.png
│           │   │   ├── coucher.png
│           │   │   └── nuit.png
│           │   └── meteo/       # Optionnel
│           │       ├── clair_aube.png
│           │       ├── clair_midi.png
│           │       └── ...
│           │
│           └── light/
│               ├── base/        # Obligatoire
│               │   ├── aube.png
│               │   ├── midi.png
│               │   ├── coucher.png
│               │   └── nuit.png
│               └── meteo/       # Optionnel
│                   ├── clair_aube.png
│                   ├── clair_midi.png
│                   └── ...
│
└── lang/
    ├── en_GB.json
    ├── fr_FR.json
    ├── de_DE.json
    └── ...
```

## 📸 Captures d’écran

> Ajoute tes captures d’écran dans `assets/screenshots/` puis mets à jour les liens ici.

- Général  
  ![general](assets/screenshots/general.png)

- Planning  
  ![planning](assets/screenshots/time.png)

- Géoloc  
  ![geoloc](assets/screenshots/geoloc.png)

- Mapping  
  ![mapping](assets/screenshots/mapping.png)

- Images  
  ![images](assets/screenshots/images.png)

---

## 📌 Installation

### 1) Cloner le dépôt

```bash
git clone https://github.com/spiderdev-github/wallpaper-smart.git
cd wallpaper-smart
```

### 2) Lancer l’installateur

```bash
chmod +x install.sh
./install.sh
```

#### Options utiles

```bash
--walldir <dir>         Répertoire racine des fonds d’écran
--minutes <n>           Fréquence du timer (systemd uniquement) (défaut : 10)
--no-deps               Ne pas tenter d’installer les dépendances (vérifications + conseils uniquement)
--force-templates       Écraser les fichiers templates existants (défaut : copie uniquement ce qui manque)
--debug                 Mode verbeux
--no-geo                Ne pas tenter de détecter la géolocalisation lors de l’installation
```

✅ Une entrée apparaîtra dans vos applications : **Wallpaper Smart**

---

## ⚙️ Configuration

Fichier de configuration :

```bash
~/.config/wallpaper-smart/config.json
```

Exemple :

```json
{
  "wallpaper_dir": "/home/<user>/.config/wallpaper-smart/wallpaper",
  "wallpaper_theme": "default",
  "schedule": {
    "aube_start": "05:00",
    "midi_start": "11:00",
    "coucher_start": "16:00",
    "nuit_start": "19:00"
  },
  "geolocation": {
    "mode": "fixed",
    "fixed": {
      "lat": 48.8566,
      "lon": 2.3522
    },
    "city_name": "Paris",
    "preset": "none"
  },
  "weather_mapping": {
    "clear": "clair",
    "cloudy": "nuageux",
    "fog": "brouillard",
    "rain": "pluie",
    "snow": "neige",
    "thunder": "orage"
  },
  "timer_minutes": 5,
  "enabled_images": {},
  "ui": {
    "language": "system"
  }
}
```

---

## 🎨 Templates & thèmes

Wallpaper Smart utilise une structure stricte et prévisible pour valider et charger les thèmes.

### ✅ Un thème est valide si :

- `templates/<theme>/dark/base/` existe
- `templates/<theme>/light/base/` existe
- chaque dossier `base/` contient au minimum :
  - `aube.png`
  - `midi.png`
  - `coucher.png`
  - `nuit.png`

- La variante `base/` est **obligatoire**.
- Les variantes supplémentaires (comme `meteo/`) sont **optionnelles**.

Exemple :

```
templates/<theme>/
├── dark/
│   └── base/
│       ├── aube.png
│       ├── midi.png
│       ├── coucher.png
│       └── nuit.png
│
├── light/
│   └── base/
│       ├── aube.png
│       ├── midi.png
│       ├── coucher.png
│       └── nuit.png
│
└── theme.json

```

### Météo (optionnelle)

Si tu veux activer la météo :

```
templates/<theme>/dark/meteo/<prefix>_<moment>.png
templates/<theme>/light/meteo/<prefix>_<moment>.png
```

Exemples :

```
templates/<theme>/
├── dark/
│   ├── base/        # Obligatoire
│   │   ├── aube.png
│   │   ├── midi.png
│   │   ├── coucher.png
│   │   └── nuit.png
│   └── meteo/       # Optionnel
│       ├── <prefix>_aube.png
│       ├── <prefix>_midi.png
│       └── ...
│
├── light/
│   ├── base/        # Obligatoire
│   │   ├── aube.png
│   │   ├── midi.png
│   │   ├── coucher.png
│   │   └── nuit.png
│   └── meteo/       # Optionnel
│       ├── <prefix>_aube.png
│       ├── <prefix>_midi.png
│       └── ...
│
└── theme.json

```

Les valeurs `<prefix>` se configurent dans l’onglet **Mapping** de l’interface.

---

## ▶️ Lancer l’application

```bash
~/.local/bin/wallpaper-smart-ui
```

---

## 🧪 Test manuel (sans timer)

```bash
CONFIG_FILE="$HOME/.config/wallpaper-smart/config.json" ~/.local/bin/wallpaper-smart.sh
```

---

## 🕒 Services systemd & timer

Wallpaper Smart utilise des unités systemd utilisateur :

- `wallpaper-smart.service` (service principal)
- `wallpaper-smart.timer` (mises à jour périodiques)
- `wallpaper-smart-style-hook.path` (détecte les changements de style GNOME)
- `wallpaper-smart-style-hook.service` (applique le fond au changement de style)

Commandes utiles :

```bash
systemctl --user status wallpaper-smart.service
systemctl --user status wallpaper-smart.timer
systemctl --user status wallpaper-smart-style-hook.path

systemctl --user start wallpaper-smart.service
systemctl --user start wallpaper-smart-style-hook.path

journalctl --user -u wallpaper-smart.service -n 50 --no-pager
journalctl --user -u wallpaper-smart-style-hook.service -n 50 --no-pager
```

---

## 🧼 Désinstallation

```bash
chmod +x uninstall.sh
./uninstall.sh
```

### Options utiles

```bash
--remove-config          Supprimer le dossier de configuration (~/.config/wallpaper-smart)
--remove-wallpapers      Supprimer le dossier des templates (templates/...) dans --wallpapers-dir
--wallpapers-dir DIR     Répertoire racine des fonds d’écran (comme wallpaper_dir dans config.json)
-h, --help               Afficher l’aide
```

---

# 🗺️ Roadmap

Wallpaper-Smart évolue progressivement pour devenir un **moteur de fonds d’écran intelligent, flexible et entièrement personnalisable**, basé sur la météo et le moment de la journée.

### ✅ Fonctionnalités terminées
- Support multi-langue de l'interface
- Compatibilité KDE Plasma
- Intégration météo en temps réel pour des emplacements prédéfinis
- Détection automatique de la géolocalisation lors de l'installation (optionnelle)
- Géolocalisation par ville avec récupération automatique de la latitude et longitude
- Gestion des thèmes de fonds d'écran en mode clair et sombre
- Amélioration des logs avec une interface plus lisible
- Alerte visuelle lorsqu'un fond d'écran météo est manquant
- Section "À propos" et bouton de don
- Indicateur d'application (AppIndicator) dans la barre d'état système
- Précision à la minute pour les créneaux horaires (aube, midi, coucher, nuit)
- Amélioration de l'onglet Images avec conservation de sélection et miniatures
- Fonds d'écran météo HD par défaut
- Nouveaux thèmes disponibles (digital_even)  

### 🧩 Expérience des thèmes (à venir)
- Gestion avancée des thèmes avec aperçu en temps réel
- Import / export de thèmes pour faciliter le partage
- Localisation des noms de thèmes via la gestion des langues dans `theme.json`
- Onglet dédié à la gestion des thèmes avec prévisualisation complète  

### ⏱️ Planification intelligente
- Moteur de planification intelligent :
  - Utilisation automatique de `systemd` lorsqu'il est disponible
  - Repli sur `crontab` en l'absence de `systemd`
  - Mise à jour dynamique de la fréquence d'exécution sans intervention manuelle  

### 🌦️ Météo & interactions
- Panneau météo interactif  
- Lignes météo cliquables pour prévisualiser et sélectionner les images associées  

---

✨ **Vision à long terme** :  
Wallpaper-Smart vise à offrir une solution fluide, respectueuse du système et extensible pour gérer des fonds d’écran dynamiques basés sur des conditions réelles (météo et temps).

---

## ❓ FAQ

### Pourquoi le fond d’écran ne change pas ?
- Vérifie que le timer est actif :
  ```bash
  systemctl --user status wallpaper-smart.timer
  ```
- Lance un test manuel :
  ```bash
  ~/.local/bin/wallpaper-smart.sh
  ```
- Essaie d’activer/désactiver le mode clair/sombre de ton OS

### Où sont les logs ?
```bash
journalctl --user -u wallpaper-smart.service -n 50 --no-pager
```

---

## ❤️ Soutenir le projet

Si Wallpaper Smart t’aide au quotidien, tu peux soutenir le projet :

- PayPal : https://www.paypal.com/paypalme/lalsarok1
- Buy Me a Coffee : https://buymeacoffee.com/spiderdev
- Site web : https://spiderdev.fr

---

## 🤝 Contribuer

Les contributions sont les bienvenues !

- forks + PR
- améliorations UI
- nouveaux thèmes de fonds d’écran
- support multi-bureaux (KDE, etc.)

---

## ⭐ Remerciements

- **GTK / GNOME**
- **API Open-Meteo**
- **Services systemd utilisateur**
- Ptifiela
- et tous les futurs contributeurs ❤️

---

## 🛡️ Licence

Licence MIT © SpiderDev  
Voir le fichier [LICENSE](LICENSE).