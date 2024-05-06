#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
ORANGE='\033[38;5;208m'
YELLOW='\033[1;33m'  # Bright yellow text
GREEN='\033[0;32m'
BLUE='\033[0;34m'  # Added blue for IP addresses and ports
NC='\033[0m' # No Color

# Usage message
if [ "$#" -ne 1 ]; then
    echo -e "${ORANGE}Usage: $0 [dev|test|prod]${NC}"
    exit 1
fi

environment="$1"

# Check for necessary tools
if ! command -v dig &> /dev/null; then
    echo -e "${RED}dig command not found. Please install 'bind-utils or dnsutils' to proceed.${NC}"
    exit 1
fi

# Define service checks for each environment
dev_services=(
    "ss1.dev.xrd.island.is 5500"
    "ss1.dev.xrd.island.is 5577"
    "cs1.dev.xrd.island.is 4001"
    "cs1.dev.xrd.island.is 80"
    "ts.dev.xrd.island.is 8080"
)

# Function to check for running services
check_running_services() {
    echo -e "\n${YELLOW}Checking X-Road service status...${NC}"
    local services=(
        "xroad-proxy-ui-api"
        "xroad-addon-messagelog"
        "xroad-base"
        "xroad-signer"
        "xroad-opmonitor"
        "xroad-proxy"
        "xroad-confclient"
        "xroad-monitor"
        "xroad-proxy"
        "xroad-opsmanager"
    )
    for service in "${services[@]}"; do
        echo "Checking status of $service..."
        systemctl is-active --quiet $service
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Service $service is running.${NC}"
        else
            echo -e "${ORANGE}Service $service is not running.${NC}"
        fi
    done
}

# Function to perform network configuration checks
network_configuration_checks() {
    echo -e "\n${YELLOW}Performing network configuration checks...${NC}"

    # Get the current IP address, gateway, and subnet mask
    current_ip=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | grep -Po 'inet \K[\d.]+')

    echo -e "Current host IP Address: ${BLUE}$current_ip${NC}"
}

# Function to perform global health checks
global_health_checks() {
    echo -e "\n${YELLOW}Performing global health checks...${NC}"
    # Check hostname
    echo "Checking hostname..."
    hostname=$(hostname)
    echo -e "${GREEN}Hostname: $hostname${NC}"

    # Check FQDN
    echo "Checking FQDN..."
    fqdn=$(hostname -f)
    fqdn_ip=$(dig +short "$fqdn")
    current_ip=$(ip addr show $(ip route show default | awk '/default/ {print $5}') | grep -Po 'inet \K[\d.]+')

    if [ $? -eq 0 ] && [ -n "$fqdn_ip" ]; then
        echo -e "${GREEN}FQDN: $fqdn${NC}"
        echo -e "IP Address from FQDN: ${BLUE}$fqdn_ip${NC}"
        echo -e "Current host IP Address: ${BLUE}$current_ip${NC}"

        # Verify if the current IP matches the IP from the FQDN
        if [[ "$current_ip" != "$fqdn_ip" ]]; then
            echo -e "${RED}Warning: Current IP ($current_ip) and FQDN IP ($fqdn_ip) do not match.${NC}"
        fi
    else
        echo -e "${RED}FQDN check failed or no IP returned.${NC}"
        return
    fi

    # DNS lookups
    echo -e "\n${YELLOW}Performing Performing forward and reverse DNS lookup for $fqdn... ${NC}"
    ip_address=$(dig +short "$fqdn")
    if [ -n "$ip_address" ]; then
        echo -e "${GREEN}IP Address for $fqdn: $ip_address${NC}"
        reverse_lookup=$(dig +short -x "$ip_address")
        echo -e "${GREEN}Reverse DNS for $ip_address: $reverse_lookup${NC}"
    else
        echo -e "${RED}DNS lookup failed for $fqdn.${NC}"
    fi

    # TCP connections on specific ports
    echo -e "\n${YELLOW}Checking X-Road connections for $fqdn...${NC}"
    check_tcp_connection "$fqdn" 5500
    check_tcp_connection "$fqdn" 5577

    # Check running services
    check_running_services
}

# Function to check TCP connections using nc
check_tcp_connection() {
    local fqdn=$1
    local port=$2
    local timeout=2  # Timeout in seconds
    echo "Checking connection to $fqdn on port $port..."
    if nc -vz -w $timeout $fqdn $port > /dev/null 2>&1; then
        echo -e "${GREEN}Connection to $fqdn on port $port successful.${NC}"
    else
        echo -e "${RED}Connection to $fqdn on port $port failed.${NC}"
    fi
}

# Function to check services using nc
check_services() {
    for service in "$@"; do
        if nc -vz -w 2 ${service%% *} ${service##* } > /dev/null 2>&1; then
            echo -e "${GREEN}Connection to $service successful.${NC}"
        else
            echo -e "${RED}Connection to $service failed.${NC}"
        fi
    done
}

# Perform global health checks
global_health_checks

echo -e "\n${YELLOW}Checking connections to Central X-Road environment for $environment...${NC}"
# Perform checks based on the environment
case $environment in
    dev)
        check_services "${dev_services[@]}"
        ;;
    test)
        # check_services "${test_services[@]}"
        ;;
    prod)
        # check_services "${prod_services[@]}"
        ;;
    *)
        echo -e "${RED}Invalid environment. Please choose from dev, test, or prod.${NC}"
        exit 1
        ;;
esac
