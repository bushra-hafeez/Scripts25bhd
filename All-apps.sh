#!/bin/bash

# Define colors
NC="\e[0m"         # No color (reset)
PINK="\e[95m"      # Light pink (for application name)
YELLOW="\e[33m"    # Yellow (for column headers)
GREEN="\e[32m"     # Green (for server IP)
WHITE="\e[97m"     # White (default text)

# Function to fetch IP details (Country)
get_ip_details() {
    local ip=$1
    if [[ "$ip" == "$SERVER_IP" || "$ip" == "127.0.0.1" ]]; then
        echo "$SERVER_COUNTRY - Internal Request"
    else
        curl -s "https://ipinfo.io/$ip/country" || echo "Unknown"
    fi
}

# Get server's public IP & country
SERVER_IP=$(curl -s ifconfig.me)
SERVER_COUNTRY=$(curl -s "https://ipinfo.io/$SERVER_IP/country")

# Print title
echo -e "${YELLOW}=============================== Traffic Stats for Today ============================================================${NC}"

# Iterate over applications
for A in $(ls -l /home/master/applications/ | grep "^d" | awk '{print $NF}'); do
    # Fetch domain name from Nginx config
    NGINX_CONF="/home/master/applications/$A/conf/server.nginx"
    domain="Unknown"
    if [ -f "$NGINX_CONF" ]; then
        domain=$(grep -m 1 'server_name' $NGINX_CONF | cut -d ' ' -f2- | tr -d ';')
    fi

    echo -e "\n${PINK}Application: $A ($domain)${NC}"
    echo "---------------------------------------------------------------------------------------------------------------------------------------"
    echo -e "${YELLOW}ReqCount  | IP Address     | Country   | Requested URL${NC}"
    echo "---------------------------------------------------------------------------------------------------------------------------------------"

    # Fetch top IPs and URLs from logs
    awk '{print $1,$7}' /home/master/applications/$A/logs/apache_*.access.log \
        | cut -d? -f1 \
        | sort | uniq -c | sort -nr | head -n 5 \
        | while read count ip url; do
            country_info=$(get_ip_details "$ip")

            # Colorize server IP entries
            if [[ "$ip" == "$SERVER_IP" || "$ip" == "127.0.0.1" ]]; then
                printf "${GREEN}%-9s | %-14s | %-10s | %-30s${NC}\n" "$count" "$ip" "$country_info" "$url"
            else
                printf "${WHITE}%-9s | %-14s | %-10s | %-30s${NC}\n" "$count" "$ip" "$country_info" "$url"
            fi
        done
done
