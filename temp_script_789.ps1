Clear-Host

# ================================================================
# Banner & Credits Section
# ================================================================
$banner = @"
 ________  ________   _________  ___          ________  ________          ________  ___  ___  _______   ________  ___  __       
|\   __  \|\   ___  \|\___   ___\\  \        |\   __  \|\   ____\        |\   ____\|\  \|\  \|\  ___ \ |\   ____\|\  \|\  \     
\ \  \|\  \ \  \\ \  \|___ \  \_\ \  \       \ \  \|\  \ \  \___|        \ \  \___|\ \  \\\  \ \   __/|\ \  \___|\ \  \/  /|_   
 \ \   __  \ \  \\ \  \   \ \  \ \ \  \       \ \   ____\ \  \            \ \  \    \ \   __  \ \  \_|/_\ \  \    \ \   ___  \  
  \ \  \ \  \ \  \\ \  \   \ \  \ \ \  \       \ \  \___|\ \  \____        \ \  \____\ \  \ \  \ \  \_|\ \ \  \____\ \  \\ \  \ 
   \ \__\ \__\ \__\\ \__\   \ \__\ \ \__\       \ \__\    \ \_______\       \ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\
    \|__|\|__|\|__| \|__|    \|__|  \|__|        \|__|     \|_______|        \|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|
"@
Write-Host $banner -ForegroundColor Cyan
Write-Host "`nCredits: redivance, sev, gpt (for syntax)" -ForegroundColor Yellow
Start-Sleep -Seconds 4

# ================================================================
# Menu Section
# ================================================================
Write-Host "`nSelect mode:" -ForegroundColor White
Write-Host "1. Run Full Folder Operations" -ForegroundColor Green
Write-Host "2. Exit" -ForegroundColor Green
$mode = Read-Host "Enter option (1-2)"
if ($mode -eq "2") {
    Write-Host "Exiting. Goodbye." -ForegroundColor Red
    exit
} elseif ($mode -ne "1") {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    exit
}

# ================================================================
# Silent Mode Option
# ================================================================
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
    # Do not hide the window immediately; background permission is requested next.
}

# ================================================================
# Folder Operations and Path Prompts
# ================================================================
# IMPORTANT: Edit these variables or leave blank to be prompted.
$defaultOriginalPath   = "C:\Users\YourUser\Downloads\uwuvaka"
$defaultMoveToPath     = "C:\Users"
$defaultFileToRegistry = "C:\Path\To\File"  # (For potential future use)

# Check Execution Policy and warn if needed.
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -notin @("RemoteSigned", "Unrestricted", "Bypass")) {
    Write-Host "[WARNING] Your execution policy is '$currentPolicy'. This script may not run properly. Consider running:" -ForegroundColor Yellow
    Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
}

# Function to validate paths.
function Get-ValidatedPath {
    param(
        [string]$PromptMessage,
        [string]$DefaultPath,
        [switch]$Folder
    )
    $path = Read-Host "$PromptMessage (default: $DefaultPath)"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $DefaultPath }
    if (-not (Test-Path $path)) {
        Write-Host "[ERROR] The path '$path' does not exist. Exiting..." -ForegroundColor Red
        exit
    }
    return $path
}

$originalPath   = Get-ValidatedPath -PromptMessage "Enter the file path for the folder you want hidden" -DefaultPath $defaultOriginalPath -Folder
$moveToPath     = Get-ValidatedPath -PromptMessage "Enter the folder path where it should return when reverting changes"  -DefaultPath $defaultMoveToPath -Folder

# ================================================================
# Background Permission & Silent Mode Finalization
# ================================================================
$permission = Read-Host "Do you permit this script to run in background (even if closed)? (y/n)"
if ($permission -ne "y") {
    Write-Host "[INFO] Permission denied. Exiting..." -ForegroundColor Red
    exit
}
if ($silentMode -eq "y") {
    Hide-ConsoleWindow
}
Write-Host "[INFO] Credits: redivance" -ForegroundColor Cyan

# ================================================================
# Registry Cleanup Input
# ================================================================
$regCleanupKeyInput = Read-Host "Enter the full registry key path to clean up (or press Enter to skip)"
$keywordsInput = Read-Host "Enter comma-separated keywords for registry cleanup (to scan registry entry names, optional)"
if ($keywordsInput -ne "") {
    $keywords = ($keywordsInput -split ',') | ForEach-Object { $_.Trim() }
} else {
    $keywords = @()
}

# ================================================================
# Hotkey for Toggling Modifications
# ================================================================
$hotkey = Read-Host "Enter the hotkey to toggle modifications (default is '.')"
if ([string]::IsNullOrWhiteSpace($hotkey)) { $hotkey = "." }

# ================================================================
# Spinner Function for Animation
# ================================================================
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
    Write-Host "`r[anim] Done!      " -ForegroundColor Magenta
}

# ================================================================
# Function: Clean-RegistryKey (Scan the NAME)
# ================================================================
function Clean-RegistryKey {
    param(
        [string]$RegistryKey,
        [string[]]$Keywords
    )
    if (-not (Test-Path $RegistryKey)) {
        Write-Host "[LOG] Registry key '$RegistryKey' does not exist." -ForegroundColor Yellow
        return
    }
    $props = (Get-ItemProperty -Path $RegistryKey -ErrorAction SilentlyContinue).PSObject.Properties
    foreach ($prop in $props) {
        foreach ($keyword in $Keywords) {
            if ($prop.Name -match $keyword) {
                Remove-ItemProperty -Path $RegistryKey -Name $prop.Name -ErrorAction SilentlyContinue
                Write-Host "[ACTION] Removed registry entry with name '$($prop.Name)' matching '$keyword' in key '$RegistryKey'." -ForegroundColor Magenta
            }
        }
    }
}

# ================================================================
# Folder Operation Functions
# ================================================================
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
        Write-Host "[ERROR] Folder path '$FolderPath' does not exist. Skipping move operation." -ForegroundColor Red
        return $FolderPath
    }
    $folderName   = [System.IO.Path]::GetFileName($FolderPath)
    $newFolderPath = Join-Path $NewLocation $folderName
    try {
        Move-Item -Path $FolderPath -Destination $newFolderPath -ErrorAction Stop
        Write-Host "[LOG] Folder moved to: $newFolderPath" -ForegroundColor Green
        return $newFolderPath
    }
    catch {
        Write-Host "[ERROR] Failed to move folder from '$FolderPath' to '$newFolderPath'. $_" -ForegroundColor Red
        exit
    }
}

function Hide-Folder {
    param([string]$FolderPath)
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[ERROR] Cannot hide folder. '$FolderPath' does not exist." -ForegroundColor Red
        exit
    }
    $cmd = "attrib +h +s `"$FolderPath`""
    Invoke-Expression $cmd
    Write-Host "[LOG] Folder hidden: $FolderPath" -ForegroundColor DarkCyan
}

function Unhide-Folder {
    param([string]$FolderPath)
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[ERROR] Cannot unhide folder. '$FolderPath' does not exist." -ForegroundColor Red
        exit
    }
    $cmd = "attrib -h -s `"$FolderPath`""
    Invoke-Expression $cmd
    Write-Host "[LOG] Folder unhidden: $FolderPath" -ForegroundColor Green
}

function Rename-Folder {
    param(
        [string]$FolderPath,
        [string]$NewName
    )
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[ERROR] Folder path '$FolderPath' does not exist for renaming. Skipping rename." -ForegroundColor Red
        return $FolderPath
    }
    $parentPath = [System.IO.Path]::GetDirectoryName($FolderPath)
    try {
        Rename-Item -Path $FolderPath -NewName $NewName -ErrorAction Stop
        $newFolderPath = Join-Path $parentPath $NewName
        Write-Host "[LOG] Folder renamed to: $newFolderPath" -ForegroundColor Green
        return $newFolderPath
    }
    catch {
        Write-Host "[ERROR] Failed to rename folder '$FolderPath' to '$NewName'. $_" -ForegroundColor Red
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
        Write-Host "[WARN] Folder '$FolderPath' not found. It may have already been reverted. Skipping revert operations." -ForegroundColor Yellow
        return $OriginalPath
    }
    Unhide-Folder -FolderPath $FolderPath
    $FolderPath = Rename-Folder -FolderPath $FolderPath -NewName $OriginalFolderName
    $FolderPath = Move-Folder -FolderPath $FolderPath -NewLocation $OriginalPath
    Write-Host "[LOG] Folder reverted to original state: $FolderPath" -ForegroundColor DarkYellow
    return $FolderPath
}

function Apply-Modification {
    param([string]$CurrentFolder)
    $newFolder = Move-Folder -FolderPath $CurrentFolder -NewLocation $moveToPath
    $newFolder = Rename-Folder -FolderPath $newFolder -NewName $renamedFolderName
    Hide-Folder -FolderPath $newFolder
    Write-Host "[LOG] Folder modifications applied: $newFolder" -ForegroundColor DarkYellow
    return $newFolder
}

# ================================================================
# Initialize Folder Settings and Apply Modifications
# ================================================================
$folderPath         = $originalPath
$originalFolderName = [System.IO.Path]::GetFileName($originalPath)
$renamedFolderName  = Get-RandomFolderName
$modifiedState = $true

Write-Host "[LOG] Applying initial folder modifications..." -ForegroundColor Green
Start-Spinner -Duration 3
$folderPath = Apply-Modification -CurrentFolder $folderPath
Write-Host "[LOG] Folder operations complete." -ForegroundColor Green

# ================================================================
# Perform Registry Cleanup If Requested
# ================================================================
if (($regCleanupKeyInput -ne "") -and ($keywords.Count -gt 0)) {
    Write-Host "[LOG] Performing registry cleanup on key: $regCleanupKeyInput" -ForegroundColor Cyan
    Clean-RegistryKey -RegistryKey $regCleanupKeyInput -Keywords $keywords
} else {
    Write-Host "[LOG] Registry cleanup skipped (no key or keywords provided)." -ForegroundColor Yellow
}

# ================================================================
# Monitoring Loop with Toggle Mechanism
# ================================================================
Write-Host "[LOG] Monitoring folder modifications... (Press '$hotkey' to toggle modifications)" -ForegroundColor Yellow
while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true).KeyChar
        if ($key -eq $hotkey) {
            if ($modifiedState) {
                Write-Host "[LOG] Reverting changes..." -ForegroundColor Red
                Start-Spinner -Duration 2
                $folderPath = Revert-All -FolderPath $folderPath -OriginalFolderName $originalFolderName -OriginalPath $originalPath
                $modifiedState = $false
            } else {
                Write-Host "[LOG] Re-applying modifications..." -ForegroundColor Red
                Start-Spinner -Duration 2
                $folderPath = Apply-Modification -CurrentFolder $folderPath
                $modifiedState = $true
            }
        }
    }
    Start-Sleep -Seconds 1
}
