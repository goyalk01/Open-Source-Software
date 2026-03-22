#!/bin/bash
# =============================================================================
# Script  : 01 - System Identity Report
# Concepts: Variables, uname, echo, whoami, hostname, command substitution
# Purpose : Collect and display system + Apache identity information
# Usage   : bash 01_system_identity.sh
# =============================================================================

# ----- System variables using command substitution $() -----

USER_NAME=$(whoami)
HOST_NAME=$(hostname)
OS_INFO=$(uname -o 2>/dev/null || uname -s)
KERNEL_VERSION=$(uname -r)
ARCHITECTURE=$(uname -m)
DATE=$(date)
UPTIME_INFO=$(uptime -p 2>/dev/null || uptime)
SHELL_NAME=$(basename "$SHELL")

# ----- Distro name from /etc/os-release -----

if [ -f /etc/os-release ]; then
    DISTRO=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
else
    DISTRO="Unknown"
fi

# ----- Apache-specific variables -----

if command -v apache2 >/dev/null 2>&1; then
    APACHE_BIN=$(which apache2)
    APACHE_VERSION=$(apache2 -v 2>/dev/null | head -1)
    APACHE_STATUS="Installed"
elif command -v httpd >/dev/null 2>&1; then
    APACHE_BIN=$(which httpd)
    APACHE_VERSION=$(httpd -v 2>/dev/null | head -1)
    APACHE_STATUS="Installed"
else
    APACHE_BIN="Not found"
    APACHE_VERSION="Not installed"
    APACHE_STATUS="Not Installed"
fi

# ----- Network identity -----

IP_ADDRESS=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS="N/A"
fi

# ----- Display the report using echo -----

echo "=============================================="
echo "       SYSTEM IDENTITY REPORT"
echo "=============================================="
echo ""
echo "--- System Information ---"
echo "  Username     : $USER_NAME"
echo "  Hostname     : $HOST_NAME"
echo "  Distro       : $DISTRO"
echo "  OS           : $OS_INFO"
echo "  Kernel       : $KERNEL_VERSION"
echo "  Architecture : $ARCHITECTURE"
echo "  Shell        : $SHELL_NAME"
echo "  Uptime       : $UPTIME_INFO"
echo "  Date         : $DATE"
echo "  IP Address   : $IP_ADDRESS"
echo ""
echo "--- Apache HTTPD Information ---"
echo "  Status       : $APACHE_STATUS"
echo "  Binary Path  : $APACHE_BIN"
echo "  Version      : $APACHE_VERSION"
echo ""
echo "--- License ---"
echo "  Apache HTTPD : Apache License 2.0"
echo "  Linux Kernel : GNU GPL v2"
echo ""
echo "=============================================="
echo "  Report generated on: $DATE"
echo "=============================================="
