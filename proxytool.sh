#!/bin/bash

# ==============================================
# GLOBAL CONFIGURATIONS
# ==============================================

# Colors for terminal output
RED='\033[0;31m'       # Red color for errors
GREEN='\033[0;32m'     # Green color for success
YELLOW='\033[0;33m'    # Yellow color for warnings
BLUE='\033[0;34m'      # Blue color for information
NC='\033[0m'           # No color (reset)

# Default values
DEFAULT_OUTPUT="./proxies.txt"       # Default output file for proxies
DEFAULT_PROTOCOL="http"              # Default proxy protocol (http, socks4, socks5)
DEFAULT_TIMEOUT="1000"               # Default timeout in milliseconds
DEFAULT_COUNTRY="all"                # Default country filter (all countries)
DEFAULT_PORT_CHECK="false"           # Default port check (disabled)
DEFAULT_SPEED_TEST="false"           # Default speed test (disabled)
DEFAULT_PING_CHECK="false"           # Default ping check (disabled)
DEFAULT_CHECK_PROXIES="false"        # Default proxy verification (disabled)
DEFAULT_LIST_PROXIES="false"         # Default proxy listing (disabled)
DEFAULT_CHECK_DEPS="false"           # Default dependency check (disabled)
API_URL="https://api.proxyscrape.com/v4/free-proxy-list/get"  # API URL to fetch proxies

# ==============================================
# FUNCTIONS
# ==============================================

# Function to display help information
show_help() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo "Options:"
    echo "  -o <file>      Output file (default: ${DEFAULT_OUTPUT})"
    echo "  -p <protocol>  Protocol (http, socks4, socks5) (default: ${DEFAULT_PROTOCOL})"
    echo "  -t <timeout>   Timeout in ms (default: ${DEFAULT_TIMEOUT})"
    echo "  -c <country>   Filter by country (e.g., US, BR) (default: ${DEFAULT_COUNTRY})"
    echo "  -P             Check proxy ping"
    echo "  -S             Test proxy speed with speedtest-go"
    echo "  -C             Verify proxies (ping, port, speed)"
    echo "  -l             List proxies"
    echo "  -D             Check dependencies"
    echo "  -h             Show help"
    echo -e "\nExamples:"
    echo "  $0 -p socks5 -c US -C"
    echo "  $0 -o fast_proxies.txt -t 10000 -l"
    exit 0
}

# Function to check for required dependencies
check_deps() {
    local deps=("curl" "nping" "nc" "speedtest-go")  # List of required dependencies
    local missing_deps=()

    # Check if each dependency is installed
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")  # Add missing dependency to the list
        fi
    done

    # If there are missing dependencies, try to install them using apt (without sudo)
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}The following dependencies are missing:${NC}" >&2
        for dep in "${missing_deps[@]}"; do
            echo -e "${YELLOW}- ${dep}${NC}" >&2  # Display missing dependencies
        done

        echo -e "\n${GREEN}Attempting to install dependencies with apt...${NC}" >&2
        if apt install -y "${missing_deps[@]}" &> /dev/null; then
            echo -e "${GREEN}Dependencies installed successfully!${NC}" >&2
        else
            echo -e "${RED}Failed to install dependencies.${NC}" >&2
            echo -e "\n${GREEN}To install manually, run:${NC}" >&2
            echo -e "${BLUE}sudo apt install -y ${missing_deps[*]}${NC}" >&2
            exit 1
        fi
    fi
}

# Function to fetch proxies from the API
fetch_proxies() {
    # Build the API URL with parameters
    local params="request=display_proxies&protocol=${protocol}&proxy_format=protocolipport&format=text&timeout=${timeout}&country=${country}"
    local url="${API_URL}?${params}"
    
    echo -e "${BLUE}Downloading ${protocol} proxies (${country})...${NC}"
    
    # Fetch proxies using curl and save them to the output file
    if ! curl -s "$url" > "$output_file"; then
        echo -e "${RED}Failed to download proxies!${NC}" >&2
        exit 1
    fi

    # Check if the proxy list is empty
    if [[ $(wc -l < "$output_file") -eq 0 ]]; then
        echo -e "${RED}No proxies found for protocol ${protocol}!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Proxies saved to: ${output_file}${NC}"
}

# Function to check if a proxy port is open
check_port() {
    local proxy=$1  # Proxy host
    local port=$2   # Proxy port

    # Use netcat (nc) to check if the port is open
    if nc -z -w 2 "$proxy" "$port" &> /dev/null; then
        echo -e "${GREEN}Port ${port} is open${NC}"
    else
        echo -e "${RED}Port ${port} is closed${NC}"
    fi
}

# Function to test proxy speed using speedtest-go
test_speed() {
    local proxy=$1
    echo -e "\n${YELLOW}Testing speed via proxy: ${proxy}${NC}"
    
    # Run speedtest-go with the proxy
    local result
    if ! result=$(speedtest-go --proxy="http://${proxy}" --json 2>&1); then
        echo -e "${RED}Failed to run speedtest-go!${NC}" >&2
        echo -e "${YELLOW}Details: ${result}${NC}" >&2
        return
    fi

    # Parse the JSON result
    local download=$(echo "$result" | jq -r '.download.bandwidth')  # Download speed in bps
    local upload=$(echo "$result" | jq -r '.upload.bandwidth')      # Upload speed in bps
    local ping=$(echo "$result" | jq -r '.ping.latency')           # Ping in ms

    # Convert bandwidth to Mbps and display results
    echo -e "${BLUE}Download: $(echo "scale=2; $download / 125000" | bc) Mbps${NC}"
    echo -e "${BLUE}Upload: $(echo "scale=2; $upload / 125000" | bc) Mbps${NC}"
    echo -e "${BLUE}Ping: ${ping} ms${NC}"
}

# Function to check proxy ping using speedtest-go
check_ping() {
    local proxy=$1
    echo -e "\n${YELLOW}Checking ping for proxy: ${proxy}${NC}"
    
    # Run speedtest-go in ping mode
    local result
    if ! result=$(speedtest-go --proxy="http://${proxy}" --ping-mode="http" --json 2>&1); then
        echo -e "${RED}Failed to check ping!${NC}" >&2
        echo -e "${YELLOW}Details: ${result}${NC}" >&2
        return
    fi

    # Parse the JSON result
    local ping=$(echo "$result" | jq -r '.ping.latency')  # Ping in ms
    echo -e "${GREEN}Ping: ${ping} ms${NC}"
}

# Function to check a single proxy (ping, port, speed)
check_proxy() {
    local link=$1
    [[ -z "$link" ]] && return  # Skip if the link is empty

    # Extract proxy host and port from the link
    local proxy=$(echo "$link" | awk -F '//' '{print $2}')
    local host=${proxy%:*}
    local port=${proxy#*:}

    echo -e "\n${YELLOW}Proxy: ${host}:${port}${NC}"
    
    # Check ping (if enabled)
    [[ "$ping_check" == true ]] && check_ping "${host}:${port}"

    # Check port (if enabled)
    [[ "$check_port" == true ]] && check_port "$host" "$port"

    # Test speed (if enabled)
    [[ "$speed_test" == true ]] && test_speed "${host}:${port}"
}

# Function to verify all proxies in the output file
verify_proxies() {
    echo -e "${BLUE}Verifying proxies...${NC}"
    while read -r proxy; do
        check_proxy "$proxy"  # Check each proxy
    done < "$output_file"
}

# Function to list all proxies in the output file
list_proxies() {
    echo -e "\n${BLUE}Proxies found (${protocol}):${NC}"
    cat -n "$output_file"  # Display proxies with line numbers
}

# ==============================================
# MAIN EXECUTION
# ==============================================

main() {
    clear  # Clear the terminal screen

    # Initialize variables with default values
    output_file="${DEFAULT_OUTPUT}"
    protocol="${DEFAULT_PROTOCOL}"
    timeout="${DEFAULT_TIMEOUT}"
    country="${DEFAULT_COUNTRY}"
    check_port="${DEFAULT_PORT_CHECK}"
    speed_test="${DEFAULT_SPEED_TEST}"
    ping_check="${DEFAULT_PING_CHECK}"
    check_proxies="${DEFAULT_CHECK_PROXIES}"
    list_proxies="${DEFAULT_LIST_PROXIES}"
    check_deps="${DEFAULT_CHECK_DEPS}"

    # Process command-line arguments
    while getopts "o:p:t:c:PSClDh" opt; do
        case "$opt" in
            o) output_file="${OPTARG:-${DEFAULT_OUTPUT}}" ;;  # Set output file
            p) protocol="${OPTARG:-${DEFAULT_PROTOCOL}}" ;;  # Set protocol
            t) timeout="${OPTARG:-${DEFAULT_TIMEOUT}}" ;;    # Set timeout
            c) country="${OPTARG:-${DEFAULT_COUNTRY}}" ;;    # Set country filter
            P) ping_check=true ;;                            # Enable ping check
            S) speed_test=true ;;                            # Enable speed test
            C) check_proxies=true ;;                         # Enable proxy verification
            l) list_proxies=true ;;                          # Enable proxy listing
            D) check_deps=true ;;                            # Enable dependency check
            h) show_help ;;                                  # Show help
            *) echo -e "${RED}Invalid option!${NC}"; exit 1 ;;  # Handle invalid options
        esac
    done

    # Check dependencies (if enabled)
    [[ "$check_deps" == true ]] && check_deps

    # Validate protocol
    [[ ! "$protocol" =~ ^(http|socks4|socks5)$ ]] && { echo -e "${RED}Invalid protocol! Use: http, socks4, or socks5${NC}"; exit 1; }

    # Fetch proxies
    fetch_proxies

    # Verify proxies (if enabled)
    [[ "$check_proxies" == true ]] && verify_proxies

    # List proxies (if enabled)
    [[ "$list_proxies" == true ]] && list_proxies

    echo -e "\n${GREEN}Done!${NC}"
}

# Execute the script
main "$@"