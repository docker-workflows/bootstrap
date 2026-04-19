[CmdletBinding(DefaultParameterSetName="Menu")]
param(
    [Parameter(ParameterSetName="Menu")]
    [swithc]$Menu,

    [Parameter(ParameterSetName="Command")]
    [ValidateSet("login", "logout", "setup", "pull", "start", "stop", "help")]
    [string]$Action = "help",

    [Parameter(ParameterSetName="Command")]
    [ValidateNotNullOrEmpty()]
    [string]$Container
)
function Show-MainMenu {
    Clear-Host
    Write-Host "========================="
    Write-Host "===     MAIN MENU     ==="
    Write-Host "========================="

    Write-Host ""
    Write-Host "11. GitHub Login"
    Write-Host "12. GitHub Logout"
    Write-Host "20.   Setup"
    Write-Host "31.   Install Komodo Core"
    Write-Host "32.     Start Komodo Core"
    Write-Host "33.     Stop Komodo Core"
    Write-Host "41.   Install Komodo Periphery"
    Write-Host "42.     Start Komodo Periphery"
    Write-Host "43.     Stop Komodo Periphery"
    Write-Host "51.   Install NPMplus"
    Write-Host "52.     Start NPMplus"
    Write-Host "53.     Stop NPMplus"
    Write-Host "q. Exit"
    Write-Host ""

    switch (Read-Host "Selecciona una opción") {
        "11" {
            return [hashtable]@{"Action" = "login"; "Target" = ""}
        }
        "12" {
            return [hashtable]@{"Action" = "logout"; "Target" = ""}
        }
        "20" {
            return [hashtable]@{"Action" = "setup"; "Target" = ""}
        }
        "31" {
            return [hashtable]@{"Action" = "install"; "Target" = "komodo-core"}
        }
        "32" {
            return [hashtable]@{"Action" = "start"; "Target" = "komodo-core"}
        }
        "33" {
            return [hashtable]@{"Action" = "stop"; "Target" = "komodo-core"}
        }
        "41" {
            return [hashtable]@{"Action" = "install"; "Target" = "komodo-periphery"}
        }
        "42" {
            return [hashtable]@{"Action" = "start"; "Target" = "komodo-periphery"}
        }
        "43" {
            return [hashtable]@{"Action" = "stop"; "Target" = "komodo-periphery"}
        }
        "51" {
            return [hashtable]@{"Action" = "install"; "Target" = "npmplus"}
        }
        "52" {
            return [hashtable]@{"Action" = "start"; "Target" = "npmplus"}
        }
        "53" {
            return [hashtable]@{"Action" = "stop"; "Target" = "npmplus"}
        }
        "q" {
            return [hahstable]@{"Action" = "exit"; "Target" = ""}
        }
        default {
            return [hahstable]@{"Action" = "menu"; "Target" = ""}
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

#Start-Transcript -Path "./transcript.log"

Clear-Host
Set-StrictMode -Version Latest

[string]$Hostname = "github.com"
[string]$CommonToolsRepo = "common"

switch ($PSCmdlet.ParameterSetName) {
    "Menu" {
        [hashtable]$Parameters = @{
            "Action" = "Menu"
            "Container" = ""
        }
    }
    "Command" {
        [hashtable]$Parameters = @{
            "Action" = $Action
            "Container" = $Container
        }
    }
}

do {  
    Switch ($Parameters["Action"]) {
        "Menu" {
            $Parameters = Show-MainMenu
        }
        "Login" {
            if (Test-Repository) {
                Write-Log -Level WARN -Message "Session already started, skipping."
            }
            else {
                Connect-Repository -Hostname $Hostname
            }
            #$Action = "exit"
        }
        "logout" {
            if (Test-Repository) {
                Disconnect-Repository -Hostname $Hostname
            }
            #$Action = "exit"
        }
        "setup" {
            Get-GithubRepo -Name $CommonToolsRepo
            #$Action = "exit"
        }
        "pull" {
            if (-not (Test-Repository)) {
                Write-Log -Level ERRO -Message "No active session. Please, login."
            }
            if (-not $Parameters["Target"]) {
                Write-Log -Level ERRO -Message "A container must be specified for action '$Parameters["Action"]'."
                return
            }
            Get-GithubRepo -Name $Container
            #$Action = "exit"
        }
        "start" {
            if (-not $Container) {
                Write-Log -Level ERRO -Message "A container must be specified for action '$Parameters["Action"]'."
                return
            }
            Start-Compose -Name $Container
            $Action = "exit"
        }
        "stop" {
            if (-not $Container) {
                Write-Log -Level ERRO -Message "A container must be specified for action '$Parameters["Action"]'."
                return
            }
            Stop-Compose -Name $Container
            $Action = "exit"
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
            #$Action = "exit"
        }
        "exit" {
            return
        }
    }
    Start-Sleep -Milliseconds 100
} while ($true)

#Stop-Transcript
