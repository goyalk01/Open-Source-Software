#!/bin/bash
# =============================================================================
# Script  : 03 - Disk & Permission Auditor
# Concepts: for loop, arrays, du, ls -ld, stat, if-else
# Purpose : Audit disk usage and permissions of Apache-related directories
# Usage   : bash 03_disk_permission_audit.sh
# =============================================================================

echo "=============================================="
echo "       DISK & PERMISSION AUDITOR"
echo "       Apache HTTPD Directories"
echo "=============================================="
echo ""

# ----- Array of directories to audit -----

DIRS=(
    "/etc/apache2"
    "/var/log/apache2"
    "/var/www"
    "/usr/sbin"
    "/usr/lib/apache2"
)

# ----- Counter variables -----
TOTAL=0
FOUND=0
MISSING=0

# =============================================================================
# Section 1: Disk Usage — for loop with du
# =============================================================================

echo "--- Disk Usage Report ---"
echo ""
printf "  %-30s %s\n" "Directory" "Size"
echo "  ------------------------------------------"

for DIR in "${DIRS[@]}"; do
    TOTAL=$((TOTAL + 1))

    if [ -d "$DIR" ]; then
        # du -sh gives human-readable size summary
        SIZE=$(du -sh "$DIR" 2>/dev/null | awk '{print $1}')
        printf "  %-30s %s\n" "$DIR" "$SIZE"
        FOUND=$((FOUND + 1))
    else
        printf "  %-30s %s\n" "$DIR" "[NOT FOUND]"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "  Found: $FOUND / $TOTAL | Missing: $MISSING"
echo ""

# =============================================================================
# Section 2: Permissions — for loop with ls -ld and stat
# =============================================================================

echo "--- Permission Report ---"
echo ""
printf "  %-30s %-12s %-15s %s\n" "Directory" "Permissions" "Owner:Group" "Octal"
echo "  -----------------------------------------------------------------"

for DIR in "${DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        # ls -ld shows directory info (not contents)
        PERMS=$(ls -ld "$DIR" 2>/dev/null | awk '{print $1}')
        OWNER=$(ls -ld "$DIR" 2>/dev/null | awk '{print $3":"$4}')
        # stat -c %a gives octal format (e.g., 755)
        OCTAL=$(stat -c "%a" "$DIR" 2>/dev/null)

        printf "  %-30s %-12s %-15s %s\n" "$DIR" "$PERMS" "$OWNER" "$OCTAL"
    fi
done

echo ""

# =============================================================================
# Section 3: Apache config directory — detailed listing
# =============================================================================

if [ -d "/etc/apache2" ]; then
    echo "--- Apache Config Directory (/etc/apache2) ---"
    echo ""
    ls -ld /etc/apache2
    echo ""
    echo "  Contents:"
    for ITEM in /etc/apache2/*; do
        if [ -e "$ITEM" ]; then
            NAME=$(basename "$ITEM")
            if [ -d "$ITEM" ]; then
                TYPE="[DIR] "
            else
                TYPE="[FILE]"
            fi
            ITEM_SIZE=$(du -h "$ITEM" 2>/dev/null | tail -1 | awk '{print $1}')
            ITEM_PERMS=$(stat -c "%a" "$ITEM" 2>/dev/null)
            printf "  %s %-25s Size: %-8s Perms: %s\n" "$TYPE" "$NAME" "$ITEM_SIZE" "$ITEM_PERMS"
        fi
    done
    echo ""
else
    echo "  [WARN] /etc/apache2 not found. Is Apache installed?"
    echo "  Install with: sudo apt install apache2"
    echo ""
fi

# =============================================================================
# Section 4: Security check — world-writable directories
# =============================================================================

echo "--- Security Checks ---"
echo ""

for DIR in "${DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        OCTAL=$(stat -c "%a" "$DIR" 2>/dev/null)
        # Last digit of octal: 2,3,6,7 means world-writable
        WORLD_BIT="${OCTAL: -1}"
        if [ "$WORLD_BIT" = "2" ] || [ "$WORLD_BIT" = "3" ] || [ "$WORLD_BIT" = "6" ] || [ "$WORLD_BIT" = "7" ]; then
            echo "  [WARN] $DIR is world-writable ($OCTAL) — security risk!"
        else
            echo "  [OK]   $DIR permissions are safe ($OCTAL)"
        fi
    fi
done

echo ""
echo "=============================================="
echo "  Audit complete."
echo "=============================================="
