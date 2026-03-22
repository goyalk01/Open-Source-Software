#!/bin/bash
# =============================================================================
# Script Name  : apache_health_monitor.sh
# Description  : Monitors the health status of Apache HTTP Server
# Purpose      : Check if Apache is installed, running, listening on ports,
#                and responding to HTTP requests. Generates a formatted report.
# Usage        : sudo bash apache_health_monitor.sh
# Author       : Open Source Audit Project
# =============================================================================

# ----- Color Definitions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Color (reset)

# ----- Counter Variables -----
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=0

# =============================================================================
# Function: print_header
# Displays a formatted header banner for the health report
# =============================================================================
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}Apache HTTPD Health Monitor${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   $(date '+%Y-%m-%d %H:%M:%S')                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# Function: check_result
# Prints a formatted PASS/WARN/FAIL result and updates counters
# Arguments:
#   $1 - Status: "PASS", "WARN", or "FAIL"
#   $2 - Description of the check
#   $3 - Additional detail (optional)
# =============================================================================
check_result() {
    local status="$1"
    local description="$2"
    local detail="$3"
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

    # Print additional detail if provided
    if [ -n "$detail" ]; then
        echo -e "         ${CYAN}→${NC} $detail"
    fi
}

# =============================================================================
# Function: check_installation
# Verifies if Apache is installed and finds its binary location
# =============================================================================
check_installation() {
    echo -e "${BOLD}── Installation Check ──${NC}"

    # Check if apache2 or httpd binary exists using 'which'
    if which apache2 > /dev/null 2>&1; then
        APACHE_BIN=$(which apache2)
        check_result "PASS" "Apache2 binary found" "$APACHE_BIN"
    elif which httpd > /dev/null 2>&1; then
        APACHE_BIN=$(which httpd)
        check_result "PASS" "HTTPD binary found" "$APACHE_BIN"
    else
        check_result "FAIL" "Apache binary not found" "Install with: sudo apt install apache2"
        return 1
    fi

    # Get Apache version string
    APACHE_VERSION=$($APACHE_BIN -v 2>/dev/null | head -n 1)
    if [ -n "$APACHE_VERSION" ]; then
        check_result "PASS" "Version detected" "$APACHE_VERSION"
    else
        check_result "WARN" "Could not determine Apache version"
    fi

    # Check where Apache files are located using 'whereis'
    APACHE_LOCATIONS=$(whereis apache2 2>/dev/null || whereis httpd 2>/dev/null)
    if [ -n "$APACHE_LOCATIONS" ]; then
        check_result "PASS" "Apache file locations found" "$APACHE_LOCATIONS"
    fi

    echo ""
}

# =============================================================================
# Function: check_service_status
# Checks if the Apache service is active and enabled via systemctl
# =============================================================================
check_service_status() {
    echo -e "${BOLD}── Service Status ──${NC}"

    # Determine service name (apache2 on Debian/Ubuntu, httpd on RHEL/CentOS)
    local service_name=""
    if systemctl list-units --type=service 2>/dev/null | grep -q "apache2"; then
        service_name="apache2"
    elif systemctl list-units --type=service 2>/dev/null | grep -q "httpd"; then
        service_name="httpd"
    else
        check_result "FAIL" "Apache service not found in systemctl"
        echo ""
        return 1
    fi

    # Check if service is currently running (active)
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        check_result "PASS" "Service '$service_name' is active (running)"
    else
        check_result "FAIL" "Service '$service_name' is not running" \
            "Start with: sudo systemctl start $service_name"
    fi

    # Check if service is enabled to start on boot
    if systemctl is-enabled --quiet "$service_name" 2>/dev/null; then
        check_result "PASS" "Service '$service_name' is enabled (starts on boot)"
    else
        check_result "WARN" "Service '$service_name' is not enabled" \
            "Enable with: sudo systemctl enable $service_name"
    fi

    # Show process info using 'ps'
    local process_count
    process_count=$(ps aux 2>/dev/null | grep -c "[a]pache2\|[h]ttpd")
    if [ "$process_count" -gt 0 ]; then
        check_result "PASS" "Apache processes running: $process_count"
    else
        check_result "FAIL" "No Apache processes detected"
    fi

    echo ""
}

# =============================================================================
# Function: check_ports
# Verifies that Apache is listening on expected network ports (80, 443)
# =============================================================================
check_ports() {
    echo -e "${BOLD}── Port Check ──${NC}"

    # Check port 80 (HTTP) using ss (modern) or netstat (legacy)
    if command -v ss > /dev/null 2>&1; then
        if ss -tlnp 2>/dev/null | grep -q ":80 "; then
            check_result "PASS" "Port 80 (HTTP) is open"
        else
            check_result "FAIL" "Port 80 (HTTP) is not listening"
        fi

        if ss -tlnp 2>/dev/null | grep -q ":443 "; then
            check_result "PASS" "Port 443 (HTTPS) is open"
        else
            check_result "WARN" "Port 443 (HTTPS) is not listening" \
                "SSL may not be configured"
        fi
    elif command -v netstat > /dev/null 2>&1; then
        if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
            check_result "PASS" "Port 80 (HTTP) is open"
        else
            check_result "FAIL" "Port 80 (HTTP) is not listening"
        fi

        if netstat -tlnp 2>/dev/null | grep -q ":443 "; then
            check_result "PASS" "Port 443 (HTTPS) is open"
        else
            check_result "WARN" "Port 443 (HTTPS) is not listening"
        fi
    else
        check_result "WARN" "Neither 'ss' nor 'netstat' found — cannot check ports"
    fi

    echo ""
}

# =============================================================================
# Function: check_http_response
# Tests if Apache responds to HTTP requests using curl
# =============================================================================
check_http_response() {
    echo -e "${BOLD}── HTTP Response Check ──${NC}"

    # Verify curl is available
    if ! command -v curl > /dev/null 2>&1; then
        check_result "WARN" "curl not installed — skipping HTTP checks"
        echo ""
        return
    fi

    # Send a HEAD request to localhost and capture the HTTP status code
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost/ 2>/dev/null)

    if [ "$http_code" -eq 200 ] 2>/dev/null; then
        check_result "PASS" "HTTP response: $http_code OK"
    elif [ "$http_code" -eq 403 ] 2>/dev/null; then
        check_result "WARN" "HTTP response: $http_code Forbidden" \
            "Default page may be restricted"
    elif [ -n "$http_code" ] && [ "$http_code" != "000" ]; then
        check_result "WARN" "HTTP response: $http_code"
    else
        check_result "FAIL" "No HTTP response from localhost" \
            "Apache may not be running"
    fi

    # Check response time
    local response_time
    response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 5 http://localhost/ 2>/dev/null)
    if [ -n "$response_time" ]; then
        check_result "PASS" "Response time: ${response_time}s"
    fi

    echo ""
}

# =============================================================================
# Function: check_config_files
# Verifies the existence and readability of key configuration files
# =============================================================================
check_config_files() {
    echo -e "${BOLD}── Configuration Files ──${NC}"

    # List of important Apache config paths to check
    local config_paths=(
        "/etc/apache2/apache2.conf"
        "/etc/apache2/ports.conf"
        "/etc/apache2/envvars"
        "/etc/httpd/conf/httpd.conf"
    )

    local found=0
    for config in "${config_paths[@]}"; do
        if [ -f "$config" ]; then
            # Check if the file is readable
            if [ -r "$config" ]; then
                local file_size
                file_size=$(stat -c %s "$config" 2>/dev/null || stat -f %z "$config" 2>/dev/null)
                check_result "PASS" "Config found: $config (${file_size} bytes)"
            else
                check_result "WARN" "Config exists but not readable: $config"
            fi
            found=1
        fi
    done

    # If no config files found at all
    if [ "$found" -eq 0 ]; then
        check_result "FAIL" "No Apache configuration files found"
    fi

    # Check sites-enabled directory (Debian/Ubuntu style)
    if [ -d "/etc/apache2/sites-enabled" ]; then
        local site_count
        site_count=$(ls -1 /etc/apache2/sites-enabled/ 2>/dev/null | wc -l)
        check_result "PASS" "Sites enabled: $site_count"
    fi

    # Check modules enabled
    if [ -d "/etc/apache2/mods-enabled" ]; then
        local mod_count
        mod_count=$(ls -1 /etc/apache2/mods-enabled/ 2>/dev/null | wc -l)
        check_result "PASS" "Modules enabled: $mod_count"
    fi

    echo ""
}

# =============================================================================
# Function: check_log_files
# Verifies that log files exist and shows recent error counts
# =============================================================================
check_log_files() {
    echo -e "${BOLD}── Log Files ──${NC}"

    # Common log directories to check
    local log_dirs=(
        "/var/log/apache2"
        "/var/log/httpd"
    )

    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            check_result "PASS" "Log directory found: $log_dir"

            # Check access log
            if [ -f "$log_dir/access.log" ]; then
                local access_lines
                access_lines=$(wc -l < "$log_dir/access.log" 2>/dev/null)
                check_result "PASS" "Access log: $access_lines entries"
            fi

            # Check error log and count recent errors
            if [ -f "$log_dir/error.log" ]; then
                local error_lines
                error_lines=$(wc -l < "$log_dir/error.log" 2>/dev/null)
                local recent_errors
                recent_errors=$(tail -100 "$log_dir/error.log" 2>/dev/null | grep -c "error")
                check_result "PASS" "Error log: $error_lines entries ($recent_errors recent errors)"
            fi
        fi
    done

    echo ""
}

# =============================================================================
# Function: print_summary
# Displays the final summary with total pass/warn/fail counts
# =============================================================================
print_summary() {
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  HEALTH CHECK SUMMARY${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Total Checks:  ${BOLD}$TOTAL_CHECKS${NC}"
    echo -e "  Passed:        ${GREEN}$PASS_COUNT${NC}"
    echo -e "  Warnings:      ${YELLOW}$WARN_COUNT${NC}"
    echo -e "  Failed:        ${RED}$FAIL_COUNT${NC}"
    echo ""

    # Overall status based on fail count
    if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
        echo -e "  Overall: ${GREEN}${BOLD}HEALTHY ✓${NC}"
    elif [ "$FAIL_COUNT" -eq 0 ]; then
        echo -e "  Overall: ${YELLOW}${BOLD}NEEDS ATTENTION ⚠${NC}"
    else
        echo -e "  Overall: ${RED}${BOLD}UNHEALTHY ✗${NC}"
    fi

    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
}

# =============================================================================
# MAIN EXECUTION
# Runs all health checks in sequence and displays the report
# =============================================================================
main() {
    print_header
    check_installation
    check_service_status
    check_ports
    check_http_response
    check_config_files
    check_log_files
    print_summary
}

# Entry point — call main function
main
