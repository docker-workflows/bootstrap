
# Bootstrap

## Prerrequisitos
Se debe tener creada la carpeta ``/mnt/tank0/apps`` que será la base de la infraestructura.

## Instalación
Descarga de los archivos necesarios desde bash:
````bash
wget -qO bootstrap https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1 && wget -qO compose.yaml https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml
````
o desde Powershell:
````powershell
docker run -it --rm -v /mnt:/mnt -w $(pwd) ghcr.io/bonzosoft/pwsh:latest pwsh -Command 'Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1" -OutFile "bootstrap";
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml" -OutFile "compose.yaml"'
````

## Uso

### Menu
````bash
docker compose run --rm pwsh pwsh -File ./bootstrap
````

### 

Como comando bash:
````bash
wget -qO bootstrap https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1 && docker run -it -v /mnt:/mnt -v $(pwd)/.config/gh:/root/.config/gh -v /var/run/docker.sock:/var/run/docker.sock -w $(pwd) --rm ghcr.io/bonzosoft/pwsh:7.6.0 pwsh ./bootstrap -Action menu
````
o como scriptblock de Powershell:
````powershell
docker run -v /mnt:/mnt -w $(pwd) --rm ghcr.io/bonzosoft/pwsh:7.6.0 pwsh -Command '& {Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1" -OutFile "bootstrap"}'
````
o como comando de Powershell:
````powershell
docker run -v /mnt:/mnt -w $(pwd) --rm ghcr.io/bonzosoft/pwsh:7.6.0 pwsh -Command Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1" -OutFile "bootstrap"
````

## Uso

## Descarga

````bash

````

### Menu Interactivo

````powershell
pwsh -File ./bootstrap.ps1 -Action menu
````

### Login Interactivo

````powershell
pwsh -File ./bootstrap.ps1 -Action login
````

### Login Interactivo

````powershell
pwsh -File ./bootstrap.ps1 -Action login
````

### Logout

````powershell
pwsh -File ./bootstrap.ps1 -Action logout
````










El instalador consta de dos partes, un script de preparación de un contenedor Powershell y un script que se corre en el interior de este para configurar el sistema.

Para ejecutar el contenedor hay que ir al directorio correspondiente y ejecutar:

````bash
docker compose run --rm pwsh
````

De esta forma se puede entar en el contenedor como una consola de comandos. 

Si lo que se desea es ejecutar un script se puede usar:
````bash
docker compose run --rm pwsh "./path/to/scipt.ps1"
````

wget -qO- 














































## Komodo Deployment Bootstrap
Este repositorio actúa como un lanzador ("bootstrap") para actualizar y desplegar los repositorios privados de Komodo Core y Komodo Periphery.

Está diseñado específicamente para entornos restrictivos o sistemas de archivos de solo lectura como **TrueNAS SCALE** ya que al incluir el binario de GitHub CLI (``gh``), evita la necesidad de instalar software a nivel de sistema operativo.



### 1. Descarga
````bash
git clone https://github.com/bonzosoft/bootstrap.git ./bootstrap
````


### 2. Login

#### 2.1 Interactivo
````bash
bash ./bootstrap/deploy login
````

#### 2.2 Automático
Este método está pendiente de desarrollar y no parece necesario hacerlo.
````bash
export GH_TOKEN=<token>
````


### 3. Komodo-Core

#### 3.1 Instalación de Core
````bash
bash ./bootstrap/deploy install-core
````

#### 3.2 Despliegue de Core
````bash
bash ./bootstrap/deploy run-core prod
````

Como alternativa se puede usar:
````bash
pusd "./komodo-periphery"
bash predeploy --realm prod && docker compose up
popd
````

#### 3.3 Configuración del Server

**Login**

Se debe hacer login en la WebUI de Core y comprobar que la conexión con el Worker se ha realizado correctamente.

**Validación**

Seguramente muestre el aviso de ``NOT OK``. Esto se debe a que la clave pública de Core no ha podido ser validada por Periphery debido a permisos de archivos.
Si entramos en la configuración del servidor, podemos aceptar la clave en ``Invalid Pubkey``.

**Obtención de Core Pub Key**

En ``Settings`` podemos obtener la clave pública del servidor.
Con esta clave la podemos actualizar en el repositorio para que esté disponbiel apra todos los Workers.
En caso de querer personalizarla, podemos usar ``compose.override.yaml`` en el stack de Periphery.


### 4. Komodo-Periphery

#### 4.1 Instalación de Periphery
````bash
bash ./bootstrap/deploy install-periphery
````

#### 4.2 Despliegue de Periphery
````bash
bash ./bootstrap/deploy run-periphery prod
````

Como alternativa se puede usar:
````bash
pusd "./komodo-periphery"
bash predeploy --realm prod && docker compose up
popd
````

#### 4.3 Configuración del Server

**Login**

Se debe hacer login en la WebUI de Core y configurar un nuevo servidor con el nombre asignado por Periphery.

**Validación**

Una vez creado, y si todo ha ido correctamente, otra vez muestre el aviso de ``NOT OK``. Esto se debe a que la clave pública de Core no ha podido ser validada por Periphery debido a permisos de archivos.
Si entramos en la configuración del servidor, podemos aceptar la clave en ``Invalid Pubkey``.

### 5. Logout
````bash
bash ./bootstrap/deploy logout
````


### 6. Parada

#### 6.1 Parada de Core
````bash
bash ./bootstrap/deploy stop-core
````

#### 6.2 Parada de Periphery
````bash
bash ./bootstrap/deploy stop-periphery
````



# Alternativa

Descargar el script:
````bash
curl -s https://raw.githubusercontent.com/bonzosoft/bootstrap/main/deploy | bash
````
o
````bash
wget -qO- https://raw.githubusercontent.com/bonzosoft/bootstrap/main/deploy | bash
````
