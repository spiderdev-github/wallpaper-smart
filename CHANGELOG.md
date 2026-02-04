# Changelog

## [1.3.0] - 2026-02-04
### Added
- Multi-langue (fr/en/de/es/ar/ru/zh) via fichiers JSON dans `lang/`
- Sélection de la langue dans l’UI (onglet Général) + sauvegarde dans `config.json`
- Géolocalisation à l’installation (définition automatique des valeurs par défaut) + option `--no-geo`
- Mode géolocalisation “Ville” :
  - saisie d’une ville
  - récupération lat/lon via Nominatim (OpenStreetMap)
- Presets de localisation (capitales) :
  - sélection rapide
  - affichage d’une icône météo en temps réel (indicatif / exemple)
- Météo en temps réel sur les presets (exemple visuel / indicateur)
- Onglet “À propos” :
  - présentation du projet
  - version
  - licence
  - liens (PayPal / BuyMeACoffee)

### Changed
- Nouvelle arborescence wallpapers :
  - `templates/<theme>/base/` → aube.png, midi.png, coucher.png, nuit.png
  - `templates/<theme>/meteo/` → `<prefix>_<moment>.png`
- UI améliorée (ergonomie géoloc, presets, actions rapides)
- Installation améliorée :
  - création + upgrade automatique du `config.json`
  - ajout d’une géoloc par défaut lors de l’installation
  - copie templates plus robuste (rsync ou fallback cp)

### Fixed
- Correctifs UI/GTK (stabilité générale + refresh)
- Fix curseur “main/pointer” sur les ComboBox sans crash GTK
- Correction du survol : le curseur ne s’applique plus à un bloc externe, uniquement sur le champ select


## [1.2.0] - 2026-02-04
### Added
- Presets géolocalisation améliorés (meilleure sélection)
- Détection météo (Open-Meteo) pour afficher une icône indicative dans la liste presets
- Boutons UI “vider” + “rechercher lat/lon” pour la saisie ville

### Changed
- UI localisation plus intuitive (modes + champs mieux gérés)
- Rafraîchissement dashboard plus stable

### Fixed
- Désactivation preset_combo quand mode = city
- Correctifs de focus UI (orange/hover)


## [1.1.0] - 2026-02-03
### Added
- Mode “city” (ville) introduit dans l’UI
- Mapping météo → préfixes plus clair
- Améliorations onglet Images :
  - placeholders
  - previews
  - ouverture dossiers base/ et meteo/

### Changed
- Amélioration logique de config + sauvegarde


## [1.0.0] - 2026-02-02
### Added
- Première version stable
- UI GTK3 (configuration)
- Script principal `wallpaper-smart.sh`
- Service + timer systemd user
- Configuration via `~/.config/wallpaper-smart/config.json`
- Gestion des wallpapers selon l’heure (aube/midi/coucher/nuit)
- Météo via Open-Meteo + mapping configurable
- Templates wallpapers (base + meteo)


## [0.1.0] - 2026-01-30
### Added
- Début du projet Wallpaper Smart
- Base du concept : fond d’écran dynamique selon l’heure + météo
