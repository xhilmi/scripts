#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to generate CSR interactively
generate_csr() {
    echo -e "${CYAN}\n🔹 Generating a new CSR...${NC}"
    read -p "🔹 Enter key file path: " key_file
    read -p "🔹 Enter CSR output file path: " csr_file
    read -p "🔹 Enter Country Name (C): " country
    read -p "🔹 Enter State or Province Name (ST): " state
    read -p "🔹 Enter Locality Name (L): " locality
    read -p "🔹 Enter Organization Name (O): " organization
    read -p "🔹 Enter Common Name (CN, e.g., *.domain.com): " cn
    subj="/C=$country/ST=$state/L=$locality/O=$organization/CN=$cn"
    echo -e "${YELLOW}🔹 Generating CSR...${NC}"
    openssl req -new -nodes -out "$csr_file" -key "$key_file" -subj "$subj"
    echo -e "${GREEN}✔ CSR generated successfully: $csr_file${NC}"
}

# Function to check domain SSL
check_domain() {
    read -p "🔹 Enter domain: " domain
    echo -e "${YELLOW}🔹 Checking SSL connection for $domain...${NC}"
    openssl s_client -connect "$domain":443
}

# Function to check CSR modulus
check_csr_modulus() {
    read -p "🔹 Enter CSR file path: " csr_file
    echo -e "${BLUE}🔹 Checking CSR Modulus...${NC}"
    openssl req -noout -modulus -in "$csr_file" | openssl md5
}

# Function to check CRT modulus
check_crt_modulus() {
    read -p "🔹 Enter CRT file path: " crt_file
    echo -e "${BLUE}🔹 Checking CRT Modulus...${NC}"
    openssl x509 -noout -modulus -in "$crt_file" | openssl md5
}

# Function to check KEY modulus
check_key_modulus() {
    read -p "🔹 Enter KEY file path: " key_file
    echo -e "${BLUE}🔹 Checking KEY Modulus...${NC}"
    openssl rsa -noout -modulus -in "$key_file" | openssl md5
}

# Function to check CSR SHASUM
check_csr_shasum() {
    read -p "🔹 Enter CSR file path: " csr_file
    echo -e "${BLUE}🔹 Checking CSR SHA256 Checksum...${NC}"
    openssl req -in "$csr_file" -pubkey -noout -outform pem | sha256sum
}

# Function to check KEY SHASUM
check_key_shasum() {
    read -p "🔹 Enter KEY file path: " key_file
    echo -e "${BLUE}🔹 Checking KEY SHA256 Checksum...${NC}"
    openssl pkey -in "$key_file" -pubout -noout -outform pem | sha256sum
}

# Function to check CSR details
check_csr_details() {
    read -p "🔹 Enter CSR file path: " csr_file
    echo -e "${BLUE}🔹 Checking CSR Details...${NC}"
    openssl req -text -noout -verify -in "$csr_file"
}

# Function to check CRT details
check_crt_details() {
    read -p "🔹 Enter CRT file path: " crt_file
    echo -e "${BLUE}🔹 Checking CRT Details...${NC}"
    openssl x509 -in "$crt_file" -text -noout
}

# Function to check KEY details
check_key_details() {
    read -p "🔹 Enter KEY file path: " key_file
    echo -e "${BLUE}🔹 Checking KEY Details...${NC}"
    openssl rsa -in "$key_file" -check -text -noout
}

# Menu
while true; do
    echo -e "${GREEN}\n============================="
    echo -e "   SSL Utility Script"
    echo -e "=============================${NC}"
    echo -e "${YELLOW}1) Generate CSR"
    echo "2) Check Domain SSL"
    echo "3) Check CSR Modulus"
    echo "4) Check CRT Modulus"
    echo "5) Check KEY Modulus"
    echo "6) Check CSR SHASUM"
    echo "7) Check KEY SHASUM"
    echo "8) Check CSR Details"
    echo "9) Check CRT Details"
    echo "10) Check KEY Details"
    echo -e "11) Exit${NC}"
    echo ""
    read -p "🔹 Enter choice: " choice

    case $choice in
        1) generate_csr ;;
        2) check_domain ;;
        3) check_csr_modulus ;;
        4) check_crt_modulus ;;
        5) check_key_modulus ;;
        6) check_csr_shasum ;;
        7) check_key_shasum ;;
        8) check_csr_details ;;
        9) check_crt_details ;;
        10) check_key_details ;;
        11) echo -e "${GREEN}✔ Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}✖ Invalid choice, try again.${NC}" ;;
    esac
done
