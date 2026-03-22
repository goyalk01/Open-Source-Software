#!/bin/bash
# =============================================================================
# Script Name  : apache_vhost_manager.sh
# Description  : Interactive virtual host manager for Apache HTTP Server
# Purpose      : Create, list, enable, disable, and delete Apache virtual hosts
#                using a menu-driven interface with case statements.
# Usage        : sudo bash apache_vhost_manager.sh
# Author       : Open Source Audit Project
# =============================================================================

# ----- Color Definitions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ----- Configuration -----
VHOST_DIR="/etc/apache2/sites-available"
ENABLED_DIR="/etc/apache2/sites-enabled"
WEB_ROOT="/var/www"

# =============================================================================
# Function: print_banner
# Displays the application banner
# =============================================================================
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}Apache Virtual Host Manager${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Manage your Apache virtual hosts easily               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# Function: check_root
# Ensures the script is run with root privileges
# =============================================================================
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root (use sudo).${NC}"
        echo "Usage: sudo bash $0"
        exit 1
    fi
}

# =============================================================================
# Function: check_apache
# Verifies Apache is installed
# =============================================================================
check_apache() {
    if ! command -v apache2 > /dev/null 2>&1 && ! command -v httpd > /dev/null 2>&1; then
        echo -e "${RED}Error: Apache is not installed.${NC}"
        echo "Install with: sudo apt install apache2"
        exit 1
    fi
}

# =============================================================================
# Function: show_menu
# Displays the main menu options
# =============================================================================
show_menu() {
    echo -e "${BOLD}── Main Menu ──${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) Create a new virtual host"
    echo -e "  ${GREEN}2${NC}) List all virtual hosts"
    echo -e "  ${GREEN}3${NC}) Enable a virtual host"
    echo -e "  ${GREEN}4${NC}) Disable a virtual host"
    echo -e "  ${GREEN}5${NC}) Delete a virtual host"
    echo -e "  ${GREEN}6${NC}) View virtual host configuration"
    echo -e "  ${GREEN}7${NC}) Test Apache configuration"
    echo -e "  ${RED}0${NC}) Exit"
    echo ""
    echo -n -e "  ${BOLD}Select an option [0-7]:${NC} "
}

# =============================================================================
# Function: create_vhost
# Interactively creates a new virtual host configuration
# Uses: read (user input), cat (file creation), heredoc (template)
# =============================================================================
create_vhost() {
    echo ""
    echo -e "${BOLD}── Create New Virtual Host ──${NC}"
    echo ""

    # Prompt for the domain name
    read -r -p "  Enter domain name (e.g., mysite.local): " domain

    # Validate input is not empty
    if [ -z "$domain" ]; then
        echo -e "  ${RED}Error: Domain name cannot be empty.${NC}"
        return 1
    fi

    # Check if config already exists
    if [ -f "$VHOST_DIR/${domain}.conf" ]; then
        echo -e "  ${YELLOW}Warning: Virtual host '${domain}' already exists.${NC}"
        read -r -p "  Overwrite? (y/n): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo -e "  ${YELLOW}Cancelled.${NC}"
            return 0
        fi
    fi

    # Prompt for admin email with a default
    read -r -p "  Enter admin email [webmaster@${domain}]: " admin_email
    admin_email="${admin_email:-webmaster@${domain}}"

    # Prompt for document root with a default
    read -r -p "  Enter document root [${WEB_ROOT}/${domain}/public_html]: " doc_root
    doc_root="${doc_root:-${WEB_ROOT}/${domain}/public_html}"

    # Prompt for port with default 80
    read -r -p "  Enter port [80]: " port
    port="${port:-80}"

    # Create the document root directory
    echo ""
    echo -e "  ${CYAN}Creating document root...${NC}"
    mkdir -p "$doc_root"

    # Create a default index.html page
    cat > "$doc_root/index.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to ${domain}</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px;
               background: #1a1a2e; color: #e0e0e0; }
        h1 { color: #00d4ff; }
        p { color: #aaa; }
    </style>
</head>
<body>
    <h1>Welcome to ${domain}</h1>
    <p>Your virtual host is working correctly.</p>
    <p>Document Root: ${doc_root}</p>
</body>
</html>
HTMLEOF

    # Generate the virtual host configuration file using a heredoc
    echo -e "  ${CYAN}Writing virtual host configuration...${NC}"
    cat > "$VHOST_DIR/${domain}.conf" << VHOSTEOF
# Virtual Host Configuration for ${domain}
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# Generated by Apache Virtual Host Manager

<VirtualHost *:${port}>
    # Server identification
    ServerAdmin ${admin_email}
    ServerName ${domain}
    ServerAlias www.${domain}

    # Document root — where web files are served from
    DocumentRoot ${doc_root}

    # Directory permissions
    <Directory ${doc_root}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Logging — separate logs for each virtual host
    ErrorLog \${APACHE_LOG_DIR}/${domain}-error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}-access.log combined

    # Security headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
</VirtualHost>
VHOSTEOF

    # Set proper file ownership
    chown -R www-data:www-data "$doc_root" 2>/dev/null

    echo ""
    echo -e "  ${GREEN}✓ Virtual host '${domain}' created successfully!${NC}"
    echo -e "  ${CYAN}Config:${NC} $VHOST_DIR/${domain}.conf"
    echo -e "  ${CYAN}DocRoot:${NC} $doc_root"
    echo ""

    # Ask if user wants to enable it immediately
    read -r -p "  Enable this virtual host now? (y/n): " enable_now
    if [ "$enable_now" = "y" ] || [ "$enable_now" = "Y" ]; then
        a2ensite "${domain}.conf" > /dev/null 2>&1
        systemctl reload apache2 2>/dev/null
        echo -e "  ${GREEN}✓ Virtual host enabled and Apache reloaded.${NC}"
    fi
}

# =============================================================================
# Function: list_vhosts
# Lists all available virtual hosts and their enabled/disabled status
# Uses: for loop, conditional check, file system traversal
# =============================================================================
list_vhosts() {
    echo ""
    echo -e "${BOLD}── Available Virtual Hosts ──${NC}"
    echo ""

    # Check if the sites-available directory exists
    if [ ! -d "$VHOST_DIR" ]; then
        echo -e "  ${YELLOW}Virtual host directory not found: $VHOST_DIR${NC}"
        return 1
    fi

    # Count total configs
    local total=0
    local enabled=0
    local disabled=0

    echo -e "  ${BOLD}Status     Config File${NC}"
    echo -e "  ─────────────────────────────────────────"

    # Loop through each .conf file in sites-available
    for config in "$VHOST_DIR"/*.conf; do
        # Check if any conf files exist (glob might not match)
        if [ ! -f "$config" ]; then
            echo -e "  ${YELLOW}No virtual host configurations found.${NC}"
            return 0
        fi

        local filename
        filename=$(basename "$config")
        total=$((total + 1))

        # Check if this config is enabled (has a symlink in sites-enabled)
        if [ -L "$ENABLED_DIR/$filename" ] || [ -f "$ENABLED_DIR/$filename" ]; then
            echo -e "  ${GREEN}[ENABLED]${NC}  $filename"
            enabled=$((enabled + 1))
        else
            echo -e "  ${RED}[DISABLED]${NC} $filename"
            disabled=$((disabled + 1))
        fi
    done

    echo ""
    echo -e "  Total: $total | ${GREEN}Enabled: $enabled${NC} | ${RED}Disabled: $disabled${NC}"
}

# =============================================================================
# Function: enable_vhost
# Enables a virtual host by name
# =============================================================================
enable_vhost() {
    echo ""
    echo -e "${BOLD}── Enable Virtual Host ──${NC}"
    echo ""

    # Show available (disabled) configs
    list_vhosts

    echo ""
    read -r -p "  Enter config filename to enable (e.g., mysite.local.conf): " config_name

    if [ -z "$config_name" ]; then
        echo -e "  ${RED}Error: No filename provided.${NC}"
        return 1
    fi

    # Check if the config file exists
    if [ ! -f "$VHOST_DIR/$config_name" ]; then
        echo -e "  ${RED}Error: Config '$config_name' not found in $VHOST_DIR${NC}"
        return 1
    fi

    # Enable the site using a2ensite
    a2ensite "$config_name" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ '$config_name' enabled.${NC}"
        echo -e "  ${CYAN}Reloading Apache...${NC}"
        systemctl reload apache2 2>/dev/null
        echo -e "  ${GREEN}✓ Apache reloaded.${NC}"
    else
        echo -e "  ${RED}Failed to enable '$config_name'.${NC}"
    fi
}

# =============================================================================
# Function: disable_vhost
# Disables a virtual host by name
# =============================================================================
disable_vhost() {
    echo ""
    echo -e "${BOLD}── Disable Virtual Host ──${NC}"
    echo ""

    list_vhosts

    echo ""
    read -r -p "  Enter config filename to disable: " config_name

    if [ -z "$config_name" ]; then
        echo -e "  ${RED}Error: No filename provided.${NC}"
        return 1
    fi

    # Disable the site using a2dissite
    a2dissite "$config_name" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ '$config_name' disabled.${NC}"
        echo -e "  ${CYAN}Reloading Apache...${NC}"
        systemctl reload apache2 2>/dev/null
        echo -e "  ${GREEN}✓ Apache reloaded.${NC}"
    else
        echo -e "  ${RED}Failed to disable '$config_name'.${NC}"
    fi
}

# =============================================================================
# Function: delete_vhost
# Permanently removes a virtual host configuration and optionally its files
# =============================================================================
delete_vhost() {
    echo ""
    echo -e "${BOLD}── Delete Virtual Host ──${NC}"
    echo ""

    list_vhosts

    echo ""
    read -r -p "  Enter config filename to delete: " config_name

    if [ -z "$config_name" ]; then
        echo -e "  ${RED}Error: No filename provided.${NC}"
        return 1
    fi

    if [ ! -f "$VHOST_DIR/$config_name" ]; then
        echo -e "  ${RED}Error: Config '$config_name' not found.${NC}"
        return 1
    fi

    # Safety confirmation — deletion is destructive
    echo -e "  ${RED}WARNING: This will permanently delete the configuration.${NC}"
    read -r -p "  Are you sure? (type 'yes' to confirm): " confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "  ${YELLOW}Cancelled.${NC}"
        return 0
    fi

    # Disable first if enabled
    a2dissite "$config_name" > /dev/null 2>&1

    # Remove the config file
    rm -f "$VHOST_DIR/$config_name"
    echo -e "  ${GREEN}✓ Configuration '$config_name' deleted.${NC}"

    # Ask about document root
    read -r -p "  Also delete the document root directory? (y/n): " del_root
    if [ "$del_root" = "y" ] || [ "$del_root" = "Y" ]; then
        # Extract domain from filename (remove .conf extension)
        local domain="${config_name%.conf}"
        if [ -d "$WEB_ROOT/$domain" ]; then
            rm -rf "$WEB_ROOT/$domain"
            echo -e "  ${GREEN}✓ Document root '$WEB_ROOT/$domain' deleted.${NC}"
        fi
    fi

    # Reload Apache
    systemctl reload apache2 2>/dev/null
    echo -e "  ${GREEN}✓ Apache reloaded.${NC}"
}

# =============================================================================
# Function: view_vhost
# Displays the contents of a virtual host configuration file
# =============================================================================
view_vhost() {
    echo ""
    echo -e "${BOLD}── View Virtual Host Configuration ──${NC}"
    echo ""

    list_vhosts

    echo ""
    read -r -p "  Enter config filename to view: " config_name

    if [ -z "$config_name" ]; then
        echo -e "  ${RED}Error: No filename provided.${NC}"
        return 1
    fi

    if [ ! -f "$VHOST_DIR/$config_name" ]; then
        echo -e "  ${RED}Error: Config '$config_name' not found.${NC}"
        return 1
    fi

    echo ""
    echo -e "${CYAN}── Contents of $config_name ──${NC}"
    echo ""
    # Display file contents with line numbers
    cat -n "$VHOST_DIR/$config_name"
    echo ""
}

# =============================================================================
# Function: test_config
# Tests Apache configuration for syntax errors
# =============================================================================
test_config() {
    echo ""
    echo -e "${BOLD}── Testing Apache Configuration ──${NC}"
    echo ""

    # Run Apache config test
    local output
    output=$(apache2ctl configtest 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "  ${GREEN}✓ Configuration test passed!${NC}"
        echo -e "  $output"
    else
        echo -e "  ${RED}✗ Configuration test failed:${NC}"
        echo -e "  $output"
    fi
}

# =============================================================================
# MAIN EXECUTION
# Menu loop using while + case statement
# =============================================================================
main() {
    check_root
    check_apache

    # Infinite loop — exits when user selects option 0
    while true; do
        print_banner
        show_menu
        read -r choice

        # Route to correct function based on user's menu selection
        case "$choice" in
            1)
                create_vhost
                ;;
            2)
                list_vhosts
                ;;
            3)
                enable_vhost
                ;;
            4)
                disable_vhost
                ;;
            5)
                delete_vhost
                ;;
            6)
                view_vhost
                ;;
            7)
                test_config
                ;;
            0)
                echo ""
                echo -e "  ${GREEN}Goodbye!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "  ${RED}Invalid option. Please select 0-7.${NC}"
                ;;
        esac

        # Pause before redrawing menu
        echo ""
        read -r -p "  Press Enter to continue..."
    done
}

# Entry point
main
