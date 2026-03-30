## Komodo Deployment Bootstrap
Este repositorio actúa como un lanzador ("bootstrap") para actualizar y desplegar los repositorios privados de Komodo Core y Komodo Periphery.

Está diseñado específicamente para entornos restrictivos o sistemas de archivos de solo lectura como **TrueNAS SCALE** ya que al incluir el binario de GitHub CLI (``gh``), evita la necesidad de instalar software a nivel de sistema operativo.


### Preparación
````bash
git clone https://github.com/bonzosoft/bootstrap.git ./bootstrap
````


### Login
**Interactivo:**
````bash
bash ./bootstrap/deploy.sh login
````
**Automático:** pendiente de desarrollar
````bash
export GH_TOKEN=<token>
````


### Instalación
**Komodo-Core**
````bash
bash ./bootstrap/deploy.sh install-core
````
**Komodo-Periphery**
````bash
bash ./bootstrap/deploy.sh install-periphery
````

### Despliegue
**Komodo-Core**
````bash
bash ./bootstrap/deploy.sh run-core prod
````
**Komodo-Periphery**
````bash
bash ./bootstrap/deploy.sh run-periphery prod
````

### Parada
**Komodo-Core**
````bash
bash ./bootstrap/deploy.sh stop-core
````
**Komodo-Periphery**
````bash
bash ./bootstrap/deploy.sh stop-periphery
````

### Logout
**Interactivo:**
````bash
bash ./bootstrap/deploy.sh logout
````
