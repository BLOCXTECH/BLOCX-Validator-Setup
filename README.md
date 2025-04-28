# BLOCX Validator Node Setup Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Hardware Requirements](#hardware-requirements)
4. [Installation Process](#installation-process)
   - [Step 1: System Preparation](#step-1-system-preparation)
   - [Step 2: Initializing the Node](#step-2-initializing-the-node)
   - [Step 3: Generating Validator Keys](#step-3-generating-validator-keys)
   - [Step 4: Creating Keystore Secrets](#step-4-creating-keystore-secrets)
   - [Step 5: Setting Fee Recipient](#step-5-setting-fee-recipient)
   - [Step 6: Starting the Validator Node](#step-6-starting-the-validator-node)
5. [Monitoring Your Node](#monitoring-your-node)
6. [Node Maintenance](#node-maintenance)
   - [Stopping the Node](#stopping-the-node)
   - [Shutting Down the Node](#shutting-down-the-node)
   - [Cleaning Up Node Data](#cleaning-up-node-data)
7. [Depositing Stake](#depositing-stake)
8. [Troubleshooting](#troubleshooting)
   - [Common Errors and Solutions](#common-errors-and-solutions)
   - [Sync Issues](#sync-issues)
   - [Connection Problems](#connection-problems)
9. [FAQ](#faq)
10. [Support](#support)

## Introduction

This guide provides detailed instructions for setting up and maintaining a BLOCX validator node. BLOCX uses a Proof of Stake (PoS) consensus mechanism, where validators are responsible for proposing and validating blocks on the blockchain.

By running a validator node, you contribute to the security and decentralization of the BLOCX network while earning rewards for your participation.

> **Note**: Running a validator node requires technical knowledge and a commitment to maintaining the node's uptime and security.

## Prerequisites

Before setting up your validator node, ensure you have:

- A Linux server (Ubuntu 20.04 LTS or later recommended)
- Root or sudo access to the server
- Stable internet connection with minimum 10 Mbps upload/download
- Dedicated IP address
- Basic knowledge of command line and Linux administration
- The required amount of BLOCX tokens for staking

## Hardware Requirements

For optimal performance of your validator node, we recommend:

| Component | Minimum    | Recommended    |
| --------- | ---------- | -------------- |
| CPU       | 4 cores    | 8+ cores       |
| RAM       | 8 GB       | 16+ GB         |
| Storage   | 500 GB SSD | 1 TB+ NVMe SSD |
| Network   | 10 Mbps    | 25+ Mbps       |

> **Important**: Storage requirements will grow over time as the blockchain expands. Plan for future expansion.

## Installation Process

### Step 1: System Preparation

1. Update your system:

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Install Docker and other dependencies:

   ```bash
   git clone https://github.com/BLOCXTECH/BLOCX-Validator-Setup.git
   cd BLOCX-Validator-Setup
   chmod +x *.sh
   ./docker-setup.sh
   ```

   This script will install Docker, Docker Compose, and other required dependencies.

### Automatic setup
- If you want to do entire thing automatically select option 1 while running
   ```bash
   ./initExecution.sh
   ```
- If you select automatic setup you can skip rest of the steps

### Step 2: Initializing the Node

1. Run the setup script with the "Initialize node only" option:

   ```bash
   ./initExecution.sh
   ```

   Choose option 2 from the menu.

2. The script will unpack the genesis data (if necessary) and initialize the execution client.

3. This process may take several minutes to complete.

### Step 3: Generating Validator Keys

1. From the setup script menu, select option 3 "Generate validator keys".

2. You will be prompted to enter your ETH/BLOCX withdrawal address. This is the address where your staking rewards will be sent if you exit the validator.

   ```bash
   [INPUT] Enter your ETH/BLOCX withdrawal address: 0xYOUR_ETHEREUM_ADDRESS
   ```

   > **CRITICAL**: Ensure this address is correct and that you have access to it. Once set, it CANNOT be changed!

3. Follow the prompts to create a new mnemonic phrase.

   > **CRITICAL**: Record your mnemonic phrase securely! This is your only recovery option if you lose your validator keys.

4. The script will generate your validator keys and move them to the appropriate location.

### Step 4: Creating Keystore Secrets

1. From the setup script menu, select option 4 "Generate keystore secrets".

2. Enter the password you used during the mnemonic generation:

   ```bash
   [INPUT] Enter password used during mnemonic generation: your_password_here
   ```

   > **Important**: This password will be required whenever you need to operate your validator. Store it securely.

### Step 5: Setting Fee Recipient

1. From the setup script menu, select option 5 "Set fee recipient address".

2. Enter your ETH/BLOCX address that will receive transaction fees:

   ```bash
   [INPUT] Enter your ETH/BLOCX fee recipient address: 0xYOUR_FEE_RECIPIENT_ADDRESS
   ```

   This address can be the same as your withdrawal address or a different one.

### Step 6: Starting the Validator Node

1. From the setup script menu, select option 6 "Start validator node".

2. You'll be prompted to enter your server's public IP address or leave it blank for auto-detection:

   ```bash
   [INPUT] Enter your server's public IP address (leave blank for auto-detect):
   ```

3. The script will start the validator node using Docker Compose.

4. Wait for the node to start syncing with the network.

## Monitoring Your Node

1. Check your node's status by selecting option 10 "Check node status" from the menu.

2. You can also view the logs directly with:

   ```bash
   docker compose -f compose-validator.yaml logs -f
   ```

3. To view logs for a specific service:

   ```bash
   docker compose -f compose-validator.yaml logs -f execution
   docker compose -f compose-validator.yaml logs -f beacon
   docker compose -f compose-validator.yaml logs -f validator
   ```

4. To monitor sync progress, you can use these commands:

   ```bash
   # For beacon node sync progress
   curl -s -X GET http://localhost:5052/eth/v1/node/syncing | jq
   ```

## Node Maintenance

### Stopping the Node

1. To temporarily stop your validator node, select option 7 "Stop validator node" from the menu.
2. This will stop all containers but preserve your data.
3. You can start the node again using option 6.

### Shutting Down the Node

1. Select option 8 "Shutdown validator node" from the menu to shut down your node.
2. This effectively does the same as stopping but is used when you want to emphasize a full shutdown.

### Cleaning Up Node Data

1. Select option 9 "Cleanup validator node" from the menu to completely remove all node data.

   > ⚠️ **WARNING**: This will delete all blockchain data and you will need to sync from scratch again! This operation cannot be undone.

2. Your validator keys will be preserved, but all sync progress and blockchain data will be deleted.

3. After cleaning, you will need to reinitialize the node before starting it again.

## Depositing Stake

After your node is fully synced with the network, you can deposit your stake to activate your validator:

1. Ensure your node is running and fully synced with the network.

   > ⚠️ **CRITICAL WARNING**: Do NOT deposit your stake before your node is fully synced! If your validator gets activated while your node is not synced, you may receive penalties.

2. Go to the staking launchpad at [https://launchpad.blocxscan.com/](https://launchpad.blocxscan.com/).

3. Follow the instructions on the launchpad to upload your `deposit.json` file and complete your deposit.

4. Wait for your validator to be activated. This can take from several hours to several days depending on the validator activation queue.

## Troubleshooting

### Common Errors and Solutions

#### Error: "Failed to initialize execution client"

**Symptoms**:

- Error message during initialization
- Node fails to start

**Solutions**:

1. Ensure genesis data is present:

   ```bash
   ls -la el-cl-genesis-data
   ```

2. Try unpacking the genesis data again:

   ```bash
   tar -xzvf el-cl-genesis-data.tar.gz
   ```

3. Try running the initialization again (option 2 in the menu).

#### Error: "Failed to start validator node"

**Symptoms**:

- Node containers fail to start
- Docker Compose error messages

**Solutions**:

1. Check for port conflicts:

   ```bash
   sudo netstat -tulpn | grep -E '8545|5052|9000|30303'
   ```

2. Ensure Docker is running:

   ```bash
   sudo systemctl status docker
   ```

3. Check Docker Compose logs:

   ```bash
   docker compose -f compose-validator.yaml logs
   ```

### Sync Issues

#### Problem: Node is not syncing or syncing extremely slowly

**Symptoms**:

- No peers are connected
- Sync progress is stalled
- Progress percentage not increasing

**Solutions**:

1. Check your internet connection:

   ```bash
   ping -c 5 google.com
   ```

2. Verify DNS resolution:

   ```bash
   nslookup google.com
   ```

3. Ensure ports are open on your firewall:

   ```bash
   sudo ufw status
   ```

4. Restart the node:

   ```bash
   docker compose -f compose-validator.yaml down
   docker compose -f compose-validator.yaml up -d
   ```

### Connection Problems

#### Problem: Cannot connect to peers

**Symptoms**:

- Low peer count
- Connection errors in logs

**Solutions**:

1. Check if ports are properly forwarded on your router/firewall.
2. Verify your public IP is correctly configured:

   ```bash
   curl https://ipinfo.io/ip
   ```

3. Ensure your ISP is not blocking peer-to-peer connections.



## Exiting Validator Node

### **Important Considerations Before Exiting**

- **Irreversibility**: Once a validator is exited, it cannot be reactivated. To resume staking, you'd need to generate new validator keys and initiate the staking process anew.

- **Withdrawal Credentials**: Ensure your validator's withdrawal credentials are set to type `0x01`. This setting is necessary for automatic withdrawals. If your credentials are of type `0x00` (BLS), you'll need to update them before exiting.



**Steps to Initiate a Voluntary Exit**

1. Access the Validator Container

First, identify and access your validator container using Docker:


```bash
docker exec -it $(docker ps --filter "name=validator" --format "{{.Names}}") bash
```


This command opens an interactive shell within the validator container.

2. Execute the Voluntary Exit Command

Within the container, run the following command to initiate the voluntary exit:


```bash
lighthouse account validator exit --keystore /validator_keys --beacon-node http://beacon:5052
```


Upon execution, you'll be prompted to enter the password associated with your keystore. After successful authentication, the voluntary exit message will be broadcasted to the network.


Verifying the Exit Status

To monitor the status of your validator's exit, you can use [beacon.blocxscan.com](http://beacon.blocxscan.com/)

1. Navigate to [https://beacon.blocxscan.com/](https://beacon.blocxscan.com/).

2. Enter your validator's public key or index in the search bar.

3. Review the validator's status to confirm the exit process.


## FAQ

### Q: How long does it take for my node to sync?

**A:** Initial sync can take anywhere from a few hours to several days depending on your hardware and network connection.

### Q: When will I start earning rewards?

**A:** You will start earning rewards after:

1. Your node is fully synced
2. You've deposited your stake
3. Your validator has been activated (which can take several days)

### Q: How can I check if my validator is active?

**A:** Visit the BLOCX Explorer at [https://beacon.blocxscan.com/validators](https://beacon.blocxscan.com/validators) and search for your validator index or public key.

### Q: What should I do if I need to move my validator to a different machine?

**A:**

1. Back up your validator keys
2. Stop the validator on the old machine
3. Set up the new machine
4. Copy your keys to the new machine
5. Start the validator on the new machine

### Q: What happens if my node goes offline?

**A:** You will incur small penalties while offline. These penalties are designed to be approximately equal to the rewards you would have earned, so you'll stop earning but not lose your principal as long as you get back online in a reasonable timeframe.

## Support

If you encounter issues not covered in this guide:

1. Check the BLOCX community Discord for help
2. Open an issue on the GitHub repository

---

Remember that running a validator comes with responsibility. Keep your node updated, secure, and online to maximize your rewards and contribute to the BLOCX network.
