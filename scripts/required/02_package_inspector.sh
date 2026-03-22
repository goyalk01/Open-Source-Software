#!/bin/bash
# =============================================================================
# Script  : 02 - Package Inspector
# Concepts: if-else (Debian vs RHEL), case statement, dpkg/rpm, functions
# Purpose : Inspect Apache and other packages using system package manager
# Usage   : bash 02_package_inspector.sh
# =============================================================================

# ----- Detect package manager using if-else -----

if command -v dpkg >/dev/null 2>&1; then
    PKG_MANAGER="dpkg"
    DEFAULT_PKG="apache2"
    echo "[INFO] Detected Debian/Ubuntu system (dpkg)"
elif command -v rpm >/dev/null 2>&1; then
    PKG_MANAGER="rpm"
    DEFAULT_PKG="httpd"
    echo "[INFO] Detected RHEL/CentOS system (rpm)"
else
    echo "[ERROR] No supported package manager found (need dpkg or rpm)."
    exit 1
fi

echo ""

# ----- Get package name from argument or use default -----

PACKAGE=${1:-apache2}

# ----- Case statement: describe common packages -----

echo ""
echo "--- Package Description ---"

case $PACKAGE in
    apache2|httpd)
        echo "  Apache: Open-source web server, powers ~30% of websites worldwide."
        echo "  License: Apache License 2.0 (permissive)"
        ;;
    mysql-server|mariadb-server)
        echo "  MySQL/MariaDB: Relational database management system."
        echo "  License: GPL v2"
        ;;
    nginx)
        echo "  Nginx: High-performance web server and reverse proxy."
        echo "  License: BSD 2-Clause"
        ;;
    python3)
        echo "  Python: General-purpose programming language."
        echo "  License: PSF License"
        ;;
    git)
        echo "  Git: Distributed version control system created by Linus Torvalds."
        echo "  License: GPL v2"
        ;;
    *)
        echo "  $PACKAGE: No description available for this package."
        ;;
esac

echo ""

# ----- Check if package is installed using if-else -----

echo "--- Installation Status ---"

if [ "$PKG_MANAGER" = "dpkg" ]; then
    if dpkg -l | grep -qi "$PACKAGE"; then
        echo "  $PACKAGE is: INSTALLED"
        INSTALLED=true
    else
        echo "  $PACKAGE is: NOT INSTALLED"
        echo "  Install with: sudo apt install $PACKAGE"
        INSTALLED=false
    fi
else
    if rpm -q "$PACKAGE" >/dev/null 2>&1; then
        echo "  $PACKAGE is: INSTALLED"
        INSTALLED=true
    else
        echo "  $PACKAGE is: NOT INSTALLED"
        echo "  Install with: sudo yum install $PACKAGE"
        INSTALLED=false
    fi
fi

echo ""

# ----- Show details if installed -----

if [ "$INSTALLED" = true ]; then
    echo "--- Package Details ---"

    if [ "$PKG_MANAGER" = "dpkg" ]; then
        dpkg -s "$PACKAGE" 2>/dev/null | grep -E "^(Package|Version|Maintainer|Installed-Size|Description):"
    else
        rpm -qi "$PACKAGE" 2>/dev/null | grep -E "^(Name|Version|Release|Size|Summary)"
    fi

    echo ""
    echo "--- Key Files (first 10) ---"

    if [ "$PKG_MANAGER" = "dpkg" ]; then
        dpkg -L "$PACKAGE" 2>/dev/null | head -10
    else
        rpm -ql "$PACKAGE" 2>/dev/null | head -10
    fi

    echo ""
    echo "--- Dependencies ---"

    if [ "$PKG_MANAGER" = "dpkg" ]; then
        dpkg -s "$PACKAGE" 2>/dev/null | grep "^Depends:" | sed 's/Depends: //' | tr ',' '\n' | while read -r dep; do
            echo "   - $(echo "$dep" | xargs)"
        done
    else
        rpm -qR "$PACKAGE" 2>/dev/null | head -10
    fi
fi

echo ""
echo "=============================================="
echo "  Inspection complete."
echo "=============================================="
