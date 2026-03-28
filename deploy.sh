#!/bin/bash
# ==============================================================================
# KOMODO DEPLOYMENT SCRIPT (Revisado)
# ==============================================================================
# Automates deployment of Komodo Core, Periphery, and Common Tools
# for read-only systems (TrueNAS SCALE) using bundled GH CLI.
# ==============================================================================

set -euo pipefail

# Configuration
ORGNAME="bonzosoft"
COMMONDIR="common-tools"
COREDIR="komodo-core"
PERIPHERYDIR="komodo-periphery"
GITBRANCH="main"

# Capture arguments
COMMAND="$1"
MODE="${2:-prod}" # Environment mode (prod|dev). Defaults to 'prod'

# Dynamically find where this script is located
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Dynamically find the 'gh' binary inside the gh_..._linux_amd64 folder structure
GH=$(find "${SCRIPTDIR}" -type f -path "*/gh_*_linux_amd64*/gh" | head -n 1)

# Temporary directory for session credentials (destroyed after use)
export GH_CONFIG_DIR="/tmp/komodo-gh-config"
export GIT_CONFIG_GLOBAL="${GH_CONFIG_DIR}/gitconfig"

#
export GH_TOKEN=""

# Functions
show_help() {
    echo "Usage: ./deploy.sh [command] [mode]"
    echo ""
    echo "Commands:"
    echo "  login                   Interactive login to Github via Device Code"
    echo "  logout                  Logout from Github"
    echo "  install-all             Sync ALL repos (common -> core -> periphery) and clean credentials"
    echo "  install-common-tools    Sync Common Tools only"
    echo "  install-core            Sync Komodo Core only"
    echo "  install-periphery       Sync Komodo Periphery only"
    echo "  run-core                Run Komodo Core via Docker Compose"
    echo "  run-periphery           Run Komodo Periphery via Docker Compose"
    echo "  stop-core               Stop Core containers"
    echo "  stop-periphery          Stop Periphery containers"
    echo "  status                  Check local folder status"
    echo "  clean-auth              Remove GH session credentials manually"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh login"
    echo "  ./deploy.sh install-all prod"
    echo "  ./deploy.sh install-core dev"
    echo "  ./deploy.sh run-core"
}

check_gh_binary() {
    if [ -z "${GH}" ] || [ ! -f "${GH}" ]; then 
        echo "[ERROR] 'gh' binary not found. Make sure the gh_*_linux_amd64 folder is in ${SCRIPTDIR}."
        exit 1
    fi
    # Ensure the binary is executable
    chmod +x "${GH}"
}

clean_auth() {
    echo "[INFO ] Cleaning GH session credentials..."
    rm -rf "${GH_CONFIG_DIR}"
}

login() {
    check_gh_binary

    if [ -z "$GH_TOKEN" ]; then
        echo "[INFO ] Starting interactive login (Device Code)..."
        "${GH}" auth login --hostname github.com --git-protocol https --web
    else
        echo "[INFO ] GH_TOKEN detected, skipping interactive login."
    fi
    
    # Setup git credential helper using the isolated configuration
    "${GH}" auth setup-git
}

sync_repo() {
    local REPO_NAME=$1
    check_gh_binary
    
    if [ ! -d "${REPO_NAME}/.git" ]; then
        echo "[INFO ] Cloning private repository ${REPO_NAME}..."
        "${GH}" repo clone "${ORGNAME}/${REPO_NAME}" "${REPO_NAME}" # -- --recurse-submodules
        cd "${REPO_NAME}"
        git submodule update --init --recursive
        cd ..
    else
        echo "[INFO ] Local repository ${REPO_NAME} found. Forcing update..."
        cd "${REPO_NAME}"
        git fetch origin "${GITBRANCH}"
        git reset --hard "origin/${GITBRANCH}"
        git submodule update --init --recursive
        cd ..
    fi

    # Environment file setup using MODE
    if [ -f "${REPO_NAME}/.env.${MODE}" ]; then
        echo "[INFO ] Applying configuration: .env.${MODE} -> .env"
        ln -sf "${REPO_NAME}/.env.${MODE}" "${REPO_NAME}/.env"
    else
        echo "[WARN ]: .env.${MODE} not found in ${REPO_NAME}. Skipping env setup."
    fi
    
    echo "[INFO ] ${REPO_NAME}"
    echo ""
}

status_check() {
    echo "[INFO ] Local Status"
    [ -d "${COMMONDIR}" ] && echo "[OK] Common folder exists" || echo "[. ] Common folder missing"
    [ -d "${COREDIR}" ] && echo "[OK] Core folder exists" || echo "[. ] Core folder missing"
    [ -d "${PERIPHERYDIR}" ] && echo "[OK] Periphery folder exists" || echo "[. ] Periphery folder missing"
}

# Main Logic Route
case "$COMMAND" in
    login)
        login
        ;;
    logout)
        clean_auth
        ;;
    install-all)
        echo "Deployment Mode: ${MODE^^}" # Prints mode in uppercase (e.g., PROD)
        sync_repo "${COMMONDIR}"
        sync_repo "${COREDIR}"
        sync_repo "${PERIPHERYDIR}"
        ;;
    install-common-tools)
        echo "Deployment Mode: ${MODE^^}"
        sync_repo "${COMMONDIR}"
        ;;
    install-core)
        echo "Deployment Mode: ${MODE^^}"
        sync_repo "${COREDIR}"
        ;;
    install-periphery)
        echo "Deployment Mode: ${MODE^^}"
        sync_repo "${PERIPHERYDIR}"
        ;;
    run-core)
        pushd "${COREDIR}"
        bash ./predeploy.sh -b "${MODE}"
        docker compose up -d
        bash ./postdeploy.sh -b "${MODE}"
        popd
        ;;
    run-periphery)
        pushd "${PERIPHERYDIR}"
        bash ./predeploy.sh -b "${MODE}"
        docker compose up -d
        bash ./postdeploy.sh -b "${MODE}"
        popd
        ;;
    stop-core)
        pushd "${COREDIR}"
        docker compose down
        popd
        ;;
    stop-periphery)
        pushd "${PERIPHERYDIR}"
        docker compose down
        popd
        ;;
    status)
        status_check
        ;;
    *)
        show_help
        ;;
esac