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

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GH_BINARY=$(find "${SCRIPTDIR}" -type f -path "*/gh_*_linux_amd64*/gh" | head -n 1)

# Temporary directory for session credentials (destroyed after use)
export GH_CONFIG_DIR="/tmp/komodo-gh-config"
export GIT_CONFIG_GLOBAL="${GH_CONFIG_DIR}/gitconfig"

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
	if [ -z "${GH_BINARY}" ] || [ ! -f "${GH_BINARY}" ]; then 
		printf "[ERROR.....] Binary 'gh' not found.\n"
		exit 1
	fi
	# Ensure the binary is executable
	chmod +x "${GH_BINARY}"
}

github_login() {
	check_gh_binary

	if [ -z "$GH_TOKEN" ]; then
		printf "[INFO......] Starting interactive login.\n"
		"${GH_BINARY}" auth login --hostname github.com --git-protocol https --web
	else
		printf "[INFO......] Detected 'GH_TOKEN', skipping interactive login.\n"
	fi
	
	"${GH_BINARY}" auth setup-git

	return 0
}

github_logout() {
	printf "[INFO......] Cleaning GH session credentials.\n"
	rm -rf "${GH_CONFIG_DIR}" > /dev/null

	return 0
}

sync_repo() {
	local REPO_NAME=$1

	check_gh_binary
	
	if [ ! -d "${REPO_NAME}/.git" ]; then
		printf "[INFO......] Cloning private repository '%s'.\n" ${REPO_NAME} 
		"${GH_BINARY}" repo clone "${ORGNAME}/${REPO_NAME}" "${REPO_NAME}" > /dev/null
		pushd "${REPO_NAME}" > /dev/null
		git submodule update --init --recursive > /dev/null
		popd > /dev/null
	else
		printf "[INFO......] Local repository '%s' found. Forcing update.\n" ${REPO_NAME}
		pushd "${REPO_NAME}" > /dev/null
		git fetch origin "${GITBRANCH}" > /dev/null
		git reset --hard "origin/${GITBRANCH}" > /dev/null
		git submodule update --init --recursive > /dev/null
		popd > /dev/null
	fi

	# Environment file setup using MODE
	if [ -f "${REPO_NAME}/.env.${MODE}" ]; then
		printf "[INFO......] Applying configuration: .env.%s -> .env\n" ${MODE}
		ln -sf "./.env.${MODE}" "${REPO_NAME}/.env" > /dev/null
	else
		printf "[WARNING...] .env.%s not found in '%s'.\n" ${MODE} ${REPO_NAME}
		return 1
	fi

	printf "[INFO......] Repository '%s' successfully cloned.\n" ${REPO_NAME} 
	return 0
}

status_check() {
	printf "[INFO......] Status:\n"
	if [[ -d "${COMMONDIR}" ]]; then
		printf "[OK........] Common folder exists.\n"
	else
		printf "[ERROR.....] Common folder missing.\n"
	fi
	if [[ -d "${COREDIR}" ]]; then
		printf "[OK........] Komodo Core folder exists.\n"
	else
		printf "[ERROR.....] Komodo Core folder missing.\n"
	fi
	if [[ -d "${PERIPHERYDIR}" ]]; then
		printf "[OK........] Komodo Periphery folder exists.\n"
	else
		printf "[ERROR.....] Komodo Periphery folder missing.\n"
	fi

	return 0
}


case "$COMMAND" in
	login)
		github_login
		;;
	logout)
		github_logout
		;;
	install-all)
		printf "Deployment Mode: %s.\n" ${MODE^^}
		sync_repo "${COMMONDIR}"
		sync_repo "${COREDIR}"
		sync_repo "${PERIPHERYDIR}"
		;;
	install-core)
		printf "Deployment Mode: %s.\n" ${MODE^^}
		sync_repo "${COREDIR}"
		;;
	install-periphery)
		printf "Deployment Mode: %s.\n" ${MODE^^}
		sync_repo "${PERIPHERYDIR}"
		;;
	run-core)
		pushd "${COREDIR}" > /dev/null
		if [[ -f "./predeploy.sh" ]]; then
			bash ./predeploy.sh -b "${MODE}"
		fi
		docker compose up -d
		if [[ -f "./postdeploy.sh" ]]; then
			bash ./postdeploy.sh -b "${MODE}"
		fi
		popd > /dev/null
		;;
	run-periphery)
		pushd "${PERIPHERYDIR}" > /dev/null
		if [[ -f "./predeploy.sh" ]]; then
			bash ./predeploy.sh -b "${MODE}"
		fi
		docker compose up -d
		if [[ -f "./postdeploy.sh" ]]; then
			bash ./postdeploy.sh -b "${MODE}"
		fi
		popd > /dev/null
		;;
	stop-core)
		pushd "${COREDIR}" > /dev/null
		docker compose down
		popd > /dev/null
		;;
	stop-periphery)
		pushd "${PERIPHERYDIR}" > /dev/null
		docker compose down
		popd > /dev/null
		;;
	status)
		status_check
		;;
	*)
		show_help
		;;
esac