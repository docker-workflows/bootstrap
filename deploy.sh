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
#GITBRANCH="main"

# Capture arguments
COMMAND="${1:?}"
if [[ "${COMMAND}" == run* ]]; then
	MODE="${2:?}"
else
	MODE=""
fi

# Path initialization
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GH_BINARY=$(find "${SCRIPTDIR}" -type f -path "*/gh_*_linux_amd64*/gh" | head -n 1)

# Temporary directory for session credentials
export GH_CONFIG_DIR="/tmp/komodo-gh-config"
export GIT_CONFIG_GLOBAL="${GH_CONFIG_DIR}/gitconfig"


show_help() {
	echo "Usage: ./deploy.sh command [mode]"
	echo ""
	echo "Commands:"
	echo "  login                   Interactive login to Github via Device Code"
	echo "  logout                  Remove GH session credentials"
	echo "  install-core            Install Komodo Core"
	echo "  install-periphery       Install Komodo Periphery"
	echo "  run-core                Run Komodo Core via Docker Compose, 'mode' parameter mandatory.""
	echo "  run-periphery           Run Komodo Periphery via Docker Compose, 'mode' parameter mandatory.""
	echo "  stop-core               Stop Core containers"
	echo "  stop-periphery          Stop Periphery containers"
	echo ""
	echo "Examples:"
	echo "  ./deploy.sh login"
	echo "  ./deploy.sh install-core prod"
	echo "  ./deploy.sh install-periphery dev"
	echo "  ./deploy.sh run-core"
}

check_gh_binary() {
	if [ -z "${GH_BINARY}" ] || [ ! -f "${GH_BINARY}" ]; then 
		printf "[ERRO]\t Binary 'gh' not found.\n"
		exit 1
	fi
	# Ensure the binary is executable
	chmod +x "${GH_BINARY}"
}

github_login() {
	check_gh_binary

	if [ ! -v "GH_TOKEN" ]; then
		printf "[INFO]\t\t Starting interactive login.\n"
		"${GH_BINARY}" auth login --hostname github.com --git-protocol https --web
	else
		printf "[INFO]\t Detected 'GH_TOKEN', skipping interactive login.\n"
	fi
	
	"${GH_BINARY}" auth setup-git

	return 0
}

github_logout() {
	printf "[INFO]\t Cleaning GH session credentials.\n"
	rm -rf "${GH_CONFIG_DIR}" > /dev/null

	return 0
}

sync_repo() {
	local REPO_NAME=$1

	check_gh_binary
	
	if [ ! -d "${REPO_NAME}/.git" ]; then
		printf "[INFO]\t Cloning private repository '%s'.\n" ${REPO_NAME} 
		"${GH_BINARY}" repo clone "${ORGNAME}/${REPO_NAME}" "${REPO_NAME}" -- --branch "${GITBRANCH:-main}" > /dev/null 2>&1
		pushd "${REPO_NAME}" > /dev/null
		git submodule update --init --recursive > /dev/null 2>&1
		popd > /dev/null
	else
		printf "[INFO]\t Local repository '%s' found. Forcing update.\n" ${REPO_NAME}
		pushd "${REPO_NAME}" > /dev/null
		git fetch origin "${GITBRANCH:-main}" > /dev/null 2>&1
		git reset --hard "origin/${GITBRANCH:-main}" > /dev/null 2>&1
		git submodule update --init --recursive > /dev/null 2>&1
		popd > /dev/null
	fi

	# Environment file setup using MODE
	#if [ -f "${REPO_NAME}/.env.${MODE}" ]; then
	#	printf "[INFO]\t Applying configuration: .env.%s -> .env\n" ${MODE}
	#	ln -sf "./.env.${MODE}" "${REPO_NAME}/.env" > /dev/null
	#else
	#	printf "[WARN]\t .env.%s not found in '%s'.\n" ${MODE} ${REPO_NAME}
	#	return 0
	#fi

	printf "[INFO]\t Repository '%s' successfully cloned.\n" ${REPO_NAME} 
	return 0
}

case "$COMMAND" in
	login)
		github_login
		;;
	logout)
		github_logout
		;;
	install-core)
		sync_repo "${COMMONDIR}"
		sync_repo "${COREDIR}"
		;;
	install-periphery)
		sync_repo "${COMMONDIR}"
		sync_repo "${PERIPHERYDIR}"
		;;
	run-core)
		printf "Deployment Mode: %s.\n" ${MODE^^}
		pushd "${COREDIR}" > /dev/null
		if [[ -f "./predeploy.sh" ]]; then
			bash ./predeploy.sh "${MODE}"
		fi
		docker compose up -d
		if [[ -f "./postdeploy.sh" ]]; then
			bash ./postdeploy.sh "${MODE}"
		fi
		popd > /dev/null
		;;
	run-periphery)
		printf "Deployment Mode: %s.\n" ${MODE^^}
		pushd "${PERIPHERYDIR}" > /dev/null
		if [[ -f "./predeploy.sh" ]]; then
			bash ./predeploy.sh "${MODE}"
		fi
		docker compose up -d
		if [[ -f "./postdeploy.sh" ]]; then
			bash ./postdeploy.sh "${MODE}"
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
	*)
		show_help
		;;
esac