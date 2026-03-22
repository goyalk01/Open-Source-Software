# 📸 Screenshots Guide

## How to Take Screenshots

For each of the 5 required scripts, take a screenshot showing:
1. The command you typed
2. The output it produced

### Steps:
```bash
# Open terminal (WSL or Ubuntu)
cd linuxopensource

# Clear screen before running
clear

# Run each script and take screenshot of the output:

# Screenshot 1:
bash scripts/required/01_system_identity.sh

# Screenshot 2:
bash scripts/required/02_package_inspector.sh

# Screenshot 3:
sudo bash scripts/required/03_disk_permission_audit.sh

# Screenshot 4:
bash scripts/required/04_log_analyzer.sh sample_data/sample_error.log

# Screenshot 5:
bash scripts/required/05_manifest_generator.sh
```

### Tips:
- Use `clear` before each script for a clean screenshot
- For Script 2 (Package Inspector): type `5` when prompted to show all options
- For Script 5 (Manifest): enter your real name and roll number
- Save screenshots as: `01_system_identity.png`, `02_package_inspector.png`, etc.
- On WSL: use Windows Snipping Tool (Win + Shift + S)

### Naming Convention:
```
screenshots/
├── 01_system_identity.png
├── 02_package_inspector.png
├── 03_disk_permission_audit.png
├── 04_log_analyzer.png
└── 05_manifest_generator.png
```
