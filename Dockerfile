FROM debian:trixie-slim

# ---------------- Versions ----------------
ARG DEBIAN_VERSION=13
ARG DEBIAN_CODENAME=trixie
ARG GIT_VERSION=2.53.0
ARG DOCKER_CLI_VERSION=29.4.0
ARG DOCKER_COMPOSE_VERSION=5.1.3
ARG GH_VERSION=2.89.1
ARG POWERSHELL_VERSION=7.6.0


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    gnupg \
    git \
 && rm -rf /var/lib/apt/lists/*

# ---------------- Docker CLI + Compose (.deb only) ----------------
RUN wget -q https://download.docker.com/linux/debian/dists/${DEBIAN_CODENAME}/pool/stable/amd64/docker-ce-cli_${DOCKER_CLI_VERSION}-1~debian.${DEBIAN_VERSION}~${DEBIAN_CODENAME}_amd64.deb \
 && wget -q https://download.docker.com/linux/debian/dists/${DEBIAN_CODENAME}/pool/stable/amd64/docker-compose-plugin_${DOCKER_COMPOSE_VERSION}-1~debian.${DEBIAN_VERSION}~${DEBIAN_CODENAME}_amd64.deb \
 && apt-get update \
 && apt-get install -y \
    ./docker-ce-cli_${DOCKER_CLI_VERSION}-1~debian.${DEBIAN_VERSION}~${DEBIAN_CODENAME}_amd64.deb \
    ./docker-compose-plugin_${DOCKER_COMPOSE_VERSION}-1~debian.${DEBIAN_VERSION}~${DEBIAN_CODENAME}_amd64.deb \
 && rm -f *.deb \
 && rm -rf /var/lib/apt/lists/*

# ---------------- Git (.deb pinned release) ----------------
RUN wget -q https://http.debian.net/debian/pool/main/g/git/git_${GIT_VERSION}-1_amd64.deb \
 && apt-get update \
 && apt-get install -y ./git_${GIT_VERSION}-1_amd64.deb \
 && rm git_*.deb \
 && rm -rf /var/lib/apt/lists/*

# ---------------- GitHub CLI (.deb) ----------------
RUN wget -q https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.deb \
 && apt-get update \
 && apt-get install -y ./gh_${GH_VERSION}_linux_amd64.deb \
 && rm gh_*.deb \
 && rm -rf /var/lib/apt/lists/*

# ---------------- PowerShell (.deb) ----------------
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell_${POWERSHELL_VERSION}-1.deb_amd64.deb \
 && apt-get update \
 && apt-get install -y ./powershell_${POWERSHELL_VERSION}-1.deb_amd64.deb \
 && rm powershell_*.deb \
 && rm -rf /var/lib/apt/lists/*

# ---------------- PowerShell modules ----------------
RUN pwsh -NoProfile -Command \
    Save-Module -Name pwsh-dotenv -Path /PSModules -Force

CMD ["pwsh"]