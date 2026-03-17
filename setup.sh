#!/bin/bash
# ==============================================================================
# KOMODO DEPLOYMENT SCRIPT
# ==============================================================================
# This script automates the deployment of Komodo Core and Periphery.
# Designed for read-only systems (like TrueNAS SCALE) using a bundled GH CLI.
#
# WORKFLOW OPTIONS:
#
# 1. INTERACTIVE (No token needed):
#    $ ./deploy.sh setup    --> Starts Device Code login (browser based).
#    $ ./deploy.sh all      --> Clones/Updates repos and WIPES credentials.
#
# 2. AUTOMATED (Using GH_TOKEN):
#    $ export GH_TOKEN=ghp_your_secret_token
#    $ ./deploy.sh all      --> GH CLI will use the token automatically.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e 

# --- Configuration ---
ORG_NAME="docker-workflows"
BRANCH="prod"
DIR_CORE="komodo-core"
DIR_PERIPHERY="komodo-periphery"

# Dynamically find where this script is located to call the bundled 'gh' binary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GH="${SCRIPT_DIR}/gh"

# Temporary directory for session credentials (destroyed after use)
export GH_CONFIG_DIR="/tmp/komodo-gh-config"
export GIT_CONFIG_GLOBAL="${GH_CONFIG_DIR}/gitconfig"

# --- Functions ---

show_help() {
    echo "Usage: ./deploy.sh [command]"
    echo ""
    echo "Commands:"
    echo "  setup       [Step 1] Login interactively via Device Code"
    echo "  all         [Step 2] Sync all repos and WIPE credentials"
    echo "  core        Sync Komodo Core repository"
    echo "  periphery   Sync Komodo Periphery repository"
    echo "  status      Check local directory status"
    echo "  clean-auth  Manually remove GH session credentials from /tmp"
}

setup() {
    mkdir -p "${GH_CONFIG_DIR}"
    chmod +x "${GH}" # Ensure the binary is executable
    
    if [ -z "$GH_TOKEN" ]; then
        echo ">>> Starting interactive login (Device Code)..."
        "${GH}" auth login --hostname github.com -p https -w
    else
        echo ">>> GH_TOKEN detected, skipping interactive login."
    fi
    
    # Setup git credential helper using the isolated configuration
    "${GH}" auth setup-git
}

clean_auth() {
    echo ">>> Wiping temporary session credentials..."
    rm -rf "${GH_CONFIG_DIR}"
    echo ">>> Done. System is clean."
}

sync_repo() {
    local REPO_NAME=$1
    
    if [ ! -f "${GH}" ]; then 
        echo "Error: gh binary not found in ${SCRIPT_DIR}."
        exit 1
    fi
    
    if [ ! -d "${REPO_NAME}/.git" ]; then
        echo "Cloning private repository ${REPO_NAME}..."
        "${GH}" repo clone "${ORG_NAME}/${REPO_NAME}" "${REPO_NAME}" -- --branch "${BRANCH}"
    else
        echo "Local repository ${REPO_NAME} found. Forcing update..."
        cd "${REPO_NAME}"
        git fetch origin "${BRANCH}"
        git reset --hard "origin/${BRANCH}"
        cd ..
    fi

    # Environment file setup
    if [ -f "${REPO_NAME}/.env.${BRANCH}" ]; then
        echo "Applying configuration: .env.${BRANCH} -> .env"
        cp "${REPO_NAME}/.env.${BRANCH}" "${REPO_NAME}/.env"
    fi
    echo ">>> Finished: ${REPO_NAME}"
    echo ""
}

status_check() {
    echo "--- Local Status ---"
    [ -d "${DIR_CORE}" ] && echo "[OK] Core folder exists" || echo "[..] Core folder missing"
    [ -d "${DIR_PERIPHERY}" ] && echo "[OK] Periphery folder exists" || echo "[..] Periphery folder missing"
}

# --- Main Logic Route ---
case "$1" in
    setup)
        setup
        ;;
    all)
        sync_repo "${DIR_CORE}"
        sync_repo "${DIR_PERIPHERY}"
        clean_auth
        ;;
    core)
        sync_repo "${DIR_CORE}"
        ;;
    periphery)
        sync_repo "${DIR_PERIPHERY}"
        ;;
    status)
        status_check
        ;;
    clean-auth)
        clean_auth
        ;;
    *)
        show_help
        ;;
esac