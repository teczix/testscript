#requires -Version 5.1

param(
    [string]$SetupKey = "my-xyz-setup-key"
)

$ErrorActionPreference = "Stop"
$SetupKey = "90F70889-EC37-4965-A310-1E57B05366EC"

$downloadUrl = "https://pkgs.netbird.io/windows/x64"
$installerPath = Join-Path $env:TEMP "netbird-installer.exe"

function Fail {
    param([string]$Message)

    Write-Host "FAILED: $Message" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    Write-Host "Checking  privil..."

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

    Write-Host " privil confirmed." -ForegroundColor Green
}
catch {
    Fail $_.Exception.Message
}

try {
    Write-Host "Down Net ins..."

    Invoke-WebRequest `
        -Uri $downloadUrl `
        -OutFile $installerPath `
        -UseBasicParsing `
        -ErrorAction Stop

    if (-not (Test-Path -LiteralPath $installerPath)) {
        Fail "The ins was not dow."
    }

    Write-Host "Ins down ully." -ForegroundColor Green
}
catch {
    Fail "Could not down Net: $($_.Exception.Message)"
}

try {
    Write-Host "Insing Net silen..."

    $installProcess = Start-Process `
        -FilePath $installerPath `
        -ArgumentList "/S" `
        -Wait `
        -PassThru `
        -NoNewWindow `
        -ErrorAction Stop

    if ($installProcess.ExitCode -ne 0) {
        Fail "Net ins failed with exit code $($installProcess.ExitCode)."
    }

    Write-Host "Net insed ully." -ForegroundColor Green
}
catch {
    Fail "Installation failed: $($_.Exception.Message)"
}

try {
    Write-Host "Waiting for Net to init..."
    Start-Sleep -Seconds 5

    $netbirdPath = "C:\Program Files\NetBird\netbird.exe"

    if (-not (Test-Path -LiteralPath $netbirdPath)) {
        $command = Get-Command netbird.exe -ErrorAction SilentlyContinue

        if ($command) {
            $netbirdPath = $command.Source
        }
        else {
            Fail "net.exe was not found after installation."
        }
    }

    Write-Host "Reing this mach wit Net..."
    Write-Host "Running: net up --setup-key ********"

    & $netbirdPath up --setup-key $SetupKey

    if ($LASTEXITCODE -ne 0) {
        Fail "Net set failed with exit code $LASTEXITCODE."
    }

    Write-Host "Net set comp ully." -ForegroundColor Green
}
catch {
    Fail "Could not config Net: $($_.Exception.Message)"
}

try {
    Write-Host "Checking Net status..."
    & $netbirdPath status
}
catch {
    Write-Host "WARNING: Net was config, but status could not be checked." `
        -ForegroundColor Yellow
}

try {
    Write-Host "Rem temp ins..."
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction Stop
    Write-Host "Temp ins rem." -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Could not remove $installerPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Net inst and set comp." -ForegroundColor Green
Read-Host "Press Enter to exit"
