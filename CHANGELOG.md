# Changelog

🇫🇷 **Version française** : [CHANGELOG.fr.md](CHANGELOG.fr.md)

---

## [1.0.0] - 2026-02-07
### 🎉 First stable release – production ready

### Added
- Full GTK3 configuration UI
- Dynamic wallpaper management based on:
  - time of day (dawn / noon / sunset / night)
  - real-time weather (Open-Meteo)
- Multi-language support (fr/en/de/es/ar/ru/zh)
- Geolocation support:
  - automatic detection during installation
  - city mode with latitude / longitude lookup (OpenStreetMap / Nominatim)
  - preset locations with indicative weather icons
- Current wallpaper state mechanism:
  - storage of the last applied wallpaper in  
    `~/.config/wallpaper-smart/wallpaper/current.json`
  - wallpaper is applied **only if different**
- Visual warning indicators ⚠️ in the dashboard when:
  - no matching weather wallpaper is available
  - fallback to base image or no valid wallpaper is found
- Application version displayed in the UI header
- “About” tab with project presentation, version, license, and support links

### Changed
- **Systemd startup behavior finalized**:
  - services now start **immediately at user login**
  - wallpaper is applied at session startup without waiting for the timer
- Updated `.service` files:
  - correct startup ordering
  - reliable execution at login
- Installer updated accordingly:
  - services are enabled and started during installation
  - no delayed initialization via timer
- Improved UI previews:
  - base and weather image blocks now share the same logic
  - consistent refresh behavior and fallback handling
- Improved error and status message formatting:
  - multi-line messages for better readability
  - clearer separation between icon, path, and error description
- Major optimization of `wallpaper-smart.sh`:
  - reduced redundant wallpaper applications
  - fewer GNOME / KDE calls
  - improved long-session stability

### Fixed
- Wallpaper not applied at session startup
- Inconsistent preview refresh between base images and weather images
- Timer-related edge cases causing missed wallpaper updates
- UI inconsistencies caused by long single-line error messages
- Service startup issues previously requiring UI launch or system reboot

---

## [0.4.0] - 2026-02-05
### 🚀 Major update – Desktop style integration (dark / light)

### Added
- Automatic wallpaper switching based on GNOME desktop style (dark / light)
- Instant reaction to desktop style changes (event-driven mechanism)
- New systemd user files:
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

## [0.3.1] - 2026-02-05
### Added
- Application version displayed in the UI header
- User alert when changing language:
  - message displayed in the selected language
  - clear indication that saving and application restart are required

### Changed
- Optimized `wallpaper-smart.sh`:
  - removal of redundant wallpaper applications
  - reduced GNOME / KDE calls
- Improved systemd user service behavior:
  - service now works correctly at system startup
  - UI no longer needs to be launched to initialize the wallpaper

### Fixed
- Critical issue where wallpaper stopped updating after multiple successive changes
- Fixed `wallpaper-smart.service`:
  - added missing values preventing automatic startup
- Dashboard now correctly reflects the applied wallpaper state

---

## [0.3.0] - 2026-02-04
### Added
- Multi-language support via JSON files in `lang/`
- Language selection in the UI with persistence in `config.json`
- “City” geolocation mode with Nominatim lookup
- Location presets (capitals) with indicative weather icons
- “About” tab with project information and support links

### Changed
- New wallpaper template structure:
  - `templates/<theme>/base/` → aube.png, midi.png, coucher.png, nuit.png
  - `templates/<theme>/meteo/` → `<prefix>_<moment>.png`
- Improved installation process:
  - automatic creation and upgrade of `config.json`
  - default geolocation added during installation

### Fixed
- UI / GTK stability issues
- ComboBox cursor and hover behavior

---

## [0.2.0] - 2026-02-04
### Added
- Improved geolocation presets
- Weather detection (Open-Meteo) for indicative icons
- UI buttons for city search and clearing input

### Changed
- More intuitive location UI
- More stable dashboard refresh

### Fixed
- Preset selection disabled when city mode is active
- UI focus and hover inconsistencies

---

## [0.1.0] - 2026-01-30
### Added
- Start of the Wallpaper Smart project
- Core concept: dynamic wallpaper based on time of day and weather
- Initial scripts, configuration logic, and prototype templates
