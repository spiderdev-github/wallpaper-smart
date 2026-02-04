# Wallpaper Smart

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![Desktop](https://img.shields.io/badge/desktop-GNOME%20%7C%20KDE-orange)
![GTK](https://img.shields.io/badge/GTK-3.x-purple)

Wallpaper Smart is a Linux (GNOME) application that automatically changes the wallpaper based on:

✅ the time of day (dawn / noon / sunset / night)   
✅ real-time weather (Open-Meteo)   
✅ a theme system using templates   
✅ a simple and modern GTK interface to manage the settings 

---

## 🚀 Version

**v1.1.0**

---

## 📖 Documentation

🇫🇷 Lire en français : [README FR](./docs/README.fr.md)  

---

## ✨ Features (main)

- 🌗 **Dynamic wallpaper by time period**
  - dawn / noon / sunset / night

- 🌦️ **Real-time weather**
  - clear / cloudy / fog / rain / snow / thunder
  - configurable mapping (`clear`, `cloudy`, etc.)

- 🎨 **Wallpaper themes (templates)**
  - managed via `templates/<theme>/...`
  - theme selection in the UI
  - automatic theme validation (base + minimum 4 images)

- 📍 **Location**
  - IP-based geolocation (**auto_ip**)
  - manual mode (**fixed**)
  - **City** mode with lat/lon search via OpenStreetMap (**Nominatim**)
  - “major capitals” presets with **real-time weather icon**

- 🌍 **Multi-language (UI)**
  - French, English, German, Spanish, Arabic, Russian, Chinese
  *(depending on available files in `lang/`)*

- 🖥️ **GTK interface (Wallpaper Smart UI)**
  - image preview
  - quick file selection
  - enable/disable per weather image
  - instant test without saving

- ⏱️ **Automatic updates**
  - via **systemd user timer** (if available)
  - otherwise can be scheduled via cron

- 📍 **Geolocation during installation (optional)**
  - detects a default location during `install.sh`
  - can be disabled with `--no-geo`

- ℹ️ **“About” section**
  - project info + links
  - donation links (PayPal / BuyMeACoffee)

---

## 🧩 Compatibility

- ✅ Linux (multiple distributions)
- ✅ GNOME (gsettings)
- ✅ KDE Plasma (script support)
- ✅ GTK3 (UI)
- ✅ systemd user (optional but recommended)

> The app automatically detects the environment (GNOME / KDE) and applies the wallpaper using the appropriate method.

---

## 📦 Dependencies

Installer (best-effort):

- `bash`, `curl`, `jq`
- `python3`
- `python3-gi` + GTK3 + Cairo (depends on distribution)
- `xdg-utils`
- KDE : `qdbus` or `qdbus-qt5` (depends on distribution)

---

## 📁 Structure of projet

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

> Add your screenshots in `assets/screenshots/` then update the links here.

- General  
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


### 1) Clone the repo

```bash
git clone https://github.com/<ton-user>/<ton-repo>.git
cd <ton-repo>
```

### 2) Run the installer

```bash
chmod +x install.sh
./install.sh
```

#### OUseful options

```bash
  --walldir <chemin>      Wallpaper root directory
  --minutes <n>           Timer frequency (systemd only) (default: 10)
  --no-deps               Do not attempt to install dependencies (only checks + hints)
  --force-templates       Overwrite existing templates files (default: copy missing only)
  --debug                 Verbose mode
  --no-geo                Do not attempt to detect geolocation during install

```bash

✅ An entry will appear in your applications : **Wallpaper Smart**

---

## ⚙️ Configuration

Config file:

```bash
~/.config/wallpaper-smart/config.json
```

Example :

```json
{
  "wallpaper_dir": "/home/user/.config/wallpaper-smart/wallpaper",
  "wallpaper_theme": "default",
  "schedule": {
    "nuit_start": 19,
    "aube_start": 5,
    "midi_start": 11,
    "coucher_start": 17
  },
  "geolocation": {
    "mode": "Fixed",
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
    "language": "system"
  }
}
```

---

## 🎨 Templates & themes

Wallpaper Smart uses a strict structure to validate a theme.

### ✅ A theme is valid if :

- `templates/<theme>/base/` exists
- and contains at least:
  - `aube.png`
  - `midi.png`
  - `coucher.png`
  - `nuit.png`

Example :

```
templates/default/base/aube.png
templates/default/base/midi.png
templates/default/base/coucher.png
templates/default/base/nuit.png
```

### Weather (optional)

If you want to enable weather:

```
templates/<theme>/meteo/<prefix>_<moment>.png
```

Examples :

```
templates/default/meteo/pluie_aube.png
templates/default/meteo/pluie_midi.png
templates/default/meteo/pluie_coucher.png
templates/default/meteo/pluie_nuit.png
```

The `<prefix>` values are configured in the **Mapping** tab of the UI.

---

## ▶️ Launch the app

```bash
~/.local/bin/wallpaper-smart-ui
```

---

## 🧪 Manual test (without timer)

```bash
CONFIG_FILE="$HOME/.config/wallpaper-smart/config.json" ~/.local/bin/wallpaper-smart.sh
```

---

## 🕒 systemd timer

The systemd user timer is:

- `wallpaper-smart.timer`
- `wallpaper-smart.service`

Useful commands:

```bash
systemctl --user status wallpaper-smart.timer
systemctl --user start wallpaper-smart.service
journalctl --user -u wallpaper-smart.service -n 50 --no-pager
```

---

## 🧼 Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

### Useful options

```bash
  --remove-config          Remove config directory (~/.config/wallpaper-smart)
  --remove-wallpapers      Remove wallpapers templates directory (templates/...) inside --wallpapers-dir
  --wallpapers-dir DIR     Wallpapers root directory (same as wallpaper_dir in config.json)
  -h, --help               Show help
```
---

## 🗺️ Roadmap

- [x] Add an “About” section in the interface
- [x] Add a “Donate” button
- [x] Improve logs (more readable interface)
- [x] KDE Plasma support
- [x] Real-time weather for preset locations
- [x] Add multi-language support
- [x] Detect geolocation during installation to set default latitude/longitude (optional)
- [x] Geolocation section: in “City” mode, retrieve latitude/longitude from the entered city
- [ ] Allow dark and light theme management for wallpapers
- [ ] Advanced theme management (preview + import/export)

---

## ❓ FAQ

### Why doesn’t the wallpaper change?
- Check that the timer is active:
  ```bash
  systemctl --user status wallpaper-smart.timer
  ```
- Run a manual test:
  ```bash
  ~/.local/bin/wallpaper-smart.sh
  ```
- Try enabling/disabling your OS light/dark style

### Where are the logs?
```bash
journalctl --user -u wallpaper-smart.service -n 50 --no-pager
```

---

## 🛡️ Licence

MIT License © SpiderDev  
See the [LICENSE](LICENSE).

---

## ❤️ Support the project

If Wallpaper Smart helps you in your daily life, you can support the project:

- PayPal : https://www.paypal.com/paypalme/lalsarok1
- Buy Me a Coffee : https://buymeacoffee.com/spiderdev
- Website : https://spiderdev.fr

---

## 🤝 Contributing

Contributions are welcome!

- forks + PR
- UI improvements
- new wallpaper themes
- support multi-desktop support (KDE etc.)

---

## ⭐ Thanks

- **GTK / GNOME**
- **Open-Meteo API**
- **systemd user services**
- Ptifiela
- and all future contributors ❤️
