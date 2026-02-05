# Changelog

🇬🇧 **English version**: [CHANGELOG.md](CHANGELOG.md)

---

## [2.0.0] - 2026-02-05
### 🚀 Mise à jour majeure – Intégration du style desktop (clair / sombre)

### Added
- Changement automatique du fond d’écran selon le style du desktop GNOME (clair / sombre)
- Réaction instantanée aux changements de style (mécanisme event-driven)
- Ajout de nouveaux fichiers systemd user :
  - `wallpaper-smart-style-hook.path`
  - `wallpaper-smart-style-hook.service`
  - `wallpaper-smart-on-style-change.sh`
- Intégration complète du paramètre GNOME `color-scheme`
- Rafraîchissement du fond d’écran en temps réel, sans dépendre du timer

### Changed
- **Changement incompatible** : nouvelle structure obligatoire des templates :
  - `templates/<theme>/dark/base/`
  - `templates/<theme>/light/base/`
- Le dossier `base/` est désormais requis pour **chaque style**
- Le dossier `meteo/` est maintenant résolu par style (clair / sombre)
- Refonte complète de la logique de résolution des fonds d’écran :
  - style → moment de la journée → météo → fallback
- Amélioration de la validation des templates et des mécanismes de repli
- Documentation et README mis à jour pour refléter la nouvelle structure

### Removed
- Suppression du support de l’ancienne structure :
  - `templates/<theme>/base/`

### Fixed
- Cas limites où le fond d’écran ne se mettait pas à jour lors d’un changement de style
- Comportements incohérents lors de bascules rapides clair ↔ sombre

---

## [1.3.1] - 2026-02-05
### Added
- Mécanisme d’état du fond d’écran courant :
  - stockage du dernier wallpaper appliqué dans `~/.config/wallpaper-smart/wallpaper/current.json`
  - comparaison entre le fond d’écran courant et le prochain à appliquer
  - application du fond d’écran uniquement si celui-ci est différent
- Affichage de la version de l’application dans le header de l’UI
  - facilite le support, le debug et les retours utilisateurs
- Alerte utilisateur lors du changement de langue :
  - message affiché dans la langue sélectionnée
  - indication claire qu’un enregistrement suivi d’un redémarrage de l’application est requis
- Indicateur visuel ⚠️ dans le dashboard lorsque :
  - aucun fond d’écran météo correspondant n’est disponible
  - fallback sur une image de base ou absence de fond valide

### Changed
- Optimisation majeure du script `wallpaper-smart.sh` :
  - suppression des applications redondantes du fond d’écran
  - réduction drastique des appels GNOME / KDE
  - amélioration de la stabilité sur les sessions longues
- Fréquence du timer désormais fiable même à **1 minute**
  - sans blocage
  - sans perte d’application du fond d’écran
- Amélioration du comportement du service systemd user :
  - fonctionnement correct dès le démarrage du système
  - plus besoin de lancer l’UI pour initialiser le fond d’écran

### Fixed
- Correctif critique : bug où le fond d’écran cessait de s’appliquer après plusieurs changements successifs
  - nécessitait auparavant un redémarrage du PC
- Correction du fichier `wallpaper-smart.service` :
  - ajout des valeurs manquantes empêchant le démarrage automatique
- Correctifs de cohérence UI :
  - dashboard désormais aligné avec l’état réel du fond d’écran appliqué
  - meilleure lisibilité des erreurs liées aux fonds manquants

---

## [1.3.0] - 2026-02-04
### Added
- Support multi-langue (fr/en/de/es/ar/ru/zh) via fichiers JSON dans `lang/`
- Sélection de la langue dans l’UI (onglet Général) avec sauvegarde dans `config.json`
- Géolocalisation à l’installation (définition automatique des valeurs par défaut) avec option `--no-geo`
- Mode de géolocalisation « Ville » :
  - saisie d’une ville
  - récupération des coordonnées lat/lon via Nominatim (OpenStreetMap)
- Presets de localisation (capitales) :
  - sélection rapide
  - affichage d’une icône météo en temps réel (indicatif)
- Météo en temps réel sur les presets (indicateur visuel)
- Onglet « À propos » :
  - présentation du projet
  - version
  - licence
  - liens (PayPal / BuyMeACoffee)

### Changed
- Nouvelle arborescence des wallpapers :
  - `templates/<theme>/base/` → aube.png, midi.png, coucher.png, nuit.png
  - `templates/<theme>/meteo/` → `<prefix>_<moment>.png`
- UI améliorée (ergonomie géolocalisation, presets, actions rapides)
- Processus d’installation amélioré :
  - création et mise à jour automatique du `config.json`
  - ajout d’une géolocalisation par défaut lors de l’installation
  - copie des templates plus robuste (rsync ou fallback cp)

### Fixed
- Correctifs UI / GTK (stabilité générale et rafraîchissement)
- Correction du curseur « main/pointer » sur les ComboBox sans crash GTK
- Correction du survol :
  - le curseur ne s’applique plus à un bloc externe
  - uniquement sur le champ select

---

## [1.2.0] - 2026-02-04
### Added
- Amélioration des presets de géolocalisation (meilleure sélection)
- Détection météo (Open-Meteo) pour afficher une icône indicative dans la liste des presets
- Boutons UI « vider » et « rechercher lat/lon » pour la saisie ville

### Changed
- UI localisation plus intuitive (modes et champs mieux gérés)
- Rafraîchissement du dashboard plus stable

### Fixed
- Désactivation de `preset_combo` lorsque le mode = city
- Correctifs de focus UI (orange / hover)

---

## [1.1.0] - 2026-02-03
### Added
- Introduction du mode « city » (ville) dans l’UI
- Mapping météo → préfixes plus clair
- Améliorations de l’onglet Images :
  - placeholders
  - previews
  - ouverture des dossiers base/ et meteo/

### Changed
- Amélioration de la logique de configuration et de la sauvegarde

---

## [1.0.0] - 2026-02-02
### Added
- Première version stable
- UI GTK3 (configuration)
- Script principal `wallpaper-smart.sh`
- Service et timer systemd user
- Configuration via `~/.config/wallpaper-smart/config.json`
- Gestion des fonds d’écran selon l’heure (aube / midi / coucher / nuit)
- Météo via Open-Meteo avec mapping configurable
- Templates de wallpapers (base + meteo)

---

## [0.1.0] - 2026-01-30
### Added
- Début du projet Wallpaper Smart
- Base du concept : fond d’écran dynamique selon l’heure et la météo
