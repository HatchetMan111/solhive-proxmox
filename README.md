solhive-proxmox/
├── README.md
├── LICENSE
├── ct/
│   └── solhive.sh
├── install/
│   └── solhive-install.sh
└── json/
    └── solhive.json

# SolHive Proxmox Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Automatisierte Installation von [SolHive](https://solhive.energy) als Proxmox LXC Container.

## Über SolHive

Solar/EV/Akku/Wärmepumpe/Lasten-Orchestrator mit Priority-Scheduler. PV-Überschuss verteilt sich nach deinen Prioritäten auf Auto, WP, Klima, Pool & Co.

**Features:**
- Priority-Scheduler für PV-Überschuss
- 9 Wallbox-Driver inkl. OCPP
- 28 WR-Profile
- Multi-Battery Support
- §14a compliant
- ML-Forecast
- DE/EN/FR/ES

## ⚠️ Lizenz-Hinweis

SolHive ist unter der [PolyForm Perimeter License 1.0.1](https://polyformproject.org/licenses/perimeter/1.0.1/) lizenziert.

**Erlaubt:**
- ✅ Installation für den eigenen, privaten Gebrauch
- ✅ Automatisierung der Installation

**Nicht erlaubt:**
- ❌ Kommerzielle Nutzung als Managed Service
- ❌ Bereitstellung als Konkurrenzprodukt

Required Notice: Copyright 2025-2026 Markus Nüsser — https://solhive.energy

Dieses Repository stellt lediglich ein Installationsskript bereit (unter MIT-Lizenz, siehe [LICENSE](LICENSE)). Es lädt beim Ausführen das offizielle SolHive-Container-Image von `code.solhive.energy` herunter; der Quellcode von SolHive selbst ist nicht Teil dieses Repos.

## 🚀 Installation

Auf dem Proxmox-VE-Host ausführen:

### One-Liner (empfohlen)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/solhive-proxmox/main/ct/solhive.sh)"
```

Der Installer erstellt einen unprivilegierten Debian-13-LXC-Container, installiert Docker sowie SolHive darin und zeigt am Ende die Web-UI-Adresse an. Timezone, Ressourcen (CPU/RAM/Disk) etc. lassen sich beim Start über den "Advanced"-Modus des Installers anpassen.

### Voraussetzungen

- Proxmox VE 8 oder neuer
- Internetzugang des Proxmox-Hosts (für Debian-Template, Docker-Setup und das SolHive-Image von `code.solhive.energy`)
- Mindestens 4 GB freier Speicher im gewählten Storage

## ⚙️ Konfiguration

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

## 🔄 Update

Denselben One-Liner im Proxmox-VE-Shell erneut gegen die bestehende Container-ID ausführen (der Installer erkennt einen vorhandenen SolHive-Container automatisch und bietet ein Update an), oder direkt im Container:

```bash
cd /opt/solhive
docker compose pull
docker compose up -d --force-recreate
```

## 🗑️ Deinstallation

Container über die Proxmox-Weboberfläche stoppen und löschen (Container auswählen → Mehr → Entfernen), oder per CLI:

```bash
pct stop <CTID>
pct destroy <CTID>
```

## 🛠️ Fehlerbehebung

- **Web-UI nicht erreichbar:** Status prüfen mit `docker compose ps` in `/opt/solhive`, Logs mit `docker compose logs -f solhive`.
- **Zertifikatswarnung im Browser:** Erwartet — SolHive generiert beim ersten Zugriff ein self-signed Zertifikat unter `/opt/solhive/certs`. Für ein vertrauenswürdiges Zertifikat empfiehlt sich ein Reverse Proxy (z. B. nginx/Caddy) davor.
- **Docker-Image lässt sich nicht ziehen:** Prüfen, ob `code.solhive.energy` vom Proxmox-Host erreichbar ist; bei privaten/lizenzpflichtigen Images ggf. vorher `docker login code.solhive.energy` im Container ausführen.

## 🤝 Mitwirken

Issues und Pull Requests für das Installationsskript sind willkommen. Für Bugs oder Feature-Wünsche zu SolHive selbst bitte den offiziellen Kanal unter [solhive.energy](https://solhive.energy) nutzen — dieses Repo pflegt nur die Proxmox-Automatisierung, nicht die Anwendung.

## 📄 Lizenz

Die Installationsskripte in diesem Repository stehen unter der [MIT-Lizenz](LICENSE). SolHive selbst ist ein eigenständiges Produkt unter der PolyForm Perimeter License 1.0.1 (siehe oben) und nicht Teil dieser Lizenzierung.

## Haftungsausschluss

Dieses Repository ist ein inoffizielles Community-Projekt zur Automatisierung der Installation und steht in keiner Verbindung zu SolHive bzw. Markus Nüsser. Nutzung auf eigenes Risiko.
