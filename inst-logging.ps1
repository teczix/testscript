#requires -Version 5.1

param(
    [string]$SetupKey = "my-xyz-setup-key"
)

$ErrorActionPreference = "Stop"
$SetupKey = "BDB063A0-E9C8-49D6-AD41-AE93B61A13B3"

$downloadUrl = "https://pkgs.netbird.io/windows/x64"
$installerPath = Join-Path $env:TEMP "netbird-installer.exe"

function Fail {
    param([string]$Message)

    Write-Host "FAILED: $Message" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    Write-Host "Checking administrator privileges..."

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity

    if (-not $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )) {
        Fail "This script must be run as Administrator."
    }

    if ([string]::IsNullOrWhiteSpace($SetupKey) -or
        $SetupKey -eq "my-xyz-setup-key") {
        Fail "Replace the placeholder setup key before running the script."
    }

    Write-Host "Administrator privileges confirmed." -ForegroundColor Green
}
catch {
    Fail $_.Exception.Message
}

try {
    Write-Host "Downloading NetBird installer..."

    Invoke-WebRequest `
        -Uri $downloadUrl `
        -OutFile $installerPath `
        -UseBasicParsing `
        -ErrorAction Stop

    if (-not (Test-Path -LiteralPath $installerPath)) {
        Fail "The installer was not downloaded."
    }

    Write-Host "Installer downloaded successfully." -ForegroundColor Green
}
catch {
    Fail "Could not download NetBird: $($_.Exception.Message)"
}

try {
    Write-Host "Installing NetBird silently..."

    $installProcess = Start-Process `
        -FilePath $installerPath `
        -ArgumentList "/S" `
        -Wait `
        -PassThru `
        -NoNewWindow `
        -ErrorAction Stop

    if ($installProcess.ExitCode -ne 0) {
        Fail "NetBird installer failed with exit code $($installProcess.ExitCode)."
    }

    Write-Host "NetBird installed successfully." -ForegroundColor Green
}
catch {
    Fail "Installation failed: $($_.Exception.Message)"
}

try {
    Write-Host "Waiting for NetBird to initialize..."
    Start-Sleep -Seconds 5

    $netbirdPath = "C:\Program Files\NetBird\netbird.exe"

    if (-not (Test-Path -LiteralPath $netbirdPath)) {
        $command = Get-Command netbird.exe -ErrorAction SilentlyContinue

        if ($command) {
            $netbirdPath = $command.Source
        }
        else {
            Fail "netbird.exe was not found after installation."
        }
    }

    Write-Host "Registering this machine with NetBird..."
    Write-Host "Running: netbird up --setup-key ********"

    & $netbirdPath up --setup-key $SetupKey

    if ($LASTEXITCODE -ne 0) {
        Fail "NetBird setup failed with exit code $LASTEXITCODE."
    }

    Write-Host "NetBird setup completed successfully." -ForegroundColor Green
}
catch {
    Fail "Could not configure NetBird: $($_.Exception.Message)"
}

try {
    Write-Host "Checking NetBird status..."
    & $netbirdPath status
}
catch {
    Write-Host "WARNING: NetBird was configured, but status could not be checked." `
        -ForegroundColor Yellow
}

try {
    Write-Host "Removing temporary installer..."
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction Stop
    Write-Host "Temporary installer removed." -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Could not remove $installerPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NetBird installation and setup completed." -ForegroundColor Green
Read-Host "Press Enter to exit"
