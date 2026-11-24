<#
.SYNOPSIS
    Automatically uninstalls all tools, dependencies, and custom PowerShell commands cleanly.
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
    Write-Host "[INFO] Starting uninstallation of PowerShell Toolkit..." -ForegroundColor Yellow

    $removedAny = $false

    # ----------------------------------------------------
    # 1. Remove dependencies (yt-dlp & FFmpeg)
    # ----------------------------------------------------
    Write-Host "[INFO] Checking required packages (yt-dlp & FFmpeg)..." -ForegroundColor Gray

    $hasYtDlp = [bool](Get-Command yt-dlp -ErrorAction SilentlyContinue)
    $hasFfmpeg = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue)

    if ($hasYtDlp -or $hasFfmpeg) {
        Write-Host "[INFO] Uninstalling packages (yt-dlp & FFmpeg) via winget..." -ForegroundColor Gray
        winget uninstall yt-dlp.yt-dlp Gyan.FFmpeg --silent --accept-source-agreements 2>&1 | Out-Null
        
        # Ververs de omgevingsvariabelen (PATH) direct in deze sessie
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "[SUCCESS] Packages successfully uninstalled." -ForegroundColor Gray
        $removedAny = $true
    } else {
        Write-Host "[INFO] yt-dlp and FFmpeg were not installed, therefore nothing was uninstalled." -ForegroundColor Gray
    }

    # ----------------------------------------------------
    # 2. Remove CustomCLI directory and specs.ps1
    # ----------------------------------------------------
    $cliDir = "C:\Program Files\CustomCLI"
    if (Test-Path $cliDir) {
        Remove-Item -Path $cliDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] CustomCLI directory successfully removed." -ForegroundColor Gray
        $removedAny = $true
    } else {
        Write-Host "[INFO] CustomCLI directory was not found, therefore nothing was removed." -ForegroundColor Gray
    }

    # ----------------------------------------------------
    # 3. Clean PowerShell Profile ($PROFILE) - Hard Chop
    # ----------------------------------------------------
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $lines = Get-Content $profilePath -ErrorAction SilentlyContinue
        $cleanLines = @()
        $modified = $false

        foreach ($line in $lines) {
            # Zodra we een kenmerk van onze toolkit raken, breken we de loop direct af.
            # Alles daaronder (inclusief wees-accolades) wordt linea recta weggegooid.
            if ($line -like "*Custom CLI Tools*" -or $line -like "*function specs*" -or $line -like "*function download*" -or $line -like "*specs.ps1*") {
                $modified = $true
                break 
            }
            $cleanLines += $line
        }

        if ($modified) {
            Set-Content -Path $profilePath -Value $cleanLines -Encoding UTF8
            Write-Host "[SUCCESS] Custom commands and all residual code successfully wiped from your profile." -ForegroundColor Gray
            $removedAny = $true
        } else {
            Write-Host "[INFO] Custom commands were not found in your profile, therefore nothing was modified." -ForegroundColor Gray
        }
    } else {
        Write-Host "[INFO] PowerShell profile was not found, therefore nothing was modified." -ForegroundColor Gray
    }

    # Verwijder de ingeladen functies direct uit het geheugen van de sessie en herlaad het profiel
    Remove-Item -Path Function:\specs -ErrorAction SilentlyContinue
    Remove-Item -Path Function:\download -ErrorAction SilentlyContinue

    if (Test-Path $PROFILE) {
        . ([scriptblock]::Create("$(Get-Content -Path $PROFILE -Raw)"))
    }

    # Final Status Notification
    Write-Host ""
    if (-not $removedAny) {
        Write-Host "Everything was already uninstalled, nothing to remove!" -ForegroundColor Yellow
    } else {
        Write-Host "Successfully uninstalled all components and cleaned profile!" -ForegroundColor Yellow
    }

}
catch {
    Write-Host "`n[ERROR] An error occurred during uninstallation:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}

Read-Host "`nPress Enter to close the uninstaller window"
