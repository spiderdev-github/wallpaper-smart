import os
import sys
import json
import time
import tempfile
import requests

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel
from PySide6.QtWebEngineWidgets import QWebEngineView


# No accents in comments (per user preference)
DEFAULT_CITIES = [
    {"name": "Paris", "lat": 48.8566, "lon": 2.3522},
    {"name": "Strasbourg", "lat": 48.5734, "lon": 7.7521},
    {"name": "London", "lat": 51.5074, "lon": -0.1278},
    {"name": "New York", "lat": 40.7128, "lon": -74.0060},
    {"name": "Rio de Janeiro", "lat": -22.9068, "lon": -43.1729},
    {"name": "Cape Town", "lat": -33.9249, "lon": 18.4241},
    {"name": "Cairo", "lat": 30.0444, "lon": 31.2357},
    {"name": "Moscow", "lat": 55.7558, "lon": 37.6173},
    {"name": "Mumbai", "lat": 19.0760, "lon": 72.8777},
    {"name": "Bangkok", "lat": 13.7563, "lon": 100.5018},
    {"name": "Tokyo", "lat": 35.6762, "lon": 139.6503},
    {"name": "Sydney", "lat": -33.8688, "lon": 151.2093},
]


def fetch_weather_openweather(api_key: str, lat: float, lon: float, units: str = "metric", lang: str = "fr") -> dict:
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": api_key,
        "units": units,
        "lang": lang,
    }
    r = requests.get(url, params=params, timeout=10)
    r.raise_for_status()
    data = r.json()

    w = (data.get("weather") or [{}])[0]
    main = data.get("main") or {}
    wind = data.get("wind") or {}

    icon = w.get("icon", "")
    desc = w.get("description", "")
    temp = main.get("temp", None)
    humidity = main.get("humidity", None)
    wind_ms = wind.get("speed", None)

    return {
        "icon": icon,
        "desc": desc,
        "temp": temp,
        "humidity": humidity,
        "wind_ms": wind_ms,
    }


def build_map_html(markers: list, center=(20.0, 0.0), zoom=2) -> str:
    # Markers: list of dict {name, lat, lon, icon_url, popup_html}
    markers_json = json.dumps(markers)

    html = f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Live Meteo</title>
  <link
    rel="stylesheet"
    href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
    integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
    crossorigin=""
  />
  <style>
    html, body, #map {{ height: 100%; margin: 0; }}
    .popup-title {{ font-weight: 700; margin-bottom: 4px; }}
    .popup-row {{ margin: 2px 0; }}
  </style>
</head>
<body>
  <div id="map"></div>

  <script
    src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
    integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
    crossorigin=""
  ></script>

  <script>
    const map = L.map('map', {{
      worldCopyJump: true
    }}).setView([{center[0]}, {center[1]}], {zoom});

    L.tileLayer('https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png', {{
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap'
    }}).addTo(map);

    const markers = {markers_json};

    markers.forEach(m => {{
      const icon = L.icon({{
        iconUrl: m.icon_url,
        iconSize: [50, 50],
        iconAnchor: [25, 25],
        popupAnchor: [0, -20],
      }});

      L.marker([m.lat, m.lon], {{ icon }}).addTo(map)
        .bindPopup(m.popup_html, {{ maxWidth: 260 }});
    }});
  </script>
</body>
</html>
"""
    return html


class LiveMeteoWidget(QWidget):
    def __init__(self, api_key: str, cities=None, refresh_seconds: int = 600, parent=None):
        super().__init__(parent)
        self.api_key = api_key.strip()
        self.cities = cities if cities is not None else DEFAULT_CITIES
        self.refresh_seconds = int(refresh_seconds)

        self.setWindowTitle("Live Meteo")
        layout = QVBoxLayout(self)

        self.status = QLabel("")
        layout.addWidget(self.status)

        self.web = QWebEngineView()
        layout.addWidget(self.web)

        self._tmp_html_path = os.path.join(tempfile.gettempdir(), "live_meteo_map.html")

        self.timer = QTimer(self)
        self.timer.timeout.connect(self.refresh)
        self.timer.start(self.refresh_seconds * 1000)

        self.refresh()

    def refresh(self):
        if not self.api_key:
            self.status.setText("API key OpenWeather manquante. Definis OPENWEATHER_API_KEY.")
            self.web.setHtml("<html><body><h3>OpenWeather API key manquante</h3></body></html>")
            return

        self.status.setText("Mise a jour meteo...")
        markers = []

        ok = 0
        failed = 0

        for c in self.cities:
            name = c["name"]
            lat = float(c["lat"])
            lon = float(c["lon"])

            try:
                w = fetch_weather_openweather(self.api_key, lat, lon, units="metric", lang="fr")
                icon_code = w["icon"] or "01d"
                icon_url = f"https://openweathermap.org/img/wn/{icon_code}@2x.png"

                temp = w["temp"]
                desc = w["desc"] or ""
                humidity = w["humidity"]
                wind_ms = w["wind_ms"]

                # Build popup HTML
                rows = []
                if temp is not None:
                    rows.append(f"<div class='popup-row'>Temp: {temp:.1f}°C</div>")
                if desc:
                    rows.append(f"<div class='popup-row'>Etat: {desc}</div>")
                if humidity is not None:
                    rows.append(f"<div class='popup-row'>Humidite: {humidity}%</div>")
                if wind_ms is not None:
                    rows.append(f"<div class='popup-row'>Vent: {wind_ms:.1f} m/s</div>")

                popup_html = (
                    "<div>"
                    f"<div class='popup-title'>{name}</div>"
                    + "".join(rows)
                    + "</div>"
                )

                markers.append({
                    "name": name,
                    "lat": lat,
                    "lon": lon,
                    "icon_url": icon_url,
                    "popup_html": popup_html
                })
                ok += 1

            except Exception as e:
                failed += 1

        html = build_map_html(markers, center=(20.0, 0.0), zoom=2)

        with open(self._tmp_html_path, "w", encoding="utf-8") as f:
            f.write(html)

        self.web.load(QUrl.fromLocalFile(self._tmp_html_path))
        self.status.setText(f"OK: {ok} | Erreurs: {failed} | Derniere maj: {time.strftime('%H:%M:%S')}")


def main():
    api_key = os.environ.get("OPENWEATHER_API_KEY", "").strip()

    app = QApplication(sys.argv)
    w = LiveMeteoWidget(api_key=api_key, refresh_seconds=600)
    w.resize(1200, 700)
    w.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
