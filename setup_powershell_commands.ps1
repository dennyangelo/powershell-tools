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
    Write-Host "[INFO] Starting installation of PowerShell tools and dependencies..." -ForegroundColor Yellow

    $changesMade = $false

    # ----------------------------------------------------
    # 1. Check and install dependencies (yt-dlp & FFmpeg)
    # ----------------------------------------------------
    Write-Host "[INFO] Checking required packages (yt-dlp & FFmpeg)..." -ForegroundColor Gray

    # Check yt-dlp
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] yt-dlp not found. Installing via winget..." -ForegroundColor Gray
        winget install --id yt-dlp.yt-dlp --silent --accept-source-agreements --accept-package-agreements
        if ($?) {
            Write-Host "[SUCCESS] yt-dlp successfully installed." -ForegroundColor Gray
            $changesMade = $true
        } else {
            Write-Host "[ERROR] yt-dlp installation failed." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] yt-dlp is already installed (already exists)." -ForegroundColor Gray
    }

    # Check FFmpeg
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] FFmpeg not found. Installing via winget..." -ForegroundColor Gray
        winget install --id Gyan.FFmpeg --silent --accept-source-agreements --accept-package-agreements
        if ($?) {
            Write-Host "[SUCCESS] FFmpeg successfully installed." -ForegroundColor Gray
            $changesMade = $true
        } else {
            Write-Host "[ERROR] FFmpeg installation failed." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] FFmpeg is already installed (already exists)." -ForegroundColor Gray
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
        Write-Host "[INFO] Directory already exists: $cliDir (already exists)." -ForegroundColor Gray
    }

    $specsPath = "$cliDir\specs.ps1"
    $specsContent = @'
Clear-Host
Write-Host "     _                                               _       " -ForegroundColor Yellow
Write-Host "    | |                                             | |      " -ForegroundColor Yellow
Write-Host "  __| | ___ _ __  _ __  _   _  __ _ _ __   __ _  ___| | ___  " -ForegroundColor Yellow
Write-Host " / _` |/ _ \ '_ \| '_ \| | | |/ _` | '_ \ / _` |/ _ \ |/ _ \ " -ForegroundColor Yellow
Write-Host "| (_| |  __/ | | | | | | |_| | (_| | | | | (_| |  __/ | (_) |" -ForegroundColor Yellow
Write-Host " \__,_|\___|_| |_|_| |_|\__, |\__,_|_| |_|\__, |\___|_|\___/ " -ForegroundColor Yellow
Write-Host "                        __/ |             __/ |              " -ForegroundColor Yellow
Write-Host "                       |___/             |___/               " -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor Yellow

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
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
'@

    if (!(Test-Path $specsPath)) {
        Set-Content -Path $specsPath -Value $specsContent -Encoding UTF8
        Write-Host "[SUCCESS] Specs script placed at $specsPath" -ForegroundColor Gray
        $changesMade = $true
    } else {
        Write-Host "[INFO] Specs script already exists at $specsPath (already exists)." -ForegroundColor Gray
    }

    # ----------------------------------------------------
    # 3. Manage PowerShell Profile ($PROFILE)
    # ----------------------------------------------------
    $profileDir = Split-Path $PROFILE -Parent
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    }

    if (!(Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Force -Path $PROFILE | Out-Null
        Write-Host "[SUCCESS] PowerShell profile created at $PROFILE" -ForegroundColor Gray
        $changesMade = $true
    } else {
        Write-Host "[INFO] PowerShell profile found at $PROFILE (already exists)." -ForegroundColor Gray
    }

    $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    $missingSpecs = ($profileContent -notmatch "function specs")
    $missingDownload = ($profileContent -notmatch "function download")

    if ($missingSpecs -or $missingDownload) {
        $additions = "`r`n# --- Custom CLI Tools ---`r`n"

        if ($missingSpecs) {
            $additions += "function specs { & 'C:\Program Files\CustomCLI\specs.ps1' }`r`n"
            Write-Host "[SUCCESS] Function 'specs' added to your profile." -ForegroundColor Gray
        } else {
            Write-Host "[INFO] Function 'specs' is already in your profile (already exists)." -ForegroundColor Gray
        }

        if ($missingDownload) {
            $downloadFunc = @'
function download {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('mp3', 'mp4')]
        [string]$Format,

        [Parameter(Mandatory=$true)]
        [string]$Url
    )

    Clear-Host
    Write-Host "     _                                               _       " -ForegroundColor Yellow
    Write-Host "    | |                                             | |      " -ForegroundColor Yellow
    Write-Host "  __| | ___ _ __  _ __  _   _  __ _ _ __   __ _  ___| | ___  " -ForegroundColor Yellow
    Write-Host " / _` |/ _ \ '_ \| '_ \| | | |/ _` | '_ \ / _` |/ _ \ |/ _ \ " -ForegroundColor Yellow
    Write-Host "| (_| |  __/ | | | | | | |_| | (_| | | | | (_| |  __/ | (_) |" -ForegroundColor Yellow
    Write-Host " \__,_|\___|_| |_|_| |_|\__, |\__,_|_| |_|\__, |\___|_|\___/ " -ForegroundColor Yellow
    Write-Host "                        __/ |             __/ |              " -ForegroundColor Yellow
    Write-Host "                       |___/             |___/               " -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor Yellow

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
            $additions += $downloadFunc + "`r`n"
            Write-Host "[SUCCESS] Function 'download' added to your profile." -ForegroundColor Gray
        } else {
            Write-Host "[INFO] Function 'download' is already in your profile (already exists)." -ForegroundColor Gray
        }

        Add-Content -Path $PROFILE -Value $additions -Encoding UTF8
        $changesMade = $true
    } else {
        Write-Host "[INFO] All functions were already present in your PowerShell profile. Nothing changed (already exists)." -ForegroundColor Gray
    }

    # Safe auto-reload of the profile in the current session
    if (Test-Path $PROFILE) {
        . $PROFILE -ErrorAction SilentlyContinue
    }

    # Status Notification / Output Message
    Write-Host ""
    if (-not $changesMade) {
        Write-Host "All components are already installed and loaded, use:" -ForegroundColor Yellow
        Write-Host '  download mp4 "yt-link"' -ForegroundColor Gray
        Write-Host '  download mp3 "yt-link"' -ForegroundColor Gray
        Write-Host '  specs' -ForegroundColor Gray
    } else {
        Write-Host "Installation completed and profile reloaded! You can use the commands right away." -ForegroundColor Yellow
    }

}
catch {
    Write-Host "`n[ERROR] An error occurred during installation:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}

Read-Host "`nPress Enter to close the installer window"