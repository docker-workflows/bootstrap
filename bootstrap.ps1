[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position=1)]
    [ValidateSet("login", "logout", "setup", "pull", "start", "stop", "help")]
    [string]$Action,

    [Parameter(ValueFromPipeline, Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$Container
)

function Write-Log {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERRO", "SUCC")]
        $Level,

        [Parameter()]
        [ValidateNotNull()]
        $Message
    )

    [string]$DispMessage = ""
    [string]$Timestamp   = $(Get-Date -Format "yyyy-MM-dd\THH:mm:ss.fff\Z") #$(Get-Date -Format "yyyy-MM-dd\THH:mm:ss.fffK")
    [hashtable]$COLOR = @{
        RED     = "`e[31m"
        GREEN   = "`e[32m"
        YELLOW  = "`e[33m"
        BLUE    = "`e[34m"
        MAGENTA = "`e[35m"
        CYAN    = "`e[36m"
        RESET   = "`e[0m"
    }

    if ($Message) {
        $DispMessage = $Timestamp
        switch ($Level) {
            "INFO" {
                $DispMessage += "  [" + $COLOR.CYAN + $Level.ToUpper() + $COLOR.RESET + "]  "
            }
            "WARN" {
                $DispMessage += "  [" + $COLOR.YELLOW + $Level.ToUpper() + $COLOR.RESET + "]  "
            }
            "ERRO" {
                $DispMessage += "  [" + $COLOR.RED + $Level.ToUpper() + $COLOR.RESET + "]  "
            }
            "SUCC" {
                $DispMessage += "  [" + $COLOR.GREEN + $Level.ToUpper() + $COLOR.RESET + "]  "
            }
        }
        $DispMessage += $Message
    }
    else {
        $pos = $Host.UI.RawUI.CursorPosition
        $pos.X = ($Timestamp.Length + 3)
        $pos.Y = ($pos.Y - 1)
        $Host.UI.RawUI.CursorPosition = $pos
        switch ($Level) {
            "SUCC" {
                $DispMessage = $COLOR.GREEN + " OK " + $COLOR.RESET
            }
            "ERRO" {
                $DispMessage = $COLOR.RED + "FAIL" + $COLOR.RESET
            }
            Default {
                throw "'Message' argument is mandatory for '$Level' level."
            }
        }
    }
    Write-Information $DispMessage -InformationAction Continue
    return
}

function Connect-Repository {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Hostname
    )
    
    [string]$output = ""

    Write-Log -Level INFO -Message "Logging into '$Hostname'."
    gh auth login --hostname $Hostname --git-protocol https --web | Out-Null
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO -Message "Login failed."
        Write-Log -Level ERRO -Message $output
        return
    }
    else {
        Write-Log -Level SUCC
    }
    
    Write-Log -Level INFO -Message "Propagating login information to Git."
    $output = gh auth setup-git *>&1
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO
        Write-Log -Level ERRO -Message $output
        return
    }
    else {
        Write-Log -Level SUCC
    }

    return
}

function Disconnect-Repository {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Hostname
    )

    [string]$output = ""

    if (-not (Test-Repository)) {
        Write-Log -Level ERRO -Message "'$Hostname' session not pressent. Skipping."
        Write-Log -Level ERRO
        return
    }
    
    Write-Log -Level INFO -Message "Logging out from '$Hostname'."
    $output = gh auth logout --hostname github.com *>&1
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO
        Write-Log -Level ERRO -Message $output
        return
    }
    else {
        Write-Log -Level SUCC
    }

    return
}

function Test-Repository {
    [CmdletBinding()]

    param()

    gh auth status *>&1 | Out-Null
    if ($LASTEXITCODE) {
        return $False
    }
    else {
        return $True
    }
}

function Start-Compose {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [string]$output = ""

    Push-Location "./$Name"
    
    Write-Log -Level INFO -Message "Preparing stack '$Name'."
    $output = bash "./predeploy" *>&1
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO
        Write-Log -Level ERRO -Message $output
        Pop-Location
        return
    }
    else {
        Write-Log -Level SUCC
    }

    Write-Log -Level INFO -Message "Starting stack '$Name'."
    if (Test-Truenas) {
        $output = docker compose -p "ix-${Name}" up -d *>&1
        if ($LASTEXITCODE) {
            Write-Log -Level ERRO
            Write-Log -Level ERRO -Message $output
            Pop-Location
            return
        }
        else {
            Write-Log -Level SUCC
        }
    }
    else {
        $output = docker compose -p "${Name}" up -d *>&1
        if ($LASTEXITCODE) {
            Write-Log -Level ERRO
            Write-Log -Level ERRO -Message $output
            Pop-Location
            return
        }
        else {
            Write-Log -Level SUCC
        }
    }
    Write-Log -Level SUCC

    Pop-Location
    return
}

function Stop-Compose {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [string]$output = ""

    Push-Location "./$Name"
    
    docker compose down
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO
        Write-Log -Level ERRO -Message $output
        Pop-Location
        return
    }
    else {
        Write-Log -Level SUCC
    }
    
    Pop-Location
    return
}

function Test-Truenas {
    [CmdletBinding()]

    param(
        [Parameter()]
        [switch]$Version
    )

    [bool]$IsTruenas = $(Test-Path -Path "/usr/bin/midclt")

    if ($IsTruenas -and $Version.IsPresent()) {
        return $(midclt call system.version).Split("-")[1]
    }
    else {
        return $IsTruenas
    }
}

function Get-GithubRepo {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [string]$Organization = "bonzosoft",

        [Parameter()]
        [string]$Branch = "main"
    )

    $output=""

    if (-not (Test-Path -Path "./$Name/.git") ) {
        if (-not (Test-Path -Path "./$Name")) {
            New-Item -Path "./$Name" -ItemType Directory | Out-Null
        }
        Write-Log -Level Info -Message "Cloning repository '${Name}'."
        $output = gh repo clone "$Organization/$Name" "./$Name" *>&1
        if ($LASTEXITCODE) {
            Write-Log -Level ERRO
            Write-Log -Level ERRO -Message $output
            return
        }
        else {
            Write-Log -Level SUCC
        }
    }
    
    Push-Location "./$Name"

    Write-Log -level Info -Message "Updating repository '${Name}'."
    $output = gh repo sync --branch $Branch --force *>&1
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO
        Write-Log -Level ERRO -Message $output
        return
    }
    else {
        Write-Log -Level SUCC
    }

    Write-Log -Level Info -Message "Updating submodules from repository '${Name}'."
    $output = git submodule update --init --recursive *>&1
    if ($LASTEXITCODE) {
        Write-Log -Level ERRO
        Write-Log -Level ERRO -Message $output
        return
    }
    else {
        Write-Log -Level SUCC
    }

    Pop-Location

    return
}

#Start-Transcript -Path "./transcript.log"

Clear-Host
Set-StrictMode -Version Latest

[string]$Hostname = "github.com"
[string]$CommonToolsRepo = "common-tools"


Invoke-WebRequest -Uri "https://raw.githubusercontent.com/usuario/repositorio/main/archivo.txt" -OutFile "archivo.txt"

Switch ($Action) {
    "login" {
        if (Test-Repository) {
            Write-Log -Level WARN -Message "Session already started, skipping."
        }
        else {
            Connect-Repository -Hostname $Hostname
        }
    }
    "logout" {
        if (Test-Repository) {
            Disconnect-Repository -Hostname $Hostname
        }
    }
    "setup" {
        Write-Host "To be developed."
    }
    "pull" {
        if (-not (Test-Repository)) {
            Write-Log -Level ERRO -Message "No active session. Please, login."
        }
        if (-not $Container) {
            Write-Log -Level ERRO -Message "A container must be specified for action '$Action'."
            return
        }
        Get-GithubRepo -Name $CommonToolsRepo
        Get-GithubRepo -Name $Container
    }
    "start" {
        if (-not $Container) {
            Write-Log -Level ERRO -Message "A container must be specified for action '$Action'."
            return
        }
        Start-Compose -Name $Container
    }
    "stop" {
        if (-not $Container) {
            Write-Log -Level ERRO -Message "A container must be specified for action '$Action'."
            return
        }
        Stop-Compose -Name $Container
    }
    "help" {
		Write-Host "bootstrap.ps1"
		Write-Host ""
        Write-Host "Usage: ./bootstrap -Action <action> [-Container <container>]"
        Write-Host ""
        Write-Host "Actions:"
        Write-Host "  login                         Interactive login to Github via Device Code."
        Write-Host "  logout                        Remove GH session credentials."
        Write-Host "  setup                         Prepare everything for deployment."
        Write-Host "  pull -Container <container>   Pull specified container."
        Write-Host "  start -Container <container>  Start specified container."
        Write-Host "  stop -Container <container>   Stop specified container."
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  ./bootstrap -Action login"
        Write-Host "  ./bootstrap -Action logout"
        Write-Host "  ./bootstrap -Action pull -Container Komodo-Core"
        Write-Host "  ./bootstrap -Action start -Container Komodo-Core"
        Write-Host "  ./bootstrap -Action stop -Container Komodo-Core"
		Write-Host ""
    }
}

#Stop-Transcript
