#!/bin/bash

# Enhanced OSINT Reconnaissance Script
# Inspired by TCM Security OSINT course
# Usage: ./recon.sh <domain>

# Color definitions
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Check if domain argument is provided
if [ $# -ne 1 ]; then
    echo -e "${RED}⚡ Syntax error! Need a target domain to start the party${RESET}"
    echo "Usage: $0 <domain>"
    exit 1
fi

domain=$1
timestamp=$(date +%Y%m%d_%H%M%S)
base_dir="${domain}_${timestamp}"
info_path="$base_dir/info"
subdomain_path="$base_dir/subdomains"
screenshot_path="$base_dir/screenshots"
report_path="$base_dir/report"

# Function to check if required tools are installed
check_requirements() {
    local tools=("whois" "subfinder" "assetfinder" "httprobe" "gowitness")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}🔧 Houston, we have a problem! Missing some cyber-tools:${RESET}"
        printf '%s\n' "${missing_tools[@]}"
        exit 1
    fi
}

# Function to create directories
setup_directories() {
    local dirs=("$info_path" "$subdomain_path" "$screenshot_path" "$report_path")
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir"; then
            echo -e "${RED}📁 Uh-oh! Couldn't create my secret folder: $dir${RESET}"
            exit 1
        fi
    done
    echo -e "${GREEN}🎯 Mission control, all systems are go!${RESET}"
}

# Function to handle errors
handle_error() {
    local message=$1
    echo -e "${RED}💥 Plot twist! $message${RESET}"
    exit 1
}

# Main scanning functions
gather_whois() {
    echo -e "${CYAN}🕵️ Time to snoop around the WHOIS database...${RESET}"
    whois "$domain" > "$info_path/whois.txt" 2>/dev/null || \
        handle_error "The WHOIS database is playing hard to get"
}

find_subdomains() {
    echo -e "${MAGENTA}🎣 Fishing for subdomains... This could be a big catch!${RESET}"
    echo -e "${YELLOW}🚀 Launching subfinder into cyberspace...${RESET}"
    subfinder -d "$domain" -o "$subdomain_path/subfinder.txt" 2>/dev/null

    echo -e "${YELLOW}🔭 Deploying assetfinder telescope...${RESET}"
    assetfinder "$domain" | grep "$domain" > "$subdomain_path/assetfinder.txt"

    # Combine and deduplicate results
    cat "$subdomain_path/subfinder.txt" "$subdomain_path/assetfinder.txt" | sort -u > "$subdomain_path/all_subdomains.txt"
    count=$(wc -l < "$subdomain_path/all_subdomains.txt")
    echo -e "${GREEN}🎉 Jackpot! Found $count unique subdomains in the wild${RESET}"
}

probe_alive() {
    echo -e "${BLUE}🏃 Time to see which domains can run and which can hide...${RESET}"
    cat "$subdomain_path/all_subdomains.txt" | \
        httprobe -c 50 -t 3000 -prefer-https | \
        grep https | sed 's/https\?:\/\///' | \
        tee "$subdomain_path/alive.txt"
    count=$(wc -l < "$subdomain_path/alive.txt")
    echo -e "${GREEN}💓 Found $count domains with a pulse!${RESET}"
}

take_screenshots() {
    echo -e "${MAGENTA}📸 Say cheese! Taking screenshots of our findings...${RESET}"
    if [ -s "$subdomain_path/alive.txt" ]; then
        gowitness scan file -f "$subdomain_path/alive.txt" \
            --screenshot-path "$screenshot_path/" \
            --timeout 20 \
            --no-http
        echo -e "${GREEN}📱 Screenshot gallery is ready for viewing!${RESET}"
    else
        echo -e "${YELLOW}📷 Cameras are ready but no domains showed up for the photoshoot${RESET}"
    fi
}

generate_report() {
    echo -e "${CYAN}📝 Time to write up our cyber detective story...${RESET}"
    {
        echo "# 🔍 Super Secret Reconnaissance Report for $domain"
        echo "🕒 Generated on: $(date)"
        echo -e "\n## 📊 The Numbers Game"
        echo "* 🎯 Total subdomains discovered: $(wc -l < "$subdomain_path/all_subdomains.txt")"
        echo "* 💓 Domains showing signs of life: $(wc -l < "$subdomain_path/alive.txt")"
        echo -e "\n## 🕵️ WHOIS Information"
        echo "\`\`\`"
        cat "$info_path/whois.txt"
        echo "\`\`\`"
        echo -e "\n## 🌐 Living Domains"
        echo "\`\`\`"
        cat "$subdomain_path/alive.txt"
        echo "\`\`\`"
    } > "$report_path/report.md"
}

# Main execution
main() {
    echo -e "${CYAN}🎮 Game On! Starting reconnaissance mission for $domain${RESET}"
    check_requirements
    setup_directories
    gather_whois
    find_subdomains
    probe_alive
    take_screenshots
    generate_report
    echo -e "${GREEN}🏆 Mission Accomplished! Your treasure awaits in: $base_dir${RESET}"
    echo -e "${YELLOW}🌟 Thanks for playing! Stay curious and hack responsibly!${RESET}"
}

main
