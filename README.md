# 🌐 Apache HTTPD — Open Source Audit Project

> A comprehensive open-source software audit of the **Apache HTTP Server (httpd)**, including origin analysis, license review, Linux system integration, and practical shell scripts for server administration.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell Scripts](https://img.shields.io/badge/Scripts-10%20Bash-green.svg)](#-required-scripts-assignment)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2FDebian-orange.svg)](#-dependencies)

---

## 📋 Table of Contents

- [About the Project](#-about-the-project)
- [Chosen Software](#-chosen-software)
- [Project Structure](#-project-structure)
- [Dependencies](#-dependencies)
- [Installation & Setup](#-installation--setup)
- [Required Scripts](#-required-scripts-assignment)
- [How to Run Scripts](#-how-to-run-scripts)
- [Advanced Scripts](#-advanced-scripts-bonus)
- [Sample Data](#-sample-data)
- [License Analysis](#-license-analysis)
- [Open Source vs Proprietary](#-open-source-vs-proprietary)
- [Note to Evaluator](#-note-to-evaluator)
- [License](#-license)

---

## 🎯 About the Project

This project is an academic audit of the **Apache HTTP Server**, one of the most influential open-source projects in computing history. It covers:

- **History & Philosophy** — Why Apache was created and how it shaped the open-source movement
- **License & Freedoms** — Analysis of the Apache License 2.0 and the 4 Freedoms of Free Software
- **Linux Integration** — How Apache runs as a systemd service with configs, logs, and modules
- **Practical Scripting** — 5 required scripts demonstrating core bash concepts + 5 advanced bonus scripts

---

## 🏛️ Chosen Software

| Attribute | Details |
|-----------|---------|
| **Software** | Apache HTTP Server (httpd) |
| **First Release** | 1995 |
| **License** | Apache License 2.0 |
| **Language** | C |
| **Maintained By** | Apache Software Foundation (ASF) |
| **Website** | [httpd.apache.org](https://httpd.apache.org) |
| **Market Share** | ~30% of all websites globally |

**Why Apache?** It powers the backbone of the internet, has a rich origin story, deep Linux integration, and provides excellent opportunities for scripting and system administration.

---

## 📁 Project Structure

```
Open-Source-Software/
├── scripts/
│   ├── required/                         # 5 assignment-required scripts
│   │   ├── 01_system_identity.sh         # Variables, uname, echo
│   │   ├── 02_package_inspector.sh       # if-else, case, dpkg/rpm
│   │   ├── 03_disk_permission_audit.sh   # for loop, du, ls -ld, stat
│   │   ├── 04_log_analyzer.sh            # while-read loop, grep, counters
│   │   └── 05_manifest_generator.sh      # read input, file write (> >>)
│   └── advanced/                         # 5 bonus enterprise-grade scripts
│       ├── apache_health_monitor.sh
│       ├── apache_log_analyzer.sh
│       ├── apache_vhost_manager.sh
│       ├── apache_security_audit.sh
│       └── apache_backup_restore.sh
├── sample_data/
│   ├── sample_access.log
│   ├── sample_error.log
│   └── sample_apache2.conf
├── docs/
│   ├── REPORT_OUTLINE.md
│   └── VIVA_PREP.md
├── screenshots/                          # Script execution screenshots
├── README.md
├── LICENSE
└── .gitignore
```

---

## 📦 Dependencies

| Dependency | Purpose |
|-----------|---------|
| **Linux** | Ubuntu 20.04+ / Debian 11+ (or WSL on Windows) |
| **Bash** | Shell interpreter (pre-installed) |
| **Apache2** | `sudo apt install apache2` — the audited software |
| **Core tools** | `awk`, `grep`, `du`, `stat`, `tar` — pre-installed on most Linux |

---

## 🚀 Installation & Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/goyalk01/Open-Source-Software.git
cd Open-Source-Software
```

### Step 2: Install Apache
```bash
sudo apt update
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
```

### Step 3: Verify Apache
```bash
sudo systemctl status apache2
apache2 -v
curl http://localhost
```

### Step 4: Make Scripts Executable
```bash
chmod +x scripts/required/*.sh
chmod +x scripts/advanced/*.sh
```

---

## 📝 Required Scripts (Assignment)

These 5 scripts fulfil the assignment requirements. Each demonstrates specific bash scripting concepts.

| # | Script | Concepts Demonstrated | Purpose |
|---|--------|----------------------|---------|
| 1 | `01_system_identity.sh` | Variables, `uname`, `echo`, command substitution `$()` | Gathers system & Apache identity info |
| 2 | `02_package_inspector.sh` | `if-else`, `case` statement, `dpkg`/`rpm` | Inspects Apache package details |
| 3 | `03_disk_permission_audit.sh` | `for` loop, arrays, `du`, `ls -ld`, `stat` | Audits disk usage & directory permissions |
| 4 | `04_log_analyzer.sh` | `while IFS= read -r`, `grep -iq`, counter variables | Reads log file line-by-line, counts patterns |
| 5 | `05_manifest_generator.sh` | `read -r -p`, `>` (create), `>>` (append), `cat` | Collects user input, writes manifest file |

---

## ▶️ How to Run Scripts

```bash
# Navigate to project directory
cd Open-Source-Software

# Script 1: System Identity (no arguments needed)
bash scripts/required/01_system_identity.sh

# Script 2: Package Inspector (default: apache2, or pass package name)
bash scripts/required/02_package_inspector.sh

# Script 3: Disk Audit (may need sudo for some directories)
sudo bash scripts/required/03_disk_permission_audit.sh

# Script 4: Log Analyzer (uses sample data or system log)
bash scripts/required/04_log_analyzer.sh sample_data/sample_error.log

# Script 5: Manifest Generator (interactive — enter your details)
bash scripts/required/05_manifest_generator.sh
```

Each script can be run with:
```bash
clear
bash scripts/required/01_system_identity.sh
```

---

## 🚀 Advanced Scripts (Bonus)

5 enterprise-grade scripts demonstrating real-world Apache administration:

| Script | Purpose |
|--------|---------|
| `apache_health_monitor.sh` | Full server health check (service, ports, HTTP response) |
| `apache_log_analyzer.sh` | Traffic analytics with charts and threat detection |
| `apache_vhost_manager.sh` | Interactive virtual host management |
| `apache_security_audit.sh` | Security config audit with A-F grade |
| `apache_backup_restore.sh` | Backup/restore with retention and logging |

Located in `scripts/advanced/` — see comments in each file for details.

---

## 📊 Sample Data

| File | Description |
|------|-------------|
| `sample_access.log` | 40 entries with varied IPs, status codes, and attack patterns |
| `sample_error.log` | 15 entries with file-not-found, auth errors, PHP errors |
| `sample_apache2.conf` | Complete config with security settings, virtual hosts, SSL |

---

## ⚖️ License Analysis

### Apache License 2.0

| Aspect | Apache 2.0 | GPL v2 | MIT |
|--------|-----------|--------|-----|
| Commercial use | ✅ | ✅ | ✅ |
| Must share modified source | ❌ | ✅ (copyleft) | ❌ |
| Patent grant | ✅ Explicit | ❌ | ❌ |
| Attribution required | ✅ | ✅ | ✅ |

**Key insight:** Companies can modify Apache code without sharing changes — this is why tech giants prefer the Apache License.

---

## ⚔️ Open Source vs Proprietary

| Feature | Apache HTTPD | Microsoft IIS |
|---------|-------------|---------------|
| **Cost** | Free | Windows Server license |
| **Source Code** | Open | Closed |
| **Platform** | Cross-platform | Windows only |
| **Configuration** | Text files | GUI-based |
| **Community** | Global open-source | Microsoft support |
| **Market Share** | ~30% | ~7% |

---

## 📌 Note to Evaluator

This project contains two sets of shell scripts:

**Required Scripts** (`scripts/required/`) — 5 scripts that directly fulfil the assignment requirements:
- Script 1: Variables, `uname`, `echo`, command substitution
- Script 2: `if-else`, `case` statement, `dpkg`/`rpm` queries
- Script 3: `for` loop, `du`, `ls`, `stat` for disk/permission audit
- Script 4: `while IFS= read -r` loop, `grep`, counter variables
- Script 5: `read` for user input, `>` and `>>` file writing

**Advanced Scripts** (`scripts/advanced/`) — 5 additional enterprise-grade scripts included as bonus work demonstrating real-world Apache automation.

All scripts are fully commented, runnable on Ubuntu/Debian, and designed to work with the included `sample_data/` for demonstration.

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE).

> Apache HTTPD itself uses the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). The scripts and documentation in this repository are original work under MIT.

---

## 👤 Author

**Krish Goyal**
University Capstone Project — Open Source Software Audit
