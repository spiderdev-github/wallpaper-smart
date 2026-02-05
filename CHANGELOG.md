# Changelog

🇫🇷 **Version française** : [CHANGELOG.fr.md](CHANGELOG.fr.md)

---

## [2.0.0] - 2026-02-05
### 🚀 Major update – Desktop style integration (dark / light)

### Added
- Automatic wallpaper switching based on GNOME desktop style (dark / light)
- Instant reaction to desktop style changes (event-driven mechanism)
- Added new systemd user files:
  - `wallpaper-smart-style-hook.path`
  - `wallpaper-smart-style-hook.service`
  - `wallpaper-smart-on-style-change.sh`
- Full integration with GNOME `color-scheme` setting
- Real-time wallpaper refresh without relying on the timer

### Changed
- **Breaking change**: new mandatory template structure:
  - `templates/<theme>/dark/base/`
  - `templates/<theme>/light/base/`
- `base/` directory is now required for **each style**
- `meteo/` directory is now resolved per style (dark / light)
- Complete rewrite of wallpaper resolution logic:
  - style → time of day → weather → fallback
- Improved template validation and fallback mechanisms
- Documentation and README updated to reflect the new structure

### Removed
- Removed support for the legacy template structure:
  - `templates/<theme>/base/`

### Fixed
- Edge cases where the wallpaper was not refreshed after a style change
- Inconsistent behavior when switching quickly between dark and light modes

---

## [1.3.1] - 2026-02-05
### Added
- Current wallpaper state mechanism:
  - storage of the last applied wallpaper in `~/.config/wallpaper-smart/wallpaper/current.json`
  - comparison between the current wallpaper and the next one to apply
  - wallpaper is applied only if it is different
- Application version displayed in the UI header
  - improves support, debugging, and user feedback
- User alert when changing language:
  - message displayed in the selected language
  - clear indication that saving + application restart is required
- Visual warning indicator ⚠️ in the dashboard when:
  - no matching weather wallpaper is available
  - fallback to a base image or no valid wallpaper is found

### Changed
- Major optimization of `wallpaper-smart.sh` script:
  - removal of redundant wallpaper applications
  - drastic reduction of GNOME / KDE calls
  - improved stability during long sessions
- Timer frequency is now reliable even at **1 minute**
  - no blocking
  - no wallpaper application loss
- Improved systemd user service behavior:
  - service now works correctly at system startup
  - UI no longer needs to be launched to initialize the wallpaper

### Fixed
- Critical fix: wallpaper stopped updating after multiple successive changes
  - previously required a system reboot
- Fixed `wallpaper-smart.service`:
  - added missing values preventing automatic startup
- UI consistency fixes:
  - dashboard now reflects the actual applied wallpaper state
  - improved readability of errors related to missing wallpapers

---

## [1.3.0] - 2026-02-04
### Added
- Multi-language support (fr/en/de/es/ar/ru/zh) via JSON files in `lang/`
- Language selection in the UI (General tab) with persistence in `config.json`
- Geolocation during installation (automatic default values) with `--no-geo` option
- “City” geolocation mode:
  - city input
  - lat/lon retrieval via Nominatim (OpenStreetMap)
- Location presets (capitals):
  - quick selection
  - real-time weather icon display (indicative / example)
- Real-time weather on presets (visual indicator)
- “About” tab:
  - project presentation
  - version
  - license
  - links (PayPal / BuyMeACoffee)

### Changed
- New wallpaper template structure:
  - `templates/<theme>/base/` → aube.png, midi.png, coucher.png, nuit.png
  - `templates/<theme>/meteo/` → `<prefix>_<moment>.png`
- Improved UI (geolocation ergonomics, presets, quick actions)
- Improved installation process:
  - automatic creation and upgrade of `config.json`
  - default geolocation added during installation
  - more robust template copy (rsync or fallback to cp)

### Fixed
- UI / GTK fixes (general stability + refresh)
- Fixed “hand/pointer” cursor on ComboBox without GTK crashes
- Hover fix: cursor now applies only to the select field, not to external blocks

---

## [1.2.0] - 2026-02-04
### Added
- Improved geolocation presets (better selection)
- Weather detection (Open-Meteo) to display an indicative icon in the preset list
- UI buttons “clear” and “search lat/lon” for city input

### Changed
- More intuitive location UI (modes + better field handling)
- More stable dashboard refresh

### Fixed
- Disable preset_combo when mode = city
- UI focus fixes (orange / hover)

---

## [1.1.0] - 2026-02-03
### Added
- “City” mode introduced in the UI
- Clearer weather → prefix mapping
- Image tab improvements:
  - placeholders
  - previews
  - open base/ and meteo/ directories

### Changed
- Improved config logic and persistence

---

## [1.0.0] - 2026-02-02
### Added
- First stable release
- GTK3 UI (configuration)
- Main script `wallpaper-smart.sh`
- systemd user service + timer
- Configuration via `~/.config/wallpaper-smart/config.json`
- Time-based wallpaper management (dawn / noon / sunset / night)
- Weather via Open-Meteo with configurable mapping
- Wallpaper templates (base + meteo)

---

## [0.1.0] - 2026-01-30
### Added
- Start of the Wallpaper Smart project
- Core concept: dynamic wallpaper based on time of day and weather
