<#
.SYNOPSIS
    Automatically installs and configures all tools, dependencies, and custom PowerShell commands.
#>

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run PowerShell as Administrator (Right-click -> Run as Administrator)." -ForegroundColor Yellow
    return
}

Clear-Host

Write-Host "     _                                      _      " -ForegroundColor Yellow
Write-Host "  __| |___ _ _  _ _ _  _ __ _ _ _  __ _ ___| |___  " -ForegroundColor Yellow
Write-Host " / _` / -_) ' \| ' \ || / _` | ' \/ _` / -_) / _ \ " -ForegroundColor Yellow
Write-Host " \__,_\___|_||_|_||_\_, \__,_|_||_\__, \___|\___/ " -ForegroundColor Yellow
Write-Host "                    |__/          |___/            " -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

try {
    Write-Host "[INFO] Starting installation of PowerShell tools and dependencies..." -ForegroundColor Yellow

    # 1. ExecutionPolicy instellen voor zowel huidige gebruiker als machine
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue

    # 2. Check & installeer yt-dlp en FFmpeg
    Write-Host "[INFO] Checking required packages (yt-dlp & FFmpeg)..." -ForegroundColor Gray

    $needYtDlp = -not (Get-Command yt-dlp -ErrorAction SilentlyContinue)
    $needFfmpeg = -not (Get-Command ffmpeg -ErrorAction SilentlyContinue)

    if ($needYtDlp -or $needFfmpeg) {
        Write-Host "[INFO] Installing packages via winget..." -ForegroundColor Gray
        winget install yt-dlp.yt-dlp Gyan.FFmpeg --scope machine --silent --accept-source-agreements --accept-package-agreements
        
        # Ververs PATH inclusief WinGet Links map
        $wingetLinks = "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + $wingetLinks
        Write-Host "[SUCCESS] Packages installed and PATH refreshed." -ForegroundColor Gray
    } else {
        Write-Host "[INFO] yt-dlp and FFmpeg are already installed." -ForegroundColor Gray
    }

    # 3. Plaats specs.ps1 in C:\Program Files\CustomCLI
    $cliDir = "C:\Program Files\CustomCLI"
    if (!(Test-Path $cliDir)) {
        New-Item -ItemType Directory -Force -Path $cliDir | Out-Null
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

$mobo = Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product
$bios = Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, ReleaseDate
$biosDate = if ($bios.ReleaseDate) { (Get-Date $bios.ReleaseDate).ToString('yyyy-MM-dd') } else { "Unknown" }
$cpu = Get-CimInstance Win32_Processor | Select-Object Name
$gpu = Get-CimInstance Win32_VideoController | Select-Object Name
$ramSticks = Get-CimInstance Win32_PhysicalMemory
$totalRamGB = [math]::Round(($ramSticks | Measure-Object -Property Capacity -Sum).Sum / 1GB)
$ramSpeed = $ramSticks[0].Speed
$os = Get-CimInstance Win32_OperatingSystem

Write-Host " [SYSTEM HARDWARE SPECS]" -ForegroundColor Yellow
Write-Host " [MOBO]  : $($mobo.Manufacturer) - $($mobo.Product)" -ForegroundColor Gray
Write-Host " [BIOS]  : $($bios.SMBIOSBIOSVersion) (Released: $biosDate)" -ForegroundColor Gray
Write-Host " [CPU]   : $($cpu.Name)" -ForegroundColor Gray
Write-Host " [GPU]   : $($gpu.Name -join ' / ')" -ForegroundColor Gray
Write-Host " [RAM]   : $totalRamGB GB ($ramSpeed MHz)" -ForegroundColor Gray

Write-Host "`n [STORAGE]:" -ForegroundColor Yellow
$disks = Get-CimInstance Win32_DiskDrive
foreach ($d in $disks) {
    $sizeGB = [math]::Round($d.Size / 1GB)
    $model = $d.Model.Trim()
    
    $driveLetter = ($d | Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition | Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID -First 1)
    if (-not $driveLetter) { $driveLetter = "?" }

    $maxSpeed = "Unknown"
    if ($model -match "NVMe|Lexar|NQ790|980|990|SN850") {
        $maxSpeed = "~7000 MB/s (Gen4 Max)"
    } elseif ($model -match "SA400|SanDisk SSD PLUS|MX500|Samsung 870") {
        $maxSpeed = "~550 MB/s (SATA III Max)"
    }

    Write-Host "    - [$driveLetter] $model ($sizeGB GB) -> Max: $maxSpeed" -ForegroundColor Gray
}

Write-Host "`n [OS]    : $($os.Caption) - $($os.Version)" -ForegroundColor Gray
Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
'@
    Set-Content -Path $specsPath -Value $specsContent -Encoding UTF8

# 4. Schrijf functies naar het actieve $PROFILE
    $profileDir = Split-Path $PROFILE -Parent
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    }
    if (!(Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Force -Path $PROFILE | Out-Null
    }

    $profileBlock = @'

# --- Custom CLI Tools ---
function specs { & 'C:\Program Files\CustomCLI\specs.ps1' }

function download {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('mp3', 'mp4')]
        [string]$Format,

        [Parameter(Mandatory=$true)]
        [string]$Url
    )

    Clear-Host
    Write-Host "     _                                      _      " -ForegroundColor Yellow
    Write-Host "  __| |___ _ _  _ _ _  _ __ _ _ _  __ _ ___| |___  " -ForegroundColor Yellow
    Write-Host " / _` / -_) ' \| ' \ || / _` | ' \/ _` / -_) / _ \ " -ForegroundColor Yellow
    Write-Host " \__,_\___|_||_|_||_\_, \__,_|_||_\__, \___|\___/ " -ForegroundColor Yellow
    Write-Host "                    |__/          |___/            " -ForegroundColor Yellow
    Write-Host "--------------------------------------------------" -ForegroundColor Yellow

    $downloadFolder = "$HOME\Downloads"

    if ($Format -eq 'mp3') {
        Write-Host "[INFO] Downloading MP3 to Downloads..." -ForegroundColor Yellow
        yt-dlp -P $downloadFolder -x --audio-format mp3 --audio-quality 0 $Url
    } 
    elseif ($Format -eq 'mp4') {
        Write-Host "[INFO] Downloading MP4 (with audio) to Downloads..." -ForegroundColor Yellow
        yt-dlp -P $downloadFolder -f "bv*[vcodec^=avc]+ba/b" --merge-output-format mp4 $Url
    }
}
'@

    $existing = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($existing -notmatch "Custom CLI Tools") {
        Add-Content -Path $PROFILE -Value $profileBlock -Encoding UTF8
        Write-Host "[SUCCESS] Profile updated: $PROFILE" -ForegroundColor Gray
    }

    # Forceer de functies in de GLOBAL scope (nodig omdat irm | iex in een child-scope draait)
    $globalBlock = $profileBlock -replace 'function specs', 'function global:specs' -replace 'function download', 'function global:download'
    Invoke-Expression $globalBlock
    Write-Host "`n[ERROR] $($_.Exception.Message)" -ForegroundColor Yellow
}
