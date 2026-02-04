# Changelog

## [1.1.0] - 2026-02-04
### Added
- Multi-langue (fr/en/de/es/ar/ru/zh) via fichiers JSON dans `lang/`
- Support KDE Plasma (application du wallpaper via DBus / outils KDE)
- Géolocalisation à l’installation (définition des valeurs par défaut) + option `--no-geo`
- Mode géolocalisation “Ville” (recherche lat/lon via Nominatim - OpenStreetMap)
- Presets de localisation (capitales) avec icône météo en temps réel (indicatif)
- Onglet “À propos” avec liens projet + dons (PayPal / BuyMeACoffee)

### Changed
- Nouvelle arborescence wallpapers : `templates/<theme>/{base,meteo}`
- UI améliorée (ergonomie géoloc, presets, actions rapides)

### Fixed
- Divers correctifs UI/GTK (stabilité + refresh)

## [1.0.0] - 2026-01-xx
### Added
- Première version fonctionnelle
- UI GTK3
- systemd user service + timer
- Gestion des thèmes via templates
- Météo via Open-Meteo (mapping configurable)
