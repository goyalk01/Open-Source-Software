#!/bin/bash
# =============================================================================
# Script Name  : apache_log_analyzer.sh
# Description  : Analyzes Apache access and error logs to extract insights
# Purpose      : Parse log files to show traffic patterns, top visitors,
#                status code distribution, most requested pages, and errors.
# Usage        : bash apache_log_analyzer.sh [access_log] [error_log]
#                bash apache_log_analyzer.sh   (uses defaults or sample data)
# Author       : Open Source Audit Project
# =============================================================================

# ----- Color Definitions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# Determine Log File Paths
# Priority: command-line args > default system paths > sample data
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Access log: use argument, or try system default, or fall back to sample
if [ -n "$1" ] && [ -f "$1" ]; then
    ACCESS_LOG="$1"
elif [ -f "/var/log/apache2/access.log" ]; then
    ACCESS_LOG="/var/log/apache2/access.log"
elif [ -f "/var/log/httpd/access_log" ]; then
    ACCESS_LOG="/var/log/httpd/access_log"
elif [ -f "$PROJECT_DIR/sample_data/sample_access.log" ]; then
    ACCESS_LOG="$PROJECT_DIR/sample_data/sample_access.log"
else
    echo -e "${RED}Error: No access log found.${NC}"
    echo "Usage: $0 [access_log_path] [error_log_path]"
    exit 1
fi

# Error log: use argument, or try system default, or fall back to sample
if [ -n "$2" ] && [ -f "$2" ]; then
    ERROR_LOG="$2"
elif [ -f "/var/log/apache2/error.log" ]; then
    ERROR_LOG="/var/log/apache2/error.log"
elif [ -f "/var/log/httpd/error_log" ]; then
    ERROR_LOG="/var/log/httpd/error_log"
elif [ -f "$PROJECT_DIR/sample_data/sample_error.log" ]; then
    ERROR_LOG="$PROJECT_DIR/sample_data/sample_error.log"
else
    ERROR_LOG=""
fi

# =============================================================================
# Function: print_header
# Displays the report header with file information
# =============================================================================
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}Apache Log Analyzer Report${NC}                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   $(date '+%Y-%m-%d %H:%M:%S')                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Access Log:${NC} $ACCESS_LOG"
    if [ -n "$ERROR_LOG" ]; then
        echo -e "  ${BOLD}Error Log:${NC}  $ERROR_LOG"
    fi
    echo ""
}

# =============================================================================
# Function: print_section
# Prints a formatted section header
# Arguments: $1 - Section title
# =============================================================================
print_section() {
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}$1${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
}

# =============================================================================
# Function: general_stats
# Shows total requests, unique IPs, date range, and file size
# =============================================================================
general_stats() {
    print_section "📊 General Statistics"

    # Count total number of requests (lines in access log)
    local total_requests
    total_requests=$(wc -l < "$ACCESS_LOG")
    echo -e "  Total Requests:    ${GREEN}$total_requests${NC}"

    # Count unique IP addresses (first field in combined log format)
    local unique_ips
    unique_ips=$(awk '{print $1}' "$ACCESS_LOG" | sort -u | wc -l)
    echo -e "  Unique Visitors:   ${GREEN}$unique_ips${NC}"

    # Get first and last timestamps in the log
    local first_entry
    first_entry=$(head -1 "$ACCESS_LOG" | awk -F'[][]' '{print $2}')
    local last_entry
    last_entry=$(tail -1 "$ACCESS_LOG" | awk -F'[][]' '{print $2}')
    echo -e "  First Entry:       $first_entry"
    echo -e "  Last Entry:        $last_entry"

    # Show file size
    local file_size
    file_size=$(du -h "$ACCESS_LOG" | awk '{print $1}')
    echo -e "  Log File Size:     $file_size"
    echo ""
}

# =============================================================================
# Function: top_ips
# Shows the top 10 IP addresses by request count
# =============================================================================
top_ips() {
    print_section "🔝 Top 10 IP Addresses"

    # Extract IP (field 1), count occurrences, sort descending, show top 10
    echo -e "  ${BOLD}Count   IP Address${NC}"
    awk '{print $1}' "$ACCESS_LOG" \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -10 \
        | while read -r count ip; do
            # Highlight high-traffic IPs in yellow
            if [ "$count" -ge 5 ]; then
                printf "  ${YELLOW}%-7s${NC} %s\n" "$count" "$ip"
            else
                printf "  %-7s %s\n" "$count" "$ip"
            fi
        done
    echo ""
}

# =============================================================================
# Function: status_codes
# Displays HTTP status code distribution with color coding
# =============================================================================
status_codes() {
    print_section "📈 HTTP Status Code Distribution"

    # Extract status code (field 9 in combined log format)
    echo -e "  ${BOLD}Count   Code   Meaning${NC}"
    awk '{print $9}' "$ACCESS_LOG" \
        | sort \
        | uniq -c \
        | sort -rn \
        | while read -r count code; do
            # Map status codes to human-readable meanings
            local meaning=""
            case "$code" in
                200) meaning="OK";;
                301) meaning="Moved Permanently";;
                302) meaning="Found (Redirect)";;
                304) meaning="Not Modified";;
                400) meaning="Bad Request";;
                401) meaning="Unauthorized";;
                403) meaning="Forbidden";;
                404) meaning="Not Found";;
                500) meaning="Internal Server Error";;
                *)   meaning="Other";;
            esac

            # Color code based on status category
            local color=""
            case "${code:0:1}" in
                2) color="${GREEN}";;   # 2xx = Success (green)
                3) color="${CYAN}";;    # 3xx = Redirect (cyan)
                4) color="${YELLOW}";;  # 4xx = Client error (yellow)
                5) color="${RED}";;     # 5xx = Server error (red)
                *) color="${NC}";;
            esac

            printf "  %-7s ${color}%-6s${NC} %s\n" "$count" "$code" "$meaning"
        done
    echo ""
}

# =============================================================================
# Function: top_pages
# Shows the most requested URLs
# =============================================================================
top_pages() {
    print_section "📄 Top 10 Requested Pages"

    # Extract the request URL (field 7 in combined log format)
    echo -e "  ${BOLD}Count   URL${NC}"
    awk '{print $7}' "$ACCESS_LOG" \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -10 \
        | while read -r count url; do
            printf "  %-7s %s\n" "$count" "$url"
        done
    echo ""
}

# =============================================================================
# Function: http_methods
# Shows the distribution of HTTP methods (GET, POST, PUT, DELETE, etc.)
# =============================================================================
http_methods() {
    print_section "🔧 HTTP Methods"

    # Extract method (field 6, removing the leading quote)
    echo -e "  ${BOLD}Count   Method${NC}"
    awk '{print $6}' "$ACCESS_LOG" \
        | sed 's/"//g' \
        | sort \
        | uniq -c \
        | sort -rn \
        | while read -r count method; do
            printf "  %-7s %s\n" "$count" "$method"
        done
    echo ""
}

# =============================================================================
# Function: traffic_by_hour
# Displays traffic distribution across hours of the day
# =============================================================================
traffic_by_hour() {
    print_section "🕐 Traffic by Hour"

    # Extract hour from timestamp [DD/Mon/YYYY:HH:MM:SS]
    echo -e "  ${BOLD}Hour    Requests   Bar${NC}"
    awk -F'[:[]' '{print $2}' "$ACCESS_LOG" \
        | awk -F: '{print $1}' \
        | sort \
        | uniq -c \
        | sort -t' ' -k2 -n \
        | while read -r count hour; do
            # Create a simple bar chart using hash symbols
            local bar=""
            local bar_length=$((count))
            # Cap bar length at 40 for display
            if [ "$bar_length" -gt 40 ]; then
                bar_length=40
            fi
            for ((i = 0; i < bar_length; i++)); do
                bar="${bar}█"
            done
            printf "  %-7s %-10s ${GREEN}%s${NC}\n" "$hour" "$count" "$bar"
        done
    echo ""
}

# =============================================================================
# Function: suspicious_activity
# Identifies potential security threats in access logs
# =============================================================================
suspicious_activity() {
    print_section "🚨 Suspicious Activity Detection"

    local found=0

    # Look for path traversal attempts (../../)
    local traversal
    traversal=$(grep -c "\.\.\/" "$ACCESS_LOG" 2>/dev/null)
    if [ "$traversal" -gt 0 ]; then
        echo -e "  ${RED}⚠ Path traversal attempts: $traversal${NC}"
        found=1
    fi

    # Look for known scanner user agents
    local scanners
    scanners=$(grep -ciE "nikto|sqlmap|nmap|masscan|dirbuster" "$ACCESS_LOG" 2>/dev/null)
    if [ "$scanners" -gt 0 ]; then
        echo -e "  ${RED}⚠ Scanner tool requests: $scanners${NC}"
        found=1
    fi

    # Look for attempts to access admin/sensitive paths
    local admin_attempts
    admin_attempts=$(grep -ciE "/admin|/phpmyadmin|/wp-admin|/config\." "$ACCESS_LOG" 2>/dev/null)
    if [ "$admin_attempts" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠ Admin/sensitive path probes: $admin_attempts${NC}"
        found=1
    fi

    # Look for high number of 4xx errors from single IP (brute force indicator)
    local brute_force
    brute_force=$(awk '$9 ~ /^4[0-9][0-9]$/ {print $1}' "$ACCESS_LOG" \
        | sort | uniq -c | sort -rn | head -5)
    if [ -n "$brute_force" ]; then
        echo -e "  ${YELLOW}Top IPs with client errors (4xx):${NC}"
        echo "$brute_force" | while read -r count ip; do
            if [ "$count" -ge 3 ]; then
                echo -e "    ${RED}$count errors from $ip${NC}"
            else
                echo -e "    $count errors from $ip"
            fi
        done
        found=1
    fi

    if [ "$found" -eq 0 ]; then
        echo -e "  ${GREEN}No suspicious activity detected ✓${NC}"
    fi

    echo ""
}

# =============================================================================
# Function: error_log_analysis
# Analyzes the error log for common error patterns
# =============================================================================
error_log_analysis() {
    # Skip if no error log is available
    if [ -z "$ERROR_LOG" ] || [ ! -f "$ERROR_LOG" ]; then
        return
    fi

    print_section "❌ Error Log Analysis"

    local total_errors
    total_errors=$(wc -l < "$ERROR_LOG")
    echo -e "  Total error log entries: ${YELLOW}$total_errors${NC}"

    # Count errors by severity level
    echo ""
    echo -e "  ${BOLD}Error Severity Distribution:${NC}"
    for level in emerg alert crit error warn notice info; do
        local count
        count=$(grep -ci "\[$level" "$ERROR_LOG" 2>/dev/null)
        if [ "$count" -gt 0 ]; then
            case "$level" in
                emerg|alert|crit)
                    echo -e "    ${RED}[$level]: $count${NC}";;
                error)
                    echo -e "    ${YELLOW}[$level]: $count${NC}";;
                *)
                    echo -e "    [$level]: $count";;
            esac
        fi
    done

    # Show the 5 most recent errors
    echo ""
    echo -e "  ${BOLD}5 Most Recent Errors:${NC}"
    grep -i "error" "$ERROR_LOG" | tail -5 | while IFS= read -r line; do
        echo -e "    ${RED}→${NC} $(echo "$line" | cut -c 1-80)..."
    done

    echo ""
}

# =============================================================================
# Function: print_footer
# Displays the report footer
# =============================================================================
print_footer() {
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "  ${BOLD}Analysis Complete${NC}"
    echo -e "  Access log entries analyzed: $(wc -l < "$ACCESS_LOG")"
    if [ -n "$ERROR_LOG" ] && [ -f "$ERROR_LOG" ]; then
        echo -e "  Error log entries analyzed:  $(wc -l < "$ERROR_LOG")"
    fi
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# Runs all analysis functions in sequence
# =============================================================================
main() {
    print_header
    general_stats
    top_ips
    status_codes
    top_pages
    http_methods
    traffic_by_hour
    suspicious_activity
    error_log_analysis
    print_footer
}

# Entry point
main
