#!/bin/bash

chmod +x bin/blocx-deposit-cli

# Color definitions for better readability
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Simple logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1" >&2
}

# Function to check if a command exists
check_command() {
    if ! which "$1" &>/dev/null; then
        log_error "$1 is required but not installed."
        log_info "Please run ./docker-setup.sh first to install dependencies."
        exit 1
    fi
}

# Function to handle errors
handle_error() {
    log_error "$1"
    exit 1
}

# Check for required dependencies
check_command docker
check_command jq

# Function to initialize the execution layer
initialize_node() {
    log_info "Initializing node execution layer..."
    
    if [ ! -d "el-cl-genesis-data" ]; then
        log_info "Genesis data not found. Unpacking genesis data..."
        if [ -f "el-cl-genesis-data.tar.gz" ]; then
            tar -xzvf el-cl-genesis-data.tar.gz || handle_error "Failed to unpack genesis data"
        else
            handle_error "Genesis data archive (el-cl-genesis-data.tar.gz) not found"
        fi
    fi
    
    log_info "Initializing geth execution client..."
    docker run \
      --rm \
      -v "$(pwd)/execution-data:/execution-data" \
      -v "$(pwd)/el-cl-genesis-data:/el-cl-genesis-data" \
      ethereum/client-go:v1.13.4 \
      --state.scheme=hash \
      --datadir=/execution-data \
      init \
      /el-cl-genesis-data/custom_config_data/genesis.json || handle_error "Failed to initialize execution client"
    
    log_success "Execution layer initialized successfully"
}

# Function to generate validator keys
generate_keys() {
    log_info "Generating validator keys..."
    
    # Get withdrawal address from user
    read -rp "$(echo -e "${BLUE}[INPUT]${RESET} Enter your ETH withdrawal address: ")" WITHDRAWAL_ADDRESS
    
    if [ -z "$WITHDRAWAL_ADDRESS" ]; then
        handle_error "Withdrawal address is required"
    fi
    
    # Generate keys using the deposit CLI
    ./bin/blocx-deposit-cli new-mnemonic --eth1_withdrawal_address "$WITHDRAWAL_ADDRESS" || handle_error "Failed to generate keys"
    
    log_success "Keys generated successfully"
    
    # Move keys to proper location
    log_info "Moving keys to proper location..."
    mkdir -p keys/validator_keys el-cl-genesis-data/jwt
    cp -rf validator_keys/* keys/validator_keys || handle_error "Failed to copy validator keys"
    
    log_success "Keys moved successfully"
}

# Function to generate keystore secrets
generate_keystore_secrets() {
    log_info "Generating keystore secrets..."
    
    # Get password from user
    read -rp "$(echo -e "${BLUE}[INPUT]${RESET} Enter password used during mnemonic generation: ")" PASSWORD
    
    if [ -z "$PASSWORD" ]; then
        handle_error "Password is required"
    fi
    
    # Generate keystore secrets
    python3 generate_keys.py --password "$PASSWORD" || handle_error "Failed to generate keystore secrets"
    
    log_success "Keystore secrets generated successfully"
}

# Function to set fee recipient
set_fee_recipient() {
    log_info "Setting fee recipient address..."
    
    # Get fee recipient address from user
    read -rp "$(echo -e "${BLUE}[INPUT]${RESET} Enter your ETH fee recipient address: ")" FEE_RECIPIENT
    
    if [ -z "$FEE_RECIPIENT" ]; then
        handle_error "Fee recipient address is required"
    fi
    
    # Export fee recipient for the docker compose file
    export FEE_RECIPIENT="$FEE_RECIPIENT"
    
    # Save it to a file for persistence
    echo "export FEE_RECIPIENT=$FEE_RECIPIENT" > .env
    
    log_success "Fee recipient set to: $FEE_RECIPIENT"
}

# Function to start the validator node
start_validator_node() {
    log_info "Starting validator node..."
    
    # Get IP address or use default
    read -rp "$(echo -e "${BLUE}[INPUT]${RESET} Enter your server's public IP address (leave blank for auto-detect): ")" IP_ADDRESS
    
    if [ -z "$IP_ADDRESS" ]; then
        IP_ADDRESS=$(curl -s https://ipinfo.io/ip)
        log_info "Using auto-detected IP: $IP_ADDRESS"
    fi
    
    # Export IP for the docker compose file
    export IP_ADDRESS="$IP_ADDRESS"
    
    # Define default bootnodes
    STATIC_EL_BOOTNODES=(
        "enode://378d074d9041983bc58950253a3e02694b9ae59f7a8f332c37e018e385f83ce9f2409f689ccd22af995d888ab38d1c4101b9dcf7f10d1ea5a84a315d2243c146@209.145.57.126:30303"
        "enode://a1da3ead2f3e553939b8cc748a8c93d7e08d8353d403c3d9eeb0b5f738bf5b9f151561a6536a70dd865f6c1fe0ab66e72e243b8e5cb3d49b32b4378a96cca928@209.126.0.162:30303"
        "enode://8a33188e594a9dc0b178d93f1a6909a19623581c087d4c1d9ead1173df69a63acc0128df17b3f0909b929a27420b47f9429546380a16444fa3c48961d6ef0ac6@161.97.156.81:30303"
        "enode://e3bed860ac9336e47856b4d76f239b860da61edc319ad9e20853f925b05c5816c734f98eaaa84fca647cacae7f86e526f979d4d879b50ce8c8c89ddff02770c2@178.18.248.45:30303"
        "enode://08c09e4c923f90f2416d840eb1a8c1125e70ac9de24cc77a1f99392d439da9f0574b730478497ce68841423638206219e5cf27992b6f94e29cfc040eae5bdd36@65.20.108.189:30303"
    )

    STATIC_CL_BOOTNODES=(
        "enr:-MS4QBk-L-MpPuqfyNwYovIeqTBikWd6vU9E7DPCNgo4IB3hIu8uYe5ivuiAbSEtyhlnhTYPwZqpf7rp5FC4L6-uMi9Fh2F0dG5ldHOI__________-EZXRoMpBkeKqeUAAAAf_JmjsAAAAAgmlkgnY0gmlwhNGROX6EcXVpY4IjKYlzZWNwMjU2azGhApQnZwoBeP2IcxTsLjaURKxGAf4Ygw7ZEOBDxo4osc1LiHN5bmNuZXRzD4N0Y3CCIyiDdWRwgiMo"
        "enr:-MS4QP8ZkC2oYF6qrQVXo2zayqMIfNyGfI9wI2NiuT8K6NkuMwC-k5jLssKKfq9EUlbfJNmv4iJLWGvBJxcnuAZEp0pFh2F0dG5ldHOI__________-EZXRoMpBkeKqeUAAAAf_JmjsAAAAAgmlkgnY0gmlwhNF-AKKEcXVpY4IjKYlzZWNwMjU2azGhAh-KPeRLwYhhon2zT-GdEuVu2QjVen9m1GqM_KB9AnP1iHN5bmNuZXRzD4N0Y3CCIyiDdWRwgiMo"
        "enr:-MS4QI5h6K7PpozTlDPjPu6bVxxoTgI_u--vPqFBbFPkV75NBeVabima9QhFdH66A3sDa5OlXT4vqRuj1WJCHobbY8dFh2F0dG5ldHOI__________-EZXRoMpBkeKqeUAAAAf_JmjsAAAAAgmlkgnY0gmlwhKFhnFGEcXVpY4IjKYlzZWNwMjU2azGhAzwv-_IlJ3FU1IisE8hvrDpWZk859feSfuu4FtvSXoSCiHN5bmNuZXRzD4N0Y3CCIyiDdWRwgiMo"
        "enr:-MS4QGCTOnGDuRqQOVc_J9RGXvDu9mj4oRIiZALj7VRNuXn7WN8PDByc9GNJmOb2-cByyXmjpOHwo_u9iN0MmJ6qRApFh2F0dG5ldHOI__________-EZXRoMpBkeKqeUAAAAf_JmjsAAAAAgmlkgnY0gmlwhLIS-C2EcXVpY4IjKYlzZWNwMjU2azGhAzcSo4SLTe-NgUaBicZeUiWyBkGCqQ3qPIizEC_MXvVFiHN5bmNuZXRzD4N0Y3CCIyiDdWRwgiMo"
        "enr:-MS4QOrRTECzxsKpyAAsx6KPTFTE6Ji7PWs-HNxEa-rfnFx2FL-09MJNGvvcwtnNiotN8e-wanUql3OoQAWs-HRMjiNFh2F0dG5ldHOI__________-EZXRoMpBkeKqeUAAAAf_JmjsAAAAAgmlkgnY0gmlwhEEUbL2EcXVpY4IjKYlzZWNwMjU2azGhA30b0glGo9cnMZJzvB9JSv54LuVLj2V2XM1iNdAh0sW_iHN5bmNuZXRzD4N0Y3CCIyiDdWRwgiMo"
    )

    STATIC_CL_TRUSTPEERS=(
        "16Uiu2HAm5Q1AeAfNuwaBaVqvxRM8L1bXf7gjQiURPHvyCmzqWyDC"
        "16Uiu2HAkwYnt1kNmK8iP9K9cUigddJfjgVKcBeSK6yJVJzJmdFrc"
        "16Uiu2HAmGhwFT2F8UkhLarvvvA8CGXBa1SmHYAT7yrwaRCVdKNKj"
        "16Uiu2HAmGMyFvqzWATNuQahhkEDkfaCeyc6qmNKLkt4r9zz9VN3W"
        "16Uiu2HAmM5MvAPAq64SrpW9c2uzAxYXHADeg32hwmCHQmhFh9hCa"
    )
    STATIC_CL_CHECKPOINTS=("https://checkpointz.blocxscan.com/")
    
    # Export environment variables
    export EL_BOOTNODES=$(IFS=, ; echo "${STATIC_EL_BOOTNODES[*]}")
    export CL_BOOTNODES=$(IFS=, ; echo "${STATIC_CL_BOOTNODES[*]}")
    export CL_TRUSTPEERS=$(IFS=, ; echo "${STATIC_CL_TRUSTPEERS[*]}")
    export CL_CHECKPOINT=$(IFS=, ; echo "${STATIC_CL_CHECKPOINTS[0]}")
    export CHAIN_ID=9090
    
    echo "export EL_BOOTNODES=$EL_BOOTNODES" #>> .env
    echo "export CL_BOOTNODES=$CL_BOOTNODES" #>> .env
    echo "export CL_TRUSTPEERS=$CL_TRUSTPEERS" #>> .env
    echo "export CL_CHECKPOINT=$CL_CHECKPOINT" #>> .env
    echo "export CHAIN_ID=$CHAIN_ID" #>> .env
    
    # Generate JWT secret if it doesn't exist
    if [ ! -f "el-cl-genesis-data/jwt/jwtsecret" ]; then
        log_info "Generating JWT secret..."
        openssl rand -hex 32 > "el-cl-genesis-data/jwt/jwtsecret" || handle_error "Failed to generate JWT secret"
    fi
    
    # Start the validator node
    log_info "Starting docker compose..."
    docker compose -f compose-validator.yaml up -d || handle_error "Failed to start validator node"
    
    log_success "Validator node started successfully"
    log_info "You can check logs with: docker compose -f compose-validator.yaml logs -f"
}

# Function to stop the validator node
stop_validator_node() {
    log_info "Stopping validator node..."
    docker compose -f compose-validator.yaml down || handle_error "Failed to stop validator node"
    log_success "Validator node stopped successfully"
}

# Function to shut down the validator node (same as stop but with clear messaging)
down_node() {
    log_info "Shutting down validator node..."
    docker compose -f compose-validator.yaml down || handle_error "Failed to shut down validator node"
    log_success "Validator node shut down successfully"
}

# Function to clean up all node data
clean_node() {
    log_warning "⚠️  WARNING: This will delete all node data and you will need to sync from scratch ⚠️"
    log_warning "This operation cannot be undone!"
    read -rp "$(echo -e "${RED}[CAUTION]${RESET} Are you sure you want to proceed? (y/N): ")" confirm
    
    confirm=$(echo "$confirm" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    if [[ "$confirm" != "y" ]]; then
        log_info "Cleanup cancelled"
        return
    fi
    
    # Stop the node first
    down_node
    
    log_info "Cleaning up node data..."
    
    # Remove data directories
    sudo rm -rf execution-data
    sudo rm -rf consensus-data
    sudo rm -rf el-cl-genesis-data
    
    # Clean validator keys (but preserve the original keys)
    sudo rm -rf keys/validator_keys/logs
    sudo rm -rf keys/validator_keys/slashing_protection.sqlite
    sudo rm -rf keys/validator_keys/slashing_protection.sqlite-journal
    sudo rm -rf keys/validator_keys/.secp-sk
    sudo rm -rf keys/validator_keys/api-token.txt
    
    log_success "Cleanup complete. You will need to reinitialize the node before starting it again."
}

# Function to show node status
show_status() {
    log_info "Checking node status..."
    docker compose -f compose-validator.yaml ps
    
    # Check if execution and beacon nodes are syncing
    log_info "Checking execution client sync status..."
    curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545 | jq
    
    log_info "Checking beacon node sync status..."
    curl -s -X GET http://localhost:5052/eth/v1/node/syncing | jq
}

# Main menu function
show_menu() {
    echo -e "${YELLOW}╔════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}║     BLOCX Validator Node Setup Tool    ║${RESET}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${RESET}"
    echo -e "${BLUE}Please select an option:${RESET}"
    echo "1. Complete setup (Steps 1-6)"
    echo "2. Initialize node only (Step 1)"
    echo "3. Generate validator keys (Step 2)"
    echo "4. Generate keystore secrets (Step 4)"
    echo "5. Set fee recipient address (Step 5)"
    echo "6. Start validator node (Step 6)"
    echo "7. Stop validator node"
    echo "8. Shutdown validator node"
    echo -e "9. Cleanup validator node ${YELLOW}(Will delete all data!)${RESET}"
    echo "10. Check node status"
    echo "11. Exit"
    echo ""
    read -rp "$(echo -e "${BLUE}[INPUT]${RESET} Enter your choice (1-11): ")" choice
    
    case $choice in
        1)
            initialize_node
            generate_keys
            generate_keystore_secrets
            set_fee_recipient
            start_validator_node
            ;;
        2)
            initialize_node
            ;;
        3)
            generate_keys
            ;;
        4)
            generate_keystore_secrets
            ;;
        5)
            set_fee_recipient
            ;;
        6)
            start_validator_node
            ;;
        7)
            stop_validator_node
            ;;
        8)
            down_node
            ;;
        9)
            clean_node
            ;;
        10)
            show_status
            ;;
        11)
            log_info "Exiting script. Goodbye!"
            exit 0
            ;;
        *)
            log_warning "Invalid choice. Please try again."
            ;;
    esac
}

# Display important information at startup
clear
log_info "Welcome to the BLOCX Validator Node Setup Tool"
log_info "This script will guide you through setting up a BLOCX validator node."
log_info "Make sure you have run ./docker-setup.sh first to install dependencies."
echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${RED}║                               ⚠️  WARNING ⚠️                                ║${RESET}"
echo -e "${RED}║ IMPORTANT: Before submitting your deposit.json file to the staking        ║${RESET}"
echo -e "${RED}║ launchpad, ensure your node is FULLY SYNCED with the network.             ║${RESET}"
echo -e "${RED}║ Otherwise, you may receive penalties.                                     ║${RESET}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Load environment variables if they exist
if [ -f ".env" ]; then
    source .env
fi

# Main loop
while true; do
    show_menu
    echo ""
    read -rp "$(echo -e "${BLUE}[INPUT]${RESET} Press Enter to continue...")" dummy
    clear
done
