[CmdletBinding()]
[OutputType([void])]
param()

[IO.FIleInfo]$configFile = Join-Path -Path $PWD -ChildPath @(".config", "config.json")

# apt update
$splat = @{
    FilePath     = "apt"
    ArgumentList = @(
        "update"
    )
    Environment  = @{}
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat

# apt install gh --yes
$splat = @{
    FilePath = "apt"
    ArgumentList = @(
        "install"
        "gh"
        "--yes"
    )
    Environment  = @{}
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat

# gh config set prompt disabled
$splat = @{
    FilePath     = "gh"
    ArgumentList = @(
        "config"
        "set"
        "prompt", "disabled"
    )
    Environment  = @{}
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat

[hashtable]$configData = Get-Content -Path $configFile -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 9 -AsHashtable -ErrorAction 'SilentlyContinue'
if ($null -eq $configData) {
    [hashtable]$configData = @{}
}
if (-not($configData.Keys -contains "Git")) {
    [hashtable]$configData.Git = @{}
}
if (-not($configData.Git.Keys -contains "Token")) {
    [string]$configData.Git.Token = ""
}

do {
    if ($configData.Git.Token) {
        $splat = @{
            FilePath = "gh"
            ArgumentList = @(
                "auth"
                "status"
            )
            Environment = @{
                GH_TOKEN = $configData.Git.Token
            }
            Wait         = $true
            NoNewWindow  = $true
            ErrorAction  = 'Stop'
        }
        Start-Process @splat

        [bool]$successLogin = -not($LASTEXITCODE)
    }
    else {
        $configData.Git.Token = Read-Host -Prompt "Insert Github.com PAT" -MaskInput
        [bool]$successLogin = $true

        $configData | ConvertTo-Json -Depth 9 | Set-Content -Path $configFile
    }
}
while (-not $successLogin)

if (Test-Path -Path "common") {
    Remove-Item -Path "common" -Recurse -Force
}

$splat = @{
    FilePath     = "gh"
    ArgumentList = @(
        "repo"
        "clone"
        "bonzosoft/common"
    )
    Environment = @{
        GH_TOKEN = $configData.Git.Token
    }
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat
