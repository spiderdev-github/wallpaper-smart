#!/usr/bin/env python3
"""
Test rapide pour vérifier si AppIndicator3 est disponible
"""

import sys

print("🔍 Test de disponibilité d'AppIndicator3...")
print()

# Test 1: Import gi
try:
    import gi
    print("✅ gi (PyGObject) disponible")
except ImportError as e:
    print(f"❌ gi (PyGObject) NON disponible: {e}")
    print("   Installer avec: sudo apt install python3-gi")
    sys.exit(1)

# Test 2: Version GTK
try:
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk
    print(f"✅ GTK 3.0 disponible (version {Gtk.MAJOR_VERSION}.{Gtk.MINOR_VERSION})")
except Exception as e:
    print(f"❌ GTK 3.0 NON disponible: {e}")
    sys.exit(1)

# Test 3: AppIndicator3
try:
    gi.require_version("AppIndicator3", "0.1")
    from gi.repository import AppIndicator3
    print("✅ AppIndicator3 disponible")
    print()
    print("🎉 Tous les tests passés ! L'icône système fonctionnera.")
    sys.exit(0)
except ImportError as e:
    print(f"⚠️  AppIndicator3 NON disponible: {e}")
    print()
    print("📦 Pour installer AppIndicator3 :")
    print("   Debian/Ubuntu: sudo apt install gir1.2-appindicator3-0.1")
    print("   Fedora:        sudo dnf install libappindicator-gtk3")
    print("   Arch:          sudo pacman -S libappindicator-gtk3")
    print()
    print("⚠️  L'application fonctionnera mais SANS icône système.")
    print("   La fenêtre s'ouvrira normalement au démarrage.")
    sys.exit(2)
except Exception as e:
    print(f"❌ Erreur lors du test AppIndicator3: {e}")
    sys.exit(1)
