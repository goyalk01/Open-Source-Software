#!/bin/bash
# =============================================================================
# Script Name  : apache_security_audit.sh
# Description  : Audits Apache HTTP Server security configuration
# Purpose      : Check for common security misconfigurations and vulnerabilities.
#                Produces a PASS/WARN/FAIL report with recommendations.
# Usage        : sudo bash apache_security_audit.sh [config_file]
# Author       : Open Source Audit Project
# =============================================================================

# ----- Color Definitions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ----- Counters -----
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=0

# ----- Determine Config File -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Config file: argument > system default > sample
if [ -n "$1" ] && [ -f "$1" ]; then
    CONFIG_FILE="$1"
    AUDIT_MODE="file"
elif [ -f "/etc/apache2/apache2.conf" ]; then
    CONFIG_FILE="/etc/apache2/apache2.conf"
    AUDIT_MODE="live"
elif [ -f "/etc/httpd/conf/httpd.conf" ]; then
    CONFIG_FILE="/etc/httpd/conf/httpd.conf"
    AUDIT_MODE="live"
elif [ -f "$PROJECT_DIR/sample_data/sample_apache2.conf" ]; then
    CONFIG_FILE="$PROJECT_DIR/sample_data/sample_apache2.conf"
    AUDIT_MODE="sample"
else
    echo -e "${RED}Error: No Apache configuration file found.${NC}"
    echo "Usage: $0 [config_file_path]"
    exit 1
fi

# =============================================================================
# Function: print_header
# =============================================================================
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}Apache Security Audit Report${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   $(date '+%Y-%m-%d %H:%M:%S')                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Config File:${NC}  $CONFIG_FILE"
    echo -e "  ${BOLD}Audit Mode:${NC}   $AUDIT_MODE"
    echo ""
}

# =============================================================================
# Function: audit_result
# Prints formatted audit result and updates counters
# Arguments:
#   $1 - Status (PASS/WARN/FAIL)
#   $2 - Check description
#   $3 - Recommendation (optional, shown for WARN/FAIL)
# =============================================================================
audit_result() {
    local status="$1"
    local description="$2"
    local recommendation="$3"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    case "$status" in
        PASS)
            echo -e "  [${GREEN}PASS${NC}] $description"
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        WARN)
            echo -e "  [${YELLOW}WARN${NC}] $description"
            WARN_COUNT=$((WARN_COUNT + 1))
            ;;
        FAIL)
            echo -e "  [${RED}FAIL${NC}] $description"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
    esac

    # Show recommendation for non-passing checks
    if [ -n "$recommendation" ] && [ "$status" != "PASS" ]; then
        echo -e "         ${CYAN}→ Fix:${NC} $recommendation"
    fi
}

# =============================================================================
# Function: check_server_tokens
# ServerTokens controls how much information Apache reveals about itself
# in HTTP response headers and error pages.
# Recommended: "Prod" (reveals only "Apache", not version/OS details)
# =============================================================================
check_server_tokens() {
    echo -e "${BOLD}── Server Information Disclosure ──${NC}"

    # Search for ServerTokens directive in config
    local tokens
    tokens=$(grep -i "^[[:space:]]*ServerTokens" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')

    if [ -z "$tokens" ]; then
        audit_result "WARN" "ServerTokens not set (defaults to 'Full')" \
            "Add 'ServerTokens Prod' to hide version info"
    elif echo "$tokens" | grep -qi "prod"; then
        audit_result "PASS" "ServerTokens set to 'Prod' — minimal info exposed"
    elif echo "$tokens" | grep -qi "full\|os\|major\|minor"; then
        audit_result "FAIL" "ServerTokens set to '$tokens' — reveals server details" \
            "Change to 'ServerTokens Prod'"
    else
        audit_result "PASS" "ServerTokens set to '$tokens'"
    fi
}

# =============================================================================
# Function: check_server_signature
# ServerSignature controls whether Apache adds a footer with server info
# to error pages and directory listings.
# Recommended: "Off"
# =============================================================================
check_server_signature() {
    local signature
    signature=$(grep -i "^[[:space:]]*ServerSignature" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')

    if [ -z "$signature" ]; then
        audit_result "WARN" "ServerSignature not set (defaults to 'On')" \
            "Add 'ServerSignature Off'"
    elif echo "$signature" | grep -qi "off"; then
        audit_result "PASS" "ServerSignature is Off — no info in error pages"
    else
        audit_result "FAIL" "ServerSignature is '$signature'" \
            "Set 'ServerSignature Off'"
    fi
    echo ""
}

# =============================================================================
# Function: check_directory_listing
# Directory listing (Options Indexes) lets visitors see all files in a
# directory when there's no index file. This is a security risk.
# =============================================================================
check_directory_listing() {
    echo -e "${BOLD}── Directory Security ──${NC}"

    # Look for 'Options Indexes' or 'Options +Indexes' (listing enabled)
    local indexes_found
    indexes_found=$(grep -n "Options.*Indexes" "$CONFIG_FILE" 2>/dev/null | grep -v "^[[:space:]]*#" | grep -v "\-Indexes")

    if [ -n "$indexes_found" ]; then
        # Check if it's explicitly disabled with -Indexes
        local disabled
        disabled=$(grep -c "\-Indexes" "$CONFIG_FILE" 2>/dev/null)
        if [ "$disabled" -gt 0 ]; then
            audit_result "PASS" "Directory listing explicitly disabled (-Indexes)"
        else
            audit_result "FAIL" "Directory listing may be enabled (Options Indexes found)" \
                "Use 'Options -Indexes' to disable directory browsing"
        fi
    else
        # Check if -Indexes is explicitly set
        if grep -q "\-Indexes" "$CONFIG_FILE" 2>/dev/null; then
            audit_result "PASS" "Directory listing disabled (-Indexes)"
        else
            audit_result "WARN" "Directory listing configuration not found" \
                "Explicitly set 'Options -Indexes' in Directory blocks"
        fi
    fi
}

# =============================================================================
# Function: check_root_directory
# The root directory (/) should deny all access by default.
# Individual directories then selectively grant access.
# =============================================================================
check_root_directory() {
    # Check if root directory has restrictive settings
    if grep -A3 "<Directory />" "$CONFIG_FILE" 2>/dev/null | grep -qi "deny\|denied\|none"; then
        audit_result "PASS" "Root directory (/) is restricted"
    elif grep -A3 "<Directory />" "$CONFIG_FILE" 2>/dev/null | grep -qi "granted\|allow"; then
        audit_result "FAIL" "Root directory (/) allows access" \
            "Set 'Require all denied' for <Directory />"
    else
        audit_result "WARN" "Root directory access policy not clearly defined"
    fi
    echo ""
}

# =============================================================================
# Function: check_ssl_config
# Checks if SSL/TLS is configured for HTTPS support
# =============================================================================
check_ssl_config() {
    echo -e "${BOLD}── SSL/TLS Configuration ──${NC}"

    # Check if SSL module is loaded
    if grep -qi "mod_ssl\|SSLEngine" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "SSL module reference found in configuration"
    else
        audit_result "WARN" "No SSL configuration detected" \
            "Enable SSL: sudo a2enmod ssl"
    fi

    # Check for SSLEngine On directive
    if grep -qi "SSLEngine[[:space:]]*on" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "SSLEngine is enabled"
    else
        audit_result "WARN" "SSLEngine not enabled in this config"
    fi

    # Check for HTTPS virtual host (port 443)
    if grep -qi ":443" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "HTTPS virtual host (port 443) configured"
    else
        audit_result "WARN" "No port 443 virtual host found" \
            "Configure HTTPS for secure communication"
    fi

    # If running live, check if SSL module is actually loaded
    if [ "$AUDIT_MODE" = "live" ]; then
        if apache2ctl -M 2>/dev/null | grep -qi "ssl_module"; then
            audit_result "PASS" "SSL module is loaded (live check)"
        else
            audit_result "FAIL" "SSL module is NOT loaded" \
                "Run: sudo a2enmod ssl && sudo systemctl restart apache2"
        fi
    fi

    echo ""
}

# =============================================================================
# Function: check_security_headers
# Modern web security headers protect against common attacks like
# clickjacking, XSS, and MIME-type confusion.
# =============================================================================
check_security_headers() {
    echo -e "${BOLD}── Security Headers ──${NC}"

    # Check for X-Content-Type-Options (prevents MIME sniffing)
    if grep -qi "X-Content-Type-Options" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "X-Content-Type-Options header is set"
    else
        audit_result "WARN" "X-Content-Type-Options header missing" \
            "Add: Header always set X-Content-Type-Options \"nosniff\""
    fi

    # Check for X-Frame-Options (prevents clickjacking)
    if grep -qi "X-Frame-Options" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "X-Frame-Options header is set"
    else
        audit_result "WARN" "X-Frame-Options header missing" \
            "Add: Header always set X-Frame-Options \"SAMEORIGIN\""
    fi

    # Check for X-XSS-Protection
    if grep -qi "X-XSS-Protection" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "X-XSS-Protection header is set"
    else
        audit_result "WARN" "X-XSS-Protection header missing" \
            "Add: Header always set X-XSS-Protection \"1; mode=block\""
    fi

    # Check for Content-Security-Policy
    if grep -qi "Content-Security-Policy" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "Content-Security-Policy header is set"
    else
        audit_result "WARN" "Content-Security-Policy header missing" \
            "Consider adding a CSP header to restrict resource loading"
    fi

    echo ""
}

# =============================================================================
# Function: check_file_permissions
# Verifies critical file/directory permissions (live mode only)
# =============================================================================
check_file_permissions() {
    # Only run permission checks in live mode
    if [ "$AUDIT_MODE" != "live" ]; then
        return
    fi

    echo -e "${BOLD}── File Permissions ──${NC}"

    # Check config file permissions (should not be world-writable)
    local config_perms
    config_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$config_perms" ]; then
        # Check if world-writable (last digit includes write = 2, 3, 6, 7)
        local world_perm="${config_perms: -1}"
        if [ "$world_perm" -ge 2 ] 2>/dev/null; then
            audit_result "FAIL" "Config file is world-writable ($config_perms)" \
                "Run: sudo chmod 644 $CONFIG_FILE"
        else
            audit_result "PASS" "Config file permissions: $config_perms"
        fi
    fi

    # Check log directory permissions
    local log_dirs=("/var/log/apache2" "/var/log/httpd")
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            local log_perms
            log_perms=$(stat -c "%a" "$log_dir" 2>/dev/null)
            if [ -n "$log_perms" ]; then
                audit_result "PASS" "Log directory permissions: $log_perms ($log_dir)"
            fi
        fi
    done

    # Check document root permissions
    if [ -d "/var/www/html" ]; then
        local www_perms
        www_perms=$(stat -c "%a" "/var/www/html" 2>/dev/null)
        local www_owner
        www_owner=$(stat -c "%U:%G" "/var/www/html" 2>/dev/null)
        audit_result "PASS" "Document root: $www_perms owned by $www_owner"
    fi

    echo ""
}

# =============================================================================
# Function: check_sensitive_files
# Checks for common files that should not be publicly accessible
# =============================================================================
check_sensitive_files() {
    if [ "$AUDIT_MODE" != "live" ]; then
        return
    fi

    echo -e "${BOLD}── Sensitive File Exposure ──${NC}"

    local doc_root="/var/www/html"
    local sensitive_files=(".htaccess" ".htpasswd" ".git" ".env" "wp-config.php" "config.php")
    local found=0

    for file in "${sensitive_files[@]}"; do
        if [ -e "$doc_root/$file" ]; then
            audit_result "WARN" "Sensitive file found: $doc_root/$file" \
                "Restrict access or remove from document root"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        audit_result "PASS" "No common sensitive files exposed in document root"
    fi

    echo ""
}

# =============================================================================
# Function: check_default_page
# Checks if the default Apache welcome page is still present
# =============================================================================
check_default_page() {
    echo -e "${BOLD}── Default Configuration ──${NC}"

    # Check for default Apache page
    if [ "$AUDIT_MODE" = "live" ]; then
        if [ -f "/var/www/html/index.html" ]; then
            if grep -qi "apache.*default\|it works\|apache2.*ubuntu" "/var/www/html/index.html" 2>/dev/null; then
                audit_result "WARN" "Default Apache welcome page is still present" \
                    "Replace with your own content or remove"
            else
                audit_result "PASS" "Default Apache page has been customized"
            fi
        fi
    fi

    # Check for ServerName configuration
    if grep -qi "^[[:space:]]*ServerName" "$CONFIG_FILE" 2>/dev/null; then
        audit_result "PASS" "ServerName is configured"
    else
        audit_result "WARN" "ServerName not set" \
            "Add 'ServerName your-domain.com' to prevent warnings"
    fi

    echo ""
}

# =============================================================================
# Function: check_modules
# Lists potentially risky enabled modules (live mode only)
# =============================================================================
check_modules() {
    if [ "$AUDIT_MODE" != "live" ]; then
        return
    fi

    echo -e "${BOLD}── Module Security ──${NC}"

    # Get list of enabled modules
    local modules
    modules=$(apache2ctl -M 2>/dev/null)

    if [ -z "$modules" ]; then
        audit_result "WARN" "Could not retrieve module list"
        echo ""
        return
    fi

    # Check for potentially risky modules
    local risky_modules=("cgi_module" "status_module" "info_module" "userdir_module")
    local risky_descriptions=(
        "CGI execution enabled — ensure scripts are secure"
        "Server status page may expose info — restrict access"
        "Server info page exposes configuration — restrict access"
        "User directory listing enabled — may expose user dirs"
    )

    for i in "${!risky_modules[@]}"; do
        if echo "$modules" | grep -qi "${risky_modules[$i]}"; then
            audit_result "WARN" "${risky_descriptions[$i]}"
        fi
    done

    # Count total modules
    local mod_count
    mod_count=$(echo "$modules" | grep -c "_module")
    audit_result "PASS" "Total modules loaded: $mod_count"

    echo ""
}

# =============================================================================
# Function: print_summary
# Displays the final audit summary with a security score
# =============================================================================
print_summary() {
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  SECURITY AUDIT SUMMARY${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Total Checks:  ${BOLD}$TOTAL_CHECKS${NC}"
    echo -e "  Passed:        ${GREEN}$PASS_COUNT${NC}"
    echo -e "  Warnings:      ${YELLOW}$WARN_COUNT${NC}"
    echo -e "  Failed:        ${RED}$FAIL_COUNT${NC}"

    # Calculate security score as a percentage
    local score=0
    if [ "$TOTAL_CHECKS" -gt 0 ]; then
        score=$(( (PASS_COUNT * 100) / TOTAL_CHECKS ))
    fi

    echo ""
    echo -e "  Security Score: ${BOLD}${score}%${NC}"

    # Grade based on score
    if [ "$score" -ge 90 ]; then
        echo -e "  Grade:          ${GREEN}${BOLD}A — Excellent${NC}"
    elif [ "$score" -ge 75 ]; then
        echo -e "  Grade:          ${GREEN}B — Good${NC}"
    elif [ "$score" -ge 60 ]; then
        echo -e "  Grade:          ${YELLOW}C — Needs Improvement${NC}"
    elif [ "$score" -ge 40 ]; then
        echo -e "  Grade:          ${YELLOW}D — Poor${NC}"
    else
        echo -e "  Grade:          ${RED}F — Critical${NC}"
    fi

    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
}

# =============================================================================
# MAIN EXECUTION
# Runs all security audit checks
# =============================================================================
main() {
    print_header
    check_server_tokens
    check_server_signature
    check_directory_listing
    check_root_directory
    check_ssl_config
    check_security_headers
    check_file_permissions
    check_sensitive_files
    check_default_page
    check_modules
    print_summary
}

# Entry point
main
