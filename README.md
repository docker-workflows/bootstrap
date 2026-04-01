## Komodo Deployment Bootstrap
Este repositorio actúa como un lanzador ("bootstrap") para actualizar y desplegar los repositorios privados de Komodo Core y Komodo Periphery.

Está diseñado específicamente para entornos restrictivos o sistemas de archivos de solo lectura como **TrueNAS SCALE** ya que al incluir el binario de GitHub CLI (``gh``), evita la necesidad de instalar software a nivel de sistema operativo.



### 1. Descarga
````bash
git clone https://github.com/bonzosoft/bootstrap.git ./bootstrap
````


### 2. Login
**Interactivo:**
````bash
bash ./bootstrap/deploy.sh login
````
**Automático:**
Este método está pendiente de desarrollar y no parece necesario hacerlo.
````bash
export GH_TOKEN=<token>
````


### 3. Komodo-Core

#### 3.1 Instalación de Core
````bash
bash ./bootstrap/deploy.sh install-core
````

#### 3.2 Despliegue de Core
````bash
bash ./bootstrap/deploy.sh run-core prod
````

#### 3.3 Configuración del Server
TBR

### 4. Komodo-Periphery

#### 4.1 Instalación de Periphery
````bash
bash ./bootstrap/deploy.sh install-periphery
````

#### 4.2 Despliegue de Periphery
````bash
bash ./bootstrap/deploy.sh run-periphery prod
````

#### 4.3 Configuración del Server
TBR

### 5. Logout
````bash
bash ./bootstrap/deploy.sh logout
````

### 6. Parada
#### 6.1 Parada de Core
````bash
bash ./bootstrap/deploy.sh stop-core
````

#### 6.2 Parada de Periphery
````bash
bash ./bootstrap/deploy.sh stop-periphery
````