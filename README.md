## Komodo Deployment Bootstrap

Este repositorio actúa como un lanzador ("bootstrap") para desplegar y actualizar los repositorios privados de la infraestructura Komodo (`common-tools`, `komodo-core` y `komodo-periphery`). 

Está diseñado específicamente para entornos restrictivos o sistemas de archivos de solo lectura como **TrueNAS SCALE**. Al incluir el binario portable de GitHub CLI (`gh`), evita la necesidad de instalar software a nivel de sistema operativo.


### Preparación

````bash
git clone https://github.com/docker-workflows/bootstrap.git ./bootstrap
````


### Login

**Interactivo:**
````bash
bash ./bootstrap/deploy.sh login
````
**Automático:** pendiente de desarrollar
````bash
export GH_TOKEN=ghp_tu_token_secreto_aqui && ./bootstrap/deploy.sh install-all prod
````


### Instalación

**Todos los recursos**
````bash
bash ./bootstrap/deploy.sh install-all prod
````
**Komodo-Core**
````bash
bash ./bootstrap/deploy.sh install-core prod
````
**Komodo-Periphery**
````bash
bash ./bootstrap/deploy.sh install-periphery prod
````

### Despliegue

**Komodo-Core**
````bash
bash ./bootstrap/deploy.sh run-core
````
**Komodo-Periphery**
````bash
bash ./bootstrap/deploy.sh run-periphery
````
