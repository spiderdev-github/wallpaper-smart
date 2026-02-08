# Changelog

🇬🇧 **English version** : [CHANGELOG.md](CHANGELOG.md)

---

## [1.0.0] - 2026-02-07
### 🎉 Première version stable – prête pour la production

### Ajouts
- Interface de configuration GTK3 complète
- Gestion dynamique du fond d’écran basée sur :
  - le moment de la journée (aube / midi / coucher / nuit)
  - la météo en temps réel (Open-Meteo)
- Support multilingue (fr/en/de/es/ar/ru/zh)
- Gestion de la géolocalisation :
  - détection automatique lors de l’installation
  - mode « Ville » avec récupération latitude / longitude (OpenStreetMap / Nominatim)
  - emplacements prédéfinis avec icônes météo indicatives
- Mécanisme d’état du fond d’écran courant :
  - stockage du dernier fond appliqué dans  
    `~/.config/wallpaper-smart/wallpaper/current.json`
  - application du fond **uniquement s’il est différent**
- Indicateurs visuels d’avertissement ⚠️ dans le tableau de bord lorsque :
  - aucun fond météo correspondant n’est disponible
  - un repli vers une image de base ou aucun fond valide n’est trouvé
- Affichage de la version de l’application dans l’en-tête de l’interface
- Onglet « À propos » avec présentation du projet, version, licence et liens de support

### Modifications
- **Comportement systemd finalisé** :
  - les services démarrent désormais **immédiatement à la connexion utilisateur**
  - le fond d’écran est appliqué au démarrage de la session sans attendre le timer
- Mise à jour des fichiers `.service` :
  - ordre de démarrage corrigé
  - exécution fiable à la connexion
- Installateur mis à jour :
  - services activés et démarrés dès l’installation
  - suppression de l’initialisation différée par le timer
- Amélioration des aperçus dans l’interface :
  - les blocs d’images de base et météo utilisent la même logique
  - rafraîchissement cohérent et gestion uniforme des fallbacks
- Amélioration du format des messages d’erreur et d’état :
  - messages sur plusieurs lignes pour une meilleure lisibilité
  - séparation claire entre icône, chemin et description
- Optimisation majeure de `wallpaper-smart.sh` :
  - réduction des applications de fond d’écran redondantes
  - diminution des appels GNOME / KDE
  - meilleure stabilité sur les longues sessions

### Corrections
- Fond d’écran non appliqué au démarrage de la session
- Rafraîchissement incohérent entre les aperçus base et météo
- Cas limites liés au timer provoquant des mises à jour manquées
- Problèmes d’interface dus aux messages d’erreur sur une seule ligne
- Problèmes de démarrage des services nécessitant auparavant le lancement de l’UI ou un redémarrage

---

## [0.4.0] - 2026-02-05
### 🚀 Mise à jour majeure – intégration du style du bureau (clair / sombre)

### Ajouts
- Changement automatique du fond d’écran selon le style GNOME (clair / sombre)
- Réaction instantanée aux changements de style (mécanisme événementiel)
- Nouveaux fichiers systemd utilisateur :
  - `wallpaper-smart-style-hook.path`
  - `wallpaper-smart-style-hook.service`
  - `wallpaper-smart-on-style-change.sh`
- Intégration complète avec le paramètre GNOME `color-scheme`
- Rafraîchissement du fond d’écran en temps réel sans dépendre du timer

### Modifications
- **Changement cassant** : nouvelle structure de templates obligatoire :
  - `templates/<theme>/dark/base/`
  - `templates/<theme>/light/base/`
- Le dossier `base/` est désormais requis pour **chaque style**
- Le dossier `meteo/` est désormais résolu par style (clair / sombre)
- Réécriture complète de la logique de résolution des fonds :
  - style → moment de la journée → météo → fallback
- Amélioration de la validation des templates et des mécanismes de repli
- Documentation et README mis à jour pour refléter la nouvelle structure

### Suppressions
- Suppression du support de l’ancienne structure de templates :
  - `templates/<theme>/base/`

### Corrections
- Cas limites où le fond d’écran n’était pas rafraîchi après un changement de style
- Comportement incohérent lors de bascules rapides entre clair et sombre

---

## [0.3.1] - 2026-02-05
### Ajouts
- Affichage de la version de l’application dans l’en-tête de l’interface
- Alerte utilisateur lors du changement de langue :
  - message affiché dans la langue sélectionnée
  - indication claire qu’un enregistrement et un redémarrage sont nécessaires

### Modifications
- Optimisation de `wallpaper-smart.sh` :
  - suppression des applications de fond redondantes
  - réduction des appels GNOME / KDE
- Amélioration du comportement du service systemd utilisateur :
  - fonctionnement correct au démarrage du système
  - l’interface n’a plus besoin d’être lancée pour initialiser le fond d’écran

### Corrections
- Problème critique où le fond d’écran cessait de se mettre à jour après plusieurs changements successifs
- Correction de `wallpaper-smart.service` :
  - ajout de valeurs manquantes empêchant le démarrage automatique
- Le tableau de bord reflète désormais correctement l’état réel du fond appliqué

---

## [0.3.0] - 2026-02-04
### Ajouts
- Support multilingue via des fichiers JSON dans `lang/`
- Sélection de la langue dans l’interface avec persistance dans `config.json`
- Mode de géolocalisation « Ville » avec récupération via Nominatim
- Emplacements prédéfinis (capitales) avec icônes météo indicatives
- Onglet « À propos » avec informations projet et liens de support

### Modifications
- Nouvelle structure des templates de fond d’écran :
  - `templates/<theme>/base/` → aube.png, midi.png, coucher.png, nuit.png
  - `templates/<theme>/meteo/` → `<prefix>_<moment>.png`
- Amélioration du processus d’installation :
  - création et mise à jour automatiques de `config.json`
  - ajout d’une géolocalisation par défaut lors de l’installation

### Corrections
- Problèmes de stabilité UI / GTK
- Comportement du curseur et du survol des ComboBox

---

## [0.2.0] - 2026-02-04
### Ajouts
- Amélioration des emplacements de géolocalisation prédéfinis
- Détection météo (Open-Meteo) pour affichage d’icônes indicatives
- Boutons UI pour la recherche de ville et l’effacement des champs

### Modifications
- Interface de localisation plus intuitive
- Rafraîchissement du tableau de bord plus stable

### Corrections
- Désactivation de la sélection des presets lorsque le mode ville est actif
- Corrections du focus et du survol de l’interface

---

## [0.1.0] - 2026-01-30
### Ajouts
- Début du projet Wallpaper Smart
- Concept principal : fond d’écran dynamique basé sur le moment de la journée et la météo
- Scripts initiaux, logique de configuration et templates prototypes
