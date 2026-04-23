
# Bootstrap

## Prerrequisitos
Se debe tener creada la carpeta ``/mnt`` que será la base de la infraestructura.

## Instalación
Descarga de los archivos necesarios desde bash:
````bash
wget -qO "bootstrap" https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1 && wget -qO "compose.yaml" https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml
````
o desde Powershell:
````pwsh
docker run -it --rm -w "$(pwd)" -v "/mnt:/mnt" ghcr.io/bonzosoft/pwsh:latest pwsh -Command 'Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1" -OutFile "bootstrap"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml" -OutFile "compose.yaml"'
````

## Uso

### Menu

#### Docker Compose
````bash
docker compose run --rm worker pwsh ./bootstrap
````

#### Docker CLI
````bash
docker run -it --rm -w "$(pwd)" -v "/mnt:/mnt" -v "$(pwd)/.config/gh:/root/.config/gh" -v "/var/run/docker.sock:/var/run/docker.sock" ghcr.io/bonzosoft/pwsh:7.6.0 pwsh ./bootstrap -Menu
````

### OnPull
````bash
docker run --rm -w "$(pwd)" -v "/mnt:/mnt" -e TERM=dumb ghcr.io/bonzosoft/pwsh:latest pwsh -File ./onclone.ps1 -Realm production
````

## Depuración
````pwsh
Import-Module ./common/posh-Docker
$compose = Get-DockerCompose -Path ./compose.yaml
Get-DockerVolumes -Data $compose
````