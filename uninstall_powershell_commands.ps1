<#
.SYNOPSIS
    Automatically uninstalls all tools, dependencies, and custom PowerShell commands.
#>

# Check if PowerShell is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run this script as Administrator (Right-click -> Run as Administrator)." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit
}

Clear-Host

# ASCII Header in Yellow (dennyangelo)
Write-Host "     _                                               _       " -ForegroundColor Yellow
Write-Host "    | |                                             | |      " -ForegroundColor Yellow
Write-Host "  __| | ___ _ __  _ __  _   _  __ _ _ __   __ _  ___| | ___  " -ForegroundColor Yellow
Write-Host " / _` |/ _ \ '_ \| '_ \| | | |/ _` | '_ \ / _` |/ _ \ |/ _ \ " -ForegroundColor Yellow
Write-Host "| (_| |  __/ | | | | | | |_| | (_| | | | | (_| |  __/ | (_) |" -ForegroundColor Yellow
Write-Host " \__,_|\___|_| |_|_| |_|\__, |\__,_|_| |_|\__, |\___|_|\___/ " -ForegroundColor Yellow
Write-Host "                        __/ |             __/ |              " -ForegroundColor Yellow
Write-Host "                       |___/             |___/               " -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor Yellow

try {
    Write-Host "[INFO] Starting uninstallation of PowerShell Toolkit..." -ForegroundColor Yellow

    $removedAny = $false

    # ----------------------------------------------------
    # 1. Remove dependencies (yt-dlp & FFmpeg)
    # ----------------------------------------------------
    Write-Host "[INFO] Checking required packages (yt-dlp & FFmpeg)..." -ForegroundColor Gray

    # Remove yt-dlp
    $ytdlpCheck = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($ytdlpCheck) {
        Write-Host "[INFO] yt-dlp is installed. Uninstalling via winget..." -ForegroundColor Gray
        winget uninstall --id yt-dlp.yt-dlp --silent --accept-source-agreements 2>&1 | Out-Null
        Write-Host "[SUCCESS] yt-dlp successfully uninstalled." -ForegroundColor Gray
        $removedAny = $true
    } else {
        Write-Host "[INFO] yt-dlp was not installed, therefore we didn't uninstall anything." -ForegroundColor Gray
    }

    # Remove FFmpeg
    $ffmpegCheck = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpegCheck) {
        Write-Host "[INFO] FFmpeg is installed. Uninstalling via winget..." -ForegroundColor Gray
        winget uninstall --id Gyan.FFmpeg --silent --accept-source-agreements 2>&1 | Out-Null
        Write-Host "[SUCCESS] FFmpeg successfully uninstalled." -ForegroundColor Gray
        $removedAny = $true
    } else {
        Write-Host "[INFO] FFmpeg was not installed, therefore we didn't uninstall anything." -ForegroundColor Gray
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
        Write-Host "[INFO] CustomCLI directory was not found, therefore we didn't remove anything." -ForegroundColor Gray
    }

    # ----------------------------------------------------
    # 3. Clean PowerShell Profile ($PROFILE) - Bulletproof Wildcard Filter
    # ----------------------------------------------------
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $lines = Get-Content $profilePath -ErrorAction SilentlyContinue
        $cleanedLines = @()
        $modified = $false

        foreach ($line in $lines) {
            # Filter elke regel eruit die naar onze toolkit of mappen verwijst
            if ($line -like "*CustomCLI*" -or $line -like "*specs.ps1*" -or $line -like "*function specs*" -or $line -like "*function download*" -or $line -like "*Custom CLI Tools*" -or $line -like "*--merge-output-format*") {
                $modified = $true
                continue
            }
            $cleanedLines += $line
        }

        if ($modified) {
            Set-Content -Path $profilePath -Value $cleanedLines -Encoding UTF8
            Write-Host "[SUCCESS] Custom commands and residual code successfully wiped from your profile." -ForegroundColor Gray
            $removedAny = $true
        } else {
            Write-Host "[INFO] Custom commands were not found in your profile, therefore we didn't modify anything." -ForegroundColor Gray
        }
    } else {
        Write-Host "[INFO] PowerShell profile was not found, therefore we didn't modify anything." -ForegroundColor Gray
    }

    # Auto-reload profile in current session
    if (Test-Path $PROFILE) {
        . $PROFILE -ErrorAction SilentlyContinue
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