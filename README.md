# SolHive Proxmox Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Automatisierte Installation von [SolHive](https://solhive.energy) als Proxmox LXC Container.

## Was ist SolHive?

SolHive ist ein selbst gehosteter Orchestrator für dein Zuhause mit PV-Anlage: Er verteilt überschüssigen Solarstrom nach frei einstellbaren Prioritäten auf E-Auto, Wärmepumpe, Klimaanlage, Pool, Akku und weitere Verbraucher — statt dass jedes Gerät für sich selbst entscheidet. Läuft komplett lokal (kein Cloud-Zwang), spricht direkt mit gängigen Wechselrichtern, Wallboxen und Batteriespeichern und lernt über einen ML-Forecast dazu, wie viel PV-Überschuss als Nächstes zu erwarten ist.

**Kernfunktionen:**
- Priority-Scheduler: legt selbst fest, welcher Verbraucher zuerst PV-Überschuss bekommt
- 9 Wallbox-Treiber inkl. OCPP — für die meisten gängigen Ladestationen
- 28 Wechselrichter-Profile, auch gemischt in einer Anlage nutzbar
- Multi-Battery-Support
- §14a-konform (steuerbare Verbrauchseinrichtungen nach deutschem EnWG)
- ML-basierte PV-Ertragsprognose
- Oberfläche auf Deutsch, Englisch, Französisch, Spanisch

### Einbindung in Home Assistant

SolHive läuft als eigenständiger Dienst neben Home Assistant und übernimmt die Lastverteilung selbst — es ersetzt HA also nicht, sondern ergänzt es. Zwei gängige Wege, beides zu verbinden:

- **REST/API-Anbindung:** SolHive stellt eine lokale API bereit, über die sich Kennzahlen (aktueller PV-Überschuss, Ladezustand, aktive Prioritäten) als Sensoren in Home Assistant einbinden lassen, z. B. via [RESTful Sensor](https://www.home-assistant.io/integrations/rest/) oder [MQTT](https://www.home-assistant.io/integrations/mqtt/), falls SolHive MQTT-Publishing aktiviert hat.
- **Home Assistant als Datenquelle:** Umgekehrt kann SolHive bestehende HA-Sensoren (z. B. Wetterdaten, individuelle Automationen, Präsenzerkennung) als zusätzlichen Input für seine eigenen Priorisierungsentscheidungen nutzen, sofern der jeweilige Sensor über eine unterstützte Schnittstelle erreichbar ist.

Die genauen Endpunkte, Entitäten-Namen und unterstützten Protokolle hängen von der jeweiligen SolHive-Version ab — verbindliche Details dazu liefert ausschließlich die offizielle Dokumentation unter [solhive.energy](https://solhive.energy); dieses Repository deckt nur die Proxmox-Installation ab, nicht die Konfiguration von SolHive selbst.

## 🚀 Installation

Auf dem Proxmox-VE-Host ausführen:

### One-Liner (empfohlen)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/solhive-proxmox/main/ct/solhive.sh)"
```

Der Installer erstellt einen unprivilegierten Debian-13-LXC-Container, installiert Docker sowie SolHive darin und zeigt am Ende die Web-UI-Adresse an.

### Voraussetzungen

- Proxmox VE 8 oder neuer
- Internetzugang des Proxmox-Hosts (für das Debian-Template, Docker-Setup und das SolHive-Image von `code.solhive.energy`)
- Mindestens 4 GB freier Speicher im gewählten Storage

## 🤝 Mitwirken

Issues und Pull Requests für das Installationsskript sind willkommen. Für Bugs oder Feature-Wünsche zu SolHive selbst bitte den offiziellen Kanal unter [solhive.energy](https://solhive.energy) nutzen — dieses Repo pflegt nur die Proxmox-Automatisierung, nicht die Anwendung.

## Haftungsausschluss

Dieses Repository ist ein inoffizielles Community-Projekt zur Automatisierung der Installation und steht in keiner Verbindung zu SolHive bzw. Markus Nüsser. Nutzung auf eigenes Risiko.

---

## Technisches

### Repo-Struktur

```
solhive-proxmox/
├── README.md
├── LICENSE
├── ct/
│   └── solhive.sh
├── install/
│   └── solhive-install.sh
└── json/
    └── solhive.json
```

### Wie die Installation funktioniert

`ct/solhive.sh` legt den LXC-Container direkt per `pct create` an und ruft anschließend `install/solhive-install.sh` aus **diesem** Repo im Container auf. Bewusst **kein** Rückgriff auf die `build_container()`-Funktion aus dem offiziellen `community-scripts/ProxmoxVE`-Framework: Diese holt das Install-Skript hart-codiert aus dem offiziellen Repo (`.../ProxmoxVE/main/install/<app>.sh`) — für SolHive, das dort nicht gelistet ist, würde das mit einem 404 fehlschlagen, ohne dass die Installation selbst einen Fehler wirft.

### ⚙️ Konfiguration

Nach der Installation liegt alles unter `/opt/solhive` im Container:

| Pfad | Zweck |
|---|---|
| `/opt/solhive/docker-compose.yml` | Compose-Definition des SolHive-Containers |
| `/opt/solhive/data` | Persistente Anwendungsdaten |
| `/opt/solhive/certs` | Self-signed Zertifikat (wird beim ersten Zugriff generiert) |

Änderungen an `docker-compose.yml` übernehmen nach:

```bash
cd /opt/solhive
docker compose up -d
```

### 🔄 Update

Denselben One-Liner mit der bestehenden Container-ID erneut ausführen — das Skript erkennt einen vorhandenen Container automatisch und aktualisiert ihn, statt einen neuen anzulegen:

```bash
CTID=<bestehende-CTID> bash -c "$(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/solhive-proxmox/main/ct/solhive.sh)"
```

Oder direkt im Container:

```bash
cd /opt/solhive
docker compose pull
docker compose up -d --force-recreate
```

### 🗑️ Deinstallation

```bash
pct stop <CTID>
pct destroy <CTID>
```

### 🛠️ Fehlerbehebung

- **Web-UI nicht erreichbar / Skript "erfolgreich" aber Seite antwortet nicht:** In früheren Versionen dieses Repos lag das an der oben beschriebenen 404-Falle von `build_container()` — mit der aktuellen Version behoben. Bei weiterhin bestehenden Problemen: Status prüfen mit `pct exec <CTID> -- docker compose -f /opt/solhive/docker-compose.yml ps`, Logs mit `pct exec <CTID> -- docker compose -f /opt/solhive/docker-compose.yml logs -f`.
- **Zertifikatswarnung im Browser:** Erwartet — SolHive generiert beim ersten Zugriff ein self-signed Zertifikat unter `/opt/solhive/certs`. Für ein vertrauenswürdiges Zertifikat empfiehlt sich ein Reverse Proxy (z. B. nginx/Caddy) davor.
- **Docker-Image lässt sich nicht ziehen:** Prüfen, ob `code.solhive.energy` vom Container aus erreichbar ist (`pct exec <CTID> -- curl -I https://code.solhive.energy`); bei privaten/lizenzpflichtigen Images ggf. vorher `docker login code.solhive.energy` im Container ausführen.

### 📄 Lizenz

Die Installationsskripte in diesem Repository stehen unter der [MIT-Lizenz](LICENSE).

SolHive selbst ist ein eigenständiges Produkt und unter der [PolyForm Perimeter License 1.0.1](https://polyformproject.org/licenses/perimeter/1.0.1/) lizenziert — nicht Teil dieser MIT-Lizenzierung.

**Erlaubt laut SolHive-Lizenz:**
- ✅ Installation für den eigenen, privaten Gebrauch
- ✅ Automatisierung der Installation

**Nicht erlaubt:**
- ❌ Kommerzielle Nutzung als Managed Service
- ❌ Bereitstellung als Konkurrenzprodukt

Required Notice: Copyright 2025-2026 Markus Nüsser — https://solhive.energy

Dieses Repository stellt lediglich ein Installationsskript bereit. Es lädt beim Ausführen das offizielle SolHive-Container-Image von `code.solhive.energy` herunter; der Quellcode von SolHive selbst ist nicht Teil dieses Repos.
