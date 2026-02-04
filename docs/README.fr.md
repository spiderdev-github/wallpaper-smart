# Wallpaper Smart

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![Desktop](https://img.shields.io/badge/desktop-GNOME%20%7C%20KDE-orange)
![GTK](https://img.shields.io/badge/GTK-3.x-purple)

Wallpaper Smart est une application Linux (GNOME) qui change automatiquement le fond d’écran selon :

✅ l’heure de la journée (aube / midi / coucher / nuit)  
✅ la météo en temps réel (Open-Meteo)  
✅ un système de thèmes via des templates  
✅ une interface GTK simple et moderne pour gérer la configuration

---

## 🚀 Version

**v1.1.0**

---

## 📖 Documentation

🇬🇧 Read in English : [README EN](../README.md)

---

## ✨ Fonctionnalités (principales)

- 🌗 **Fond d’écran dynamique par moment**
  - aube / midi / coucher / nuit

- 🌦️ **Météo en temps réel**
  - clear / cloudy / fog / rain / snow / thunder
  - mapping configurable (`clair`, `nuageux`, etc.)

- 🎨 **Thèmes de wallpapers (templates)**
  - gestion via `templates/<theme>/...`
  - sélection du thème dans l’UI
  - validation automatique d’un thème (base + 4 images minimum)

- 📍 **Localisation**
  - géolocalisation par IP (**auto_ip**)
  - mode manuel (**fixed**)
  - mode **Ville** avec recherche lat/lon via OpenStreetMap (**Nominatim**)
  - presets “grandes capitales” avec **icône météo en temps réel**

- 🌍 **Multi‑langue (UI)**
  - Français, Anglais, Allemand, Espagnol, Arabe, Russe, Chinois  
  *(selon les fichiers disponibles dans `lang/`)*

- 🖥️ **Interface GTK (Wallpaper Smart UI)**
  - aperçu des images
  - sélection rapide des fichiers
  - activation/désactivation par image météo
  - test immédiat sans sauvegarder

- ⏱️ **Mise à jour automatique**
  - via **systemd user timer** (si disponible)
  - sinon possibilité de planifier via cron

- 📍 **Géolocalisation à l’installation (optionnel)**
  - détecte une localisation par défaut lors du `install.sh`
  - désactivable avec `--no-geo`

- ℹ️ **Section “À propos”**
  - infos du projet + liens
  - liens pour dons (PayPal / BuyMeACoffee)

---

## 🧩 Compatibilité

- ✅ Linux (multi‑distributions)
- ✅ GNOME (gsettings)
- ✅ KDE Plasma (support via script)
- ✅ GTK3 (UI)
- ✅ systemd user (optionnel mais recommandé)

> L'application detecte automatiquement l'environnement (GNOME / KDE) et applique le wallpaper via la methode adaptee.

---

## 📦 Dépendances

Installateur (best-effort) :

- `bash`, `curl`, `jq`
- `python3`
- `python3-gi` + GTK3 + Cairo (selon distro)
- `xdg-utils`
- KDE : `qdbus` ou `qdbus-qt5` (selon distribution)

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
│   └── wallpaper-smart-mkplaceholders.sh
├── wallpaper/
│   └── templates/
│       └── default/
│       │   ├── base/
│       │   │   ├── aube.png
│       │   │   ├── midi.png
│       │   │   ├── coucher.png
│       │   │   └── nuit.png
│       │   └── meteo/
│       │       ├── clair_aube.png
│       │       ├── clair_midi.png
│       │       └── ...
│       │
│       └── ...
│
└── lang/
    ├── en_US.json
    ├── fr_FR.json
    ├── de_DE.json
    └── ...
```

## 📸 Screenshots

> Ajoute tes screenshots dans `assets/screenshots/` puis adapte les liens ici.

- Général  
  ![General](assets/screenshots/general.png)

- Planning  
  ![planning](assets/screenshots/time.png)
  
- Géoloc  
  ![Geoloc](assets/screenshots/geoloc.png)

- Mapping  
  ![Mapping](assets/screenshots/mapping.png)

- Images  
  ![Images](assets/screenshots/images.png)

---

## 📌 Installation

### 1) Cloner le repo

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
  --walldir <chemin>      Répertoire racine des fonds d’écran
  --minutes <n>           Fréquence du timer (systemd uniquement) (défaut : 10)
  --no-deps               Ne pas essayer d’installer les dépendances (vérifications + conseils uniquement)
  --force-templates       Écraser les fichiers de templates existants (défaut : copie uniquement les fichiers manquants)
  --debug                 Mode verbeux
  --no-geo                Ne pas tenter de détecter la géolocalisation pendant l’installation

```

✅ Une entrée apparaîtra dans tes applications : **Wallpaper Smart**

---

## ⚙️ Configuration

Fichier de config :

```bash
~/.config/wallpaper-smart/config.json
```

Exemple :

```json
{
  "wallpaper_dir": "/home/user/.config/wallpaper-smart/wallpaper",
  "wallpaper_theme": "default",
  "schedule": {
    "nuit_start": 20,
    "aube_start": 5,
    "midi_start": 11,
    "coucher_start": 17
  },
  "geolocation": {
    "mode": "fixed",
    "fixed": { "lat": 48.5839, "lon": 7.7455 },
    "city_name": "Strasbourg",
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
  "timer_minutes": 10,
  "enabled_images": {},
  "ui": {
    "language": "fr_FR"
  }
}
```

---

## 🎨 Templates & thèmes

Wallpaper Smart utilise une structure stricte pour valider un thème.

### ✅ Un thème est valide si :

- `templates/<theme>/base/` existe
- et contient au minimum :
  - `aube.png`
  - `midi.png`
  - `coucher.png`
  - `nuit.png`

Exemple :

```
templates/default/base/aube.png
templates/default/base/midi.png
templates/default/base/coucher.png
templates/default/base/nuit.png
```

### Météo (optionnel)

Si tu veux activer la météo :

```
templates/<theme>/meteo/<prefix>_<moment>.png
```

Exemples :

```
templates/default/meteo/pluie_aube.png
templates/default/meteo/pluie_midi.png
templates/default/meteo/pluie_coucher.png
templates/default/meteo/pluie_nuit.png
```

Les `<prefix>` sont configurés dans l’onglet **Mapping** de l’UI.

---

## ▶️ Lancer l'application

```bash
~/.local/bin/wallpaper-smart-ui
```

---

## 🧪 Test manuel (sans timer)

```bash
CONFIG_FILE="$HOME/.config/wallpaper-smart/config.json" ~/.local/bin/wallpaper-smart.sh
```

---

## 🕒 Timer systemd

Le timer systemd user est :

- `wallpaper-smart.timer`
- `wallpaper-smart.service`

Commandes utiles :

```bash
systemctl --user status wallpaper-smart.timer
systemctl --user start wallpaper-smart.service
journalctl --user -u wallpaper-smart.service -n 50 --no-pager
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
  --remove-wallpapers      Supprimer le dossier des templates de wallpapers (templates/...) dans --wallpapers-dir
  --wallpapers-dir DIR     Dossier racine des wallpapers (identique à wallpaper_dir dans config.json)
  -h, --help               Afficher l’aide
```
---

## 🗺️ Roadmap

- [x] Ajouter une section « À propos » dans l’interface
- [x] Ajouter un bouton « Don »
- [x] Améliorer les logs (interface plus lisible)
- [x] Support de KDE Plasma
- [x] Météo en temps réel pour les localisations prédéfinies
- [x] Ajouter la gestion multilingue
- [x] Détecter la géolocalisation à l’installation pour définir la latitude/longitude par défaut (opetion désactivable)
- [x] Section géolocalisation : en mode « Ville », récupérer la latitude/longitude à partir de la ville saisie
- [ ] Permettre la gestion des thèmes sombre et clair pour les fonds d’écran
- [ ] Gestion avancée des thèmes (aperçu + import/export)

---

## ❓ FAQ

### Pourquoi le wallpaper ne change pas ?
- Verifie que le timer est actif :
  ```bash
  systemctl --user status wallpaper-smart.timer
  ```
- Lance un test manuel :
  ```bash
  ~/.local/bin/wallpaper-smart.sh
  ```
- Essaye d'activer/désactiver le style claire/sombre de ton OS

### Ou sont les logs ?
```bash
journalctl --user -u wallpaper-smart.service -n 50 --no-pager
```

---

## 🛡️ Licence

MIT License © SpiderDev  
Voir le fichier [LICENSE](LICENSE).

---

## ❤️ Soutenir le projet

Si Wallpaper Smart vous aide au quotidien, vous pouvez soutenir le projet :

- PayPal : https://www.paypal.com/paypalme/lalsarok1
- Buy Me a Coffee : https://buymeacoffee.com/spiderdev
- Site : https://spiderdev.fr

## 🤝 Contribuer

Les contributions sont bienvenues !

- forks + PR
- amelioration UI
- nouveaux themes wallpapers
- support multi-desktop (KDE etc.)

---

## ⭐ Remerciements

- **GTK / GNOME**
- **Open-Meteo API**
- **systemd user services**
- Ptifiela
- et tous les futurs contributeurs ❤️
