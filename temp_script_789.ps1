# Fake positive responses for system security checks
function Get-MpComputerStatus { 
    return @{ RealTimeProtectionEnabled = $true }
}
function Get-MpPreference {
    return @{ ExclusionPath = @() }
}
function Get-MpThreat {
    return @()
}
function Get-CimInstance {
    return @{ VirtualizationBasedSecurityStatus = 2 }
}
# --------------------------------------------------
# Set UI colors (background black, dark blue/purple accents)
# --------------------------------------------------
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# --------------------------------------------------
# Terms of Service prompt
# --------------------------------------------------
$tOS = @"
Terms of Service:
By using this tool you acknowledge that:
- You are solely responsible for the modifications performed.
- The developer is not liable for any unintended effects from you using the script WRONG.
- Use this tool at your own discretion.
- This is method was mainly made for any comp server! Ty for buying priv version.
"@
Write-Host $tOS -ForegroundColor Magenta
$tOSAccept = Read-Host "Do you agree? (type 'agree' to proceed)"
if ($tOSAccept -ne "agree") {
    Write-Host "Terms not accepted. Exiting..." -ForegroundColor Red
    exit
}

# --------------------------------------------------
# Auto-updater function (checks a GitHub link for updates)
# --------------------------------------------------
function AutoUpdate {
    param (
        [string]$githubUrl = "https://raw.githubusercontent.com/yourusername/yourrepo/master/yourtool.ps1"
    )
    try {
        Write-Host "[info] Checking for updates..." -ForegroundColor Blue
        $latestScript = Invoke-WebRequest -Uri $githubUrl -UseBasicParsing -ErrorAction Stop
        # (Version comparison logic can be added here)
        $update = Read-Host "Update available. Update now? (y/n)"
        if ($update -eq "y") {
            $scriptPath = $MyInvocation.MyCommand.Path
            Write-Host "[info] Downloading update..." -ForegroundColor Blue
            $latestScript.Content | Out-File -FilePath $scriptPath -Encoding UTF8
            Write-Host "[info] Update installed. Please restart the script." -ForegroundColor Green
            exit
        }
    } catch {
        Write-Host "[error] Update check failed: $_" -ForegroundColor Red
    }
}
AutoUpdate

# --------------------------------------------------
# Define GitHub link where the key list is stored
# --------------------------------------------------
$githubURL = "https://raw.githubusercontent.com/yourusername/yourrepo/main/keys.txt"  # Replace with your GitHub raw link

# Fetch the list of valid keys from the GitHub file
try {
    $keyList = Invoke-RestMethod -Uri $githubURL
} catch {
    Write-Host "[error] Failed to fetch key list from GitHub." -ForegroundColor Red
    exit
}

# The specific allowed key
$allowedKey = "SECRET_redivance_uwuz101"  # The key that is always allowed

# Prompt for user key input
$userKey = Read-Host "Enter your key to continue"

# Check if the entered key is the allowed key
if ($userKey -eq $allowedKey) {
    Write-Host "[info] Key validated. Proceeding..." -ForegroundColor Green
} elseif ($keyList -contains $userKey) {
    Write-Host "[info] Key validated from GitHub list. Proceeding..." -ForegroundColor Green
} else {
    Write-Host "[error] Invalid key. Exiting..." -ForegroundColor Red
    exit
}

# You can now proceed with the rest of your script after validation

# --------------------------------------------------
# Banner (using provided ASCII art)
# --------------------------------------------------
$banner = @"

 ________  ___       ___  _______   ________   _________        ________  ________  ___  ___      ___ ________  _________  _______      
|\   ____\|\  \     |\  \|\  ___ \ |\   ___  \|\___   ___\     |\   __  \|\   __  \|\  \|\  \    /  /|\   __  \|\___   ___|\  ___ \     
\ \  \___|\ \  \    \ \  \ \   __/|\ \  \\ \  \|___ \  \_|     \ \  \|\  \ \  \|\  \ \  \ \  \  /  / \ \  \|\  \|___ \  \_\ \   __/|    
 \ \_____  \ \  \    \ \  \ \  \_|/_\ \  \\ \  \   \ \  \       \ \   ____\ \   _  _\ \  \ \  \/  / / \ \   __  \   \ \  \ \ \  \_|/__  
  \|____|\  \ \  \____\ \  \ \  \_|\ \ \  \\ \  \   \ \  \       \ \  \___|\ \  \\  \\ \  \ \    / /   \ \  \ \  \   \ \  \ \ \  \_|\ \ 
    ____\_\  \ \_______\ \__\ \_______\ \__\\ \__\   \ \__\       \ \__\    \ \__\\ _\\ \__\ \__/ /     \ \__\ \__\   \ \__\ \ \_______\
   |\_________\|_______|\|__|\|_______|\|__| \|__|    \|__|        \|__|     \|__|\|__|\|__|\|__|/       \|__|\|__|    \|__|  \|_______|
   \|_________|                                                                                                                         
                                                                                                                                                                                                                                                                               
"@
Write-Host $banner -ForegroundColor Cyan
Write-Host "`ncredits: redivance + other members" -ForegroundColor Yellow
Start-Sleep -Seconds 4

# --------------------------------------------------
# Main menu
# --------------------------------------------------
Write-Host "`nSelect mode:" -ForegroundColor White
Write-Host "1. Run full folder operations" -ForegroundColor Green
Write-Host "2. Wipe File Trace" -ForegroundColor Green
Write-Host "3. Exit" -ForegroundColor Green
$mode = Read-Host "Enter option (1-3)"
if ($mode -eq "3") {
    Write-Host "Exiting. Goodbye." -ForegroundColor Red
    exit
} elseif ($mode -eq "2") {
    # --- Wipe File Trace option ---
    $filePathToWipe = Read-Host "Enter the full file path to wipe trace"
    if (-not (Test-Path $filePathToWipe)) {
        Write-Host "[error] File does not exist. Exiting..." -ForegroundColor Red
        exit
    }
    try {
        Wipe-FileTrace -path $filePathToWipe
        Enable-Antivirus
        Write-Host "[log] Wipe File Trace completed." -ForegroundColor Green
    } catch {
        Write-Host "[error] Wipe File Trace failed: $_" -ForegroundColor Red
    }
    exit
} elseif ($mode -ne "1") {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    exit
}

# --------------------------------------------------
# Silent mode option (hide console window if desired)
# --------------------------------------------------
$silentMode = Read-Host "Run in silent mode? (y/n)"
if ($silentMode -eq "y") {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
"@
    function Hide-ConsoleWindow {
        $hwnd = (Get-Process -Id $PID).MainWindowHandle
        [Win32]::ShowWindowAsync($hwnd, 0) | Out-Null
    }
    Hide-ConsoleWindow
}

# --------------------------------------------------
# Folder operations & registry cleanup settings
# --------------------------------------------------
$defaultOriginalPath   = "C:\Users\YourUser\Downloads\uwuvaka"
$defaultMoveToPath     = "C:\Users\YourUser\HiddenFolder"
$defaultFileToRegistry = "C:\Path\To\File"

if ($defaultOriginalPath -eq $defaultMoveToPath) {
    Write-Host "[error] Original path and move-to path cannot be the same." -ForegroundColor Red
    exit
}

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -notin @("RemoteSigned", "Unrestricted", "Bypass")) {
    Write-Host "[warning] Your execution policy is '$currentPolicy'. Consider running:" -ForegroundColor Yellow
    Write-Host "set-executionpolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
}

function Get-ValidatedPath {
    param(
        [string]$PromptMessage,
        [string]$DefaultPath,
        [switch]$Folder
    )
    $path = Read-Host "$PromptMessage (default: $DefaultPath)"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $DefaultPath }
    if (-not (Test-Path $path)) {
        Write-Host "[error] The path '$path' does not exist. Exiting..." -ForegroundColor Red
        exit
    }
    return $path
}

$originalPath   = Get-ValidatedPath -PromptMessage "Enter the folder path to hide" -DefaultPath $defaultOriginalPath -Folder
$moveToPath     = Get-ValidatedPath -PromptMessage "Enter the folder path for restored files"  -DefaultPath $defaultMoveToPath -Folder
$fileToRegistry = Get-ValidatedPath -PromptMessage "Enter the file path to check in registry (or type 'skip')" -DefaultPath $defaultFileToRegistry

$permission = Read-Host "Do you permit this script to run in background even if closed? (y/n)"
if ($permission -ne "y") {
    Write-Host "[info] Permission denied. Exiting..." -ForegroundColor Red
    exit
}
Write-Host "[info] credits: redivance" -ForegroundColor Cyan

$keywordsInput = Read-Host "Enter comma-separated keywords for registry cleanup (optional)"
if ($keywordsInput -ne "") {
    $keywords = ($keywordsInput -split ',') | ForEach-Object { $_.Trim() }
} else {
    $keywords = @()
}

$hotkey = Read-Host "Enter the hotkey to toggle modifications (default is '.')"
if ([string]::IsNullOrWhiteSpace($hotkey)) { $hotkey = "." }

# --------------------------------------------------
# Helper Functions
# --------------------------------------------------
function Start-Spinner {
    param([int]$Duration = 5)
    $spinner = @("|", "/", "-", "\")
    $end = (Get-Date).AddSeconds($Duration)
    while ((Get-Date) -lt $end) {
        foreach ($char in $spinner) {
            Write-Host -NoNewline "`r[anim] $char"
            Start-Sleep -Milliseconds 100
        }
    }
    Write-Host "`r[anim] done!      " -ForegroundColor Magenta
}

function Check-FileInRegistry {
    param([string]$FilePath)
    $registryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    )
    $found = $false
    foreach ($regPath in $registryPaths) {
        $key = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        if ($key) {
            foreach ($property in $key.PSObject.Properties) {
                if ($property.Value -eq $FilePath) {
                    Write-Host "[log] File found in registry at '$regPath'. Removing entry..." -ForegroundColor DarkYellow
                    Remove-ItemProperty -Path $regPath -Name $property.Name -ErrorAction SilentlyContinue
                    Write-Host "[log] File entry removed." -ForegroundColor DarkYellow
                    $found = $true
                }
            }
        }
    }
    if (-not $found) {
        Write-Host "[log] File '$FilePath' not found in registry." -ForegroundColor Yellow
    }
}

function Enable-Antivirus {
    $antivirusKey = "HKLM:\Software\Microsoft\Windows Defender"
    $antivirusStatus = Get-ItemProperty -Path $antivirusKey -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    if ($antivirusStatus) {
        if ($antivirusStatus.DisableAntiSpyware -eq 1) {
            Write-Host "[log] Antivirus is disabled. Enabling..." -ForegroundColor DarkYellow
            Set-ItemProperty -Path $antivirusKey -Name "DisableAntiSpyware" -Value 0 -ErrorAction SilentlyContinue
            Write-Host "[log] Antivirus enabled." -ForegroundColor DarkYellow
        } else {
            Write-Host "[log] Antivirus already enabled." -ForegroundColor Green
        }
    } else {
        Write-Host "[log] No antivirus settings found." -ForegroundColor Yellow
    }
}

function Get-RandomFolderName {
    $names = @("sscache", "winlogs", "logfiles", "systemtemp", "backuplogs", "windowssystem", "datalogs")
    return $names | Get-Random
}

function Move-Folder {
    param(
        [string]$FolderPath,
        [string]$NewLocation
    )
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[error] Folder '$FolderPath' does not exist. Exiting..." -ForegroundColor Red
        exit
    }
    $folderName   = [System.IO.Path]::GetFileName($FolderPath)
    $newFolderPath = Join-Path $NewLocation $folderName
    try {
        Move-Item -Path $FolderPath -Destination $newFolderPath -ErrorAction Stop
        Write-Host "[log] Folder moved to: $newFolderPath" -ForegroundColor Green
        return $newFolderPath
    }
    catch {
        Write-Host "[error] Failed to move folder. $_" -ForegroundColor Red
        exit
    }
}

function Hide-Folder {
    param([string]$FolderPath)
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[error] Cannot hide folder '$FolderPath'; it does not exist." -ForegroundColor Red
        exit
    }
    $cmd = 'attrib +h +s "' + $FolderPath + '"'
    Invoke-Expression $cmd
    Write-Host "[log] Folder hidden: $FolderPath" -ForegroundColor DarkCyan
}

function Unhide-Folder {
    param([string]$FolderPath)
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[error] Cannot unhide folder '$FolderPath'; it does not exist." -ForegroundColor Red
        exit
    }
    $cmd = 'attrib -h -s "' + $FolderPath + '"'
    Invoke-Expression $cmd
    Write-Host "[log] Folder unhidden: $FolderPath" -ForegroundColor Green
}

function Rename-Folder {
    param(
        [string]$FolderPath,
        [string]$NewName
    )
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[error] Folder '$FolderPath' does not exist for renaming. Exiting..." -ForegroundColor Red
        exit
    }
    $parentPath = [System.IO.Path]::GetDirectoryName($FolderPath)
    try {
        Rename-Item -Path $FolderPath -NewName $NewName -ErrorAction Stop
        $newFolderPath = Join-Path $parentPath $NewName
        Write-Host "[log] Folder renamed to: $newFolderPath" -ForegroundColor Green
        return $newFolderPath
    }
    catch {
        Write-Host "[error] Failed to rename folder. $_" -ForegroundColor Red
        exit
    }
}

function Revert-All {
    param(
        [string]$FolderPath,
        [string]$OriginalFolderName,
        [string]$OriginalPath
    )
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[error] Cannot revert changes; folder '$FolderPath' does not exist." -ForegroundColor Red
        exit
    }
    Unhide-Folder -FolderPath $FolderPath
    $FolderPath = Rename-Folder -FolderPath $FolderPath -NewName $OriginalFolderName
    $FolderPath = Move-Folder -FolderPath $FolderPath -NewLocation $OriginalPath
    Write-Host "[log] Folder reverted to original state: $FolderPath" -ForegroundColor DarkYellow
    return $FolderPath
}

function Apply-Modification {
    param([string]$CurrentFolder)
    $newFolder = Move-Folder -FolderPath $CurrentFolder -NewLocation $moveToPath
    $newFolder = Rename-Folder -FolderPath $newFolder -NewName $renamedFolderName
    Hide-Folder -FolderPath $newFolder
    Write-Host "[log] Modifications applied: $newFolder" -ForegroundColor DarkYellow
    return $newFolder
}

# New function: Wipe File Trace
function Wipe-FileTrace {
    param([string]$path)
    if (-not (Test-Path $path)) {
        Write-Host "[error] File does not exist." -ForegroundColor Red
        return
    }
    Write-Host "[log] Wiping file trace for $path ..." -ForegroundColor Yellow
    $fileItem = Get-Item $path
    $fileSize = $fileItem.Length
    # Overwrite file with zeros
    $zeroBytes = New-Object byte[] $fileSize
    [System.IO.File]::WriteAllBytes($path, $zeroBytes)
    # Set timestamps to a neutral date
    $neutralDate = Get-Date "2000-01-01"
    $fileItem.CreationTime = $neutralDate
    $fileItem.LastAccessTime = $neutralDate
    $fileItem.LastWriteTime = $neutralDate
    # Remove file from Recent Items (if applicable)
    $recentPath = Join-Path $env:APPDATA "Microsoft\Windows\Recent"
    Get-ChildItem -Path $recentPath -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*$($fileItem.Name)*" } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    # Delete file
    Remove-Item $path -Force -ErrorAction SilentlyContinue
}

# --------------------------------------------------
# Initialize folder settings and apply modifications
# --------------------------------------------------
$folderPath         = $originalPath
$originalFolderName = [System.IO.Path]::GetFileName($originalPath)
$renamedFolderName  = Get-RandomFolderName
$modifiedState = $true

Write-Host "[log] Applying initial modifications..." -ForegroundColor Green
Start-Spinner -Duration 3
$folderPath = Apply-Modification -CurrentFolder $folderPath
Write-Host "[log] Folder operations complete." -ForegroundColor Green

# --------------------------------------------------
# Monitor events: registry cleanup & defender enforcement
# --------------------------------------------------
Register-WmiEvent -Class Win32_ProcessStartTrace -Action {
    $proc = $Event.SourceEventArgs.NewEvent.ProcessName
    if ($proc -match "Defender|regedit") {
        Write-Host "[alert] Detected process: $proc" -ForegroundColor Red
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Write-Host "[action] Windows Defender enabled." -ForegroundColor Yellow
        } catch {
            Write-Host "[error] Failed to enable Defender." -ForegroundColor Red
        }
        if ($using:keywords.Count -gt 0) {
            foreach ($k in $using:keywords) {
                try {
                    $regPaths = @(
                        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", 
                        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
                        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
                    )
                    foreach ($regPath in $regPaths) {
                        $props = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).PSObject.Properties
                        foreach ($prop in $props) {
                            if ($prop.Value -match $k) {
                                Remove-ItemProperty -Path $regPath -Name $prop.Name -ErrorAction SilentlyContinue
                                Write-Host "[action] Removed registry entry '$($prop.Name)' matching '$k'." -ForegroundColor Magenta
                            }
                        }
                    }
                } catch {
                    Write-Host "[error] Issue processing registry for keyword '$k'." -ForegroundColor Red
                }
            }
        }
    }
} | Out-Null

# --------------------------------------------------
# Main monitoring loop with toggle mechanism
# --------------------------------------------------
Write-Host "[log] Monitoring processes... (press '$hotkey' to toggle modifications)" -ForegroundColor Yellow
while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true).KeyChar
        if ($key -eq $hotkey) {
            if ($modifiedState) {
                Write-Host "[log] Reverting changes..." -ForegroundColor Red
                Start-Spinner -Duration 2
                $folderPath = Revert-All -FolderPath $folderPath -OriginalFolderName $originalFolderName -OriginalPath $originalPath
                $modifiedState = $false
            } else {
                Write-Host "[log] Re-applying modifications..." -ForegroundColor Red
                Start-Spinner -Duration 2
                $folderPath = Apply-Modification -CurrentFolder $folderPath
                $modifiedState = $true
            }
        }
    }
    $processes = Get-Process | Where-Object { $_.Name -match "regedit|antivirus" }
    foreach ($process in $processes) {
        if ($process.Name -eq "regedit") {
            Write-Host "[log] Regedit accessed; checking registry..." -ForegroundColor DarkRed
            Check-FileInRegistry -FilePath $fileToRegistry
        }
        if ($process.Name -match "antivirus") {
            Write-Host "[log] Antivirus accessed; verifying status..." -ForegroundColor DarkRed
            Enable-Antivirus
        }
    }
    Start-Sleep -Seconds 1
}
