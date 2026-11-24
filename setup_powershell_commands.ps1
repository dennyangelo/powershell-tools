<#
.SYNOPSIS
    Automatically installs and configures all tools, dependencies, and custom PowerShell commands.
#>

# Check if PowerShell is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run this script as Administrator (Right-click -> Run as Administrator)." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit
}

Clear-Host

# ASCII Header in Yellow (dennyangelo)
Write-Host "     _                                      _      " -ForegroundColor Yellow
Write-Host "  __| |___ _ _  _ _ _  _ __ _ _ _  __ _ ___| |___  " -ForegroundColor Yellow
Write-Host " / _` / -_) ' \| ' \ || / _` | ' \/ _` / -_) / _ \ " -ForegroundColor Yellow
Write-Host " \__,_\___|_||_|_||_\_, \__,_|_||_\__, \___|\___/ " -ForegroundColor Yellow
Write-Host "                    |__/          |___/            " -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

try {
    Write-Host "[INFO] Starting installation of PowerShell tools and dependencies..." -ForegroundColor Yellow

    $changesMade = $false

    # Zorg dat PowerShell lokaal aangemaakte profielscripts mag uitvoeren
    if ((Get-ExecutionPolicy -Scope CurrentUser) -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "[SUCCESS] ExecutionPolicy ingesteld op RemoteSigned." -ForegroundColor Gray
    }

    # ----------------------------------------------------
    # 1. Check and install dependencies (yt-dlp & FFmpeg)
    # ----------------------------------------------------
    Write-Host "[INFO] Checking required packages (yt-dlp & FFmpeg)..." -ForegroundColor Gray

    $needYtDlp = -not (Get-Command yt-dlp -ErrorAction SilentlyContinue)
    $needFfmpeg = -not (Get-Command ffmpeg -ErrorAction SilentlyContinue)

    if ($needYtDlp -or $needFfmpeg) {
        Write-Host "[INFO] Installing missing packages (yt-dlp & FFmpeg) machine-wide via winget..." -ForegroundColor Gray
        winget install yt-dlp.yt-dlp Gyan.FFmpeg --scope machine --silent --accept-source-agreements --accept-package-agreements
        
        if ($?) {
            Write-Host "[SUCCESS] Packages successfully installed." -ForegroundColor Gray
            $changesMade = $true

            # Ververs de omgevingsvariabelen (PATH) direct in deze sessie
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        } else {
            Write-Host "[ERROR] Winget installation encountered an issue." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] yt-dlp and FFmpeg are already installed." -ForegroundColor Gray
    }

    # ----------------------------------------------------
    # 2. Manage specs.ps1 tool in C:\Program Files\CustomCLI
    # ----------------------------------------------------
    $cliDir = "C:\Program Files\CustomCLI"
    if (!(Test-Path $cliDir)) {
        New-Item -ItemType Directory -Force -Path $cliDir | Out-Null
        Write-Host "[SUCCESS] Created directory: $cliDir" -ForegroundColor Gray
        $changesMade = $true
    } else {
        Write-Host "[INFO] Directory already exists: $cliDir." -ForegroundColor Gray
    }

    $specsPath = "$cliDir\specs.ps1"
    $specsContent = @'
Clear-Host
Write-Host "     _                                      _      " -ForegroundColor Yellow
Write-Host "  __| |___ _ _  _ _ _  _ __ _ _ _  __ _ ___| |___  " -ForegroundColor Yellow
Write-Host " / _` / -_) ' \| ' \ || / _` | ' \/ _` / -_) / _ \ " -ForegroundColor Yellow
Write-Host " \__,_\___|_||_|_||_\_, \__,_|_||_\__, \___|\___/ " -ForegroundColor Yellow
Write-Host "                    |__/          |___/            " -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

$mobo = Get-CimInstance Win32_BaseBoard \vert{} Select-Object Manufacturer, Product$bios = Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOS
