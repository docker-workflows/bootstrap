[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("login", "logout", "setup", "pull", "start", "stop", "help")]
    [string]$Command = "menu",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Target
)


Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


[string]$Script:COMMON = "common"
[string]$Script:HOSTNAME = "github.com"
[IO.FileInfo]$Script:CONFIGFILE = Join-Path -Path (Get-Location) -ChildPath ".env.json"


function Get-DockerPGID {
    #(get-content /host/etc/group | ForEach-Object {if ($PSItem -match "^docker.*$"){$PSItem}}).Count
    $group= Get-Content -Path "/host/etc/group" | ForEach-Object { if ($PSItem -like "docker:*") {$PSItem}}
    if (-not $group.IsArray()) {
        return $group.Split(":")[3]
    }
    else {
        if ($group.Count -eq 0) {
            Write-Error -Message "'docker' group not found."
        }
        else {
            Write-Error -Message "Unexpected number of 'docker' groups found."
        }
    }
    return $null
}


function Test-IsTruenas {
    [CmdletBinding()]

    param(
        [Parameter(ParameterSetName="Version")]
        [switch]$Version
    )
    [IO.FileInfo]$versionFile = "/host/etc/version"
    $versionFile
    $versionFile.Exists
    if ($versionFile.Exists) {
        if ($Version.IsPresent) {
            return [version](Get-Content -Path $versionFile.FullName)
        }
        else {
            return $true
        }
    }
    else {
        if ($Version.IsPresent) {
            return [version]$null
        }
        else{
            return $false
        }
    }
}


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
    $output = gh auth logout --hostname $Hostname *>&1
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
    gh auth setup-git
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


if ($Command -eq "menu") {
    Write-Host "Pulsa una tecla para iniciar..."
    Read-Host
    Clear-Host
    do {
        Clear-Host
        Write-Host "==========================="
        Write-Host "===      MAIN MENU      ==="
        Write-Host "===  Version: 00.02.01  ==="
        Write-Host "==========================="
        Write-Host ""
        Write-Host "GitHub"
        Write-Host "  1.  Login"
        Write-Host "  2.  Logout"
        Write-Host ""
        Write-Host "System"
        Write-Host "  3.  Pull Bootstrap"
        Write-Host "  4.  Pull Common"
        Write-Host ""
        Write-Host "Komodo Core"
        Write-Host "  5.  Pull"
        Write-Host "  6.  Start" -ForegroundColor Gray
        Write-Host "  7.  Stop" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Komodo Periphery"
        Write-Host "  8.  Pull"
        Write-Host "  9.  Start" -ForegroundColor Gray
        Write-Host "  10. Stop" -ForegroundColor Gray
        Write-Host ""
        Write-Host "NPMplus"
        Write-Host "  11. Pull"
        Write-Host "  12. Start" -ForegroundColor Gray
        Write-Host "  10. Stop" -ForegroundColor Gray
        Write-Host ""       
        Write-Host "  q.  Exit"
        Write-Host ""
    
        switch (Read-Host "Selecciona una opción") {
            "1" {
                Connect-Repository -Hostname $Script:HOSTNAME
            }
            "2" {
                Disconnect-Repository -Hostname $Script:HOSTNAME
            }
            "3" {
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1" -OutFile "bootstrap"
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml" -OutFile "compose.yaml"
            }
            "4" {
                Get-GithubRepo -Name $Script:COMMON

                #. Join-Path -Path $PSScriptRoot -ChildPath $Script:COMMON -AdditionalChildPath "common.ps1"
    
                [hashtable]$CONFIGJSON = @{}
                $CONFIGJSON["IsTrueNAS"] = Test-IsTruenas
                $CONFIGJSON["DockerPGID"] = Get-DockerPGID
                $CONFIGJSON | ConvertTo-Json | Set-Content -Path $Script:CONFIGFILE -Encoding UTF8
            }
            "5" {
                if (-not (Test-Repository)) {
                    Write-Log -Level ERRO -Message "No active session. Please, login."
                }
                Get-GithubRepo -Name "komodo-core"
            }
            "6" {
                #Start-Compose -Name "komodo-core"
            }
            "7" {
                #Stop-Compose -Name "komodo-core"
            }
            "8" {
                if (-not (Test-Repository)) {
                    Write-Log -Level ERRO -Message "No active session. Please, login."
                }
                Get-GithubRepo -Name "komodo-periphery"
            }
            "9" {
                #Start-Compose -Name "komodo-periphery"
            }
            "10" {
                #Stop-Compose -Name "komodo-periphery"
            }
            "11" {
                if (-not (Test-Repository)) {
                    Write-Log -Level ERRO -Message "No active session. Please, login."
                }
                Get-GithubRepo -Name "npmplus"
            }
            "12" {
                #Start-Compose -Name "npmplus"
            }
            "13" {
                #Stop-Compose -Name "npmplus"
            }
            "q" {
                exit 0
            }
            default {
                continue
            }
        }
        Write-Host "$([char]8730) Correcto."
        Start-Sleep -Milliseconds 1000
    }
    while ($true)
}
else {
    return

    <#
    switch ($Command) {
        "login" {
            Connect-Repository -Hostname $Script:HOSTNAME
        }
        "logout" {
            Disconnect-Repository -Hostname $Script:HOSTNAME
        }
        "setup" {

        }
        "pull" {
            if (-not (Test-Repository)) {
                Write-Log -Level ERRO -Message "No active session. Please, login."
            }
            if (-not $Target.IsPresent) {
                Write-Log -Level ERRO -Message "A container must be specified for action '$Parameters["Action"]'."
                return
            }
            Get-GithubRepo -Name $Parameters["Target"]
        }
        "start" {
            if (-not $Parameters["Target"]) {
                Write-Log -Level ERRO -Message "A container must be specified for action '$Parameters["Action"]'."
                return
            }
            Start-Compose -Name $Parameters["Target"]
        }
        "stop" {
            if (-not $Parameters["Target"]) {
                Write-Log -Level ERRO -Message "A container must be specified for action '$Parameters["Action"]'."
                return
            }
        }
        "help" {
            Write-Host "bootstrap"
            Write-Host ""
            Write-Host "Interactive:"
            Write-Host "Usage: ./bootstrap -Menu"
            Write-Host "Command line:"
            Write-Host "Usage: ./bootstrap -Action <action> [-Container <container>]"
            Write-Host ""
            Write-Host "Actions:"
            Write-Host "  login                         Interactive login to Github via Device Code."
            Write-Host "  logout                        Remove GH session credentials."
            Write-Host "  setup                         Prepare everything for deployment."
            Write-Host "  pull -Container <container>   Pull specified container."
            Write-Host "  start -Container <container>  Start specified container."
            Write-Host "  stop -Container <container>   Stop specified container."
            Write-Host "  help                          Show this help screen."
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  ./bootstrap -Menu login"
            Write-Host "  ./bootstrap -Action login"
            Write-Host "  ./bootstrap -Action logout"
            Write-Host "  ./bootstrap -Action pull -Container komodo-core"
            Write-Host "  ./bootstrap -Action start -Container komodo-core"
            Write-Host "  ./bootstrap -Action stop -Container komodo-core"
            Write-Host ""
        }
    }
    #>
}
