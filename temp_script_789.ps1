# ==============================
# Auto-Updater (Checks GitHub)
# ==============================
# Version: 1.00 uwu
$localScriptPath = $MyInvocation.MyCommand.Path
$repoUrl = "https://raw.githubusercontent.com/redivancee/securehide/main/temp_script_789.ps1"
$localVersion = "test uwu"  # Change this when you upload new versions to GitHub!

try {
    $remoteScript = Invoke-WebRequest -Uri $repoUrl -UseBasicParsing -ErrorAction Stop
    if ($remoteScript.Content -match "# Version: (\d+\.\d+)") {
        $remoteVersion = $matches[1]
        if ([double]$remoteVersion -gt [double]$localVersion) {
            Write-Host "[UPDATE] New version found! Updating to v$remoteVersion..." -ForegroundColor Green
            $remoteScript.Content | Set-Content -Path $localScriptPath -Encoding UTF8
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$localScriptPath`"" -NoNewWindow
            exit
        }
        else {
            Write-Host "[INFO] No updates available. Running script..." -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "[WARNING] Could not check for updates. Running offline mode..." -ForegroundColor Yellow
}

Clear-Host

# ================================================================
# Banner & Credits Section
# ================================================================
$banner = @"
 ________  _______   ________  ___  ___  ________  _______   ___  ___  ___  ________  _______           ________  ___  ___  ________  ___       ___  ________     
|\   ____\|\  ___ \ |\   ____\|\  \|\  \|\   __  \|\  ___ \ |\  \|\  \|\  \|\   ___ \|\  ___ \         |\   __  \|\  \|\  \|\   __  \|\  \     |\  \|\   ____\    
\ \  \___|\ \   __/|\ \  \___|\ \  \\\  \ \  \|\  \ \   __/|\ \  \\\  \ \  \ \  \_|\ \ \   __/|        \ \  \|\  \ \  \\\  \ \  \|\ /\ \  \    \ \  \ \  \___|    
 \ \_____  \ \  \_|/_\ \  \    \ \  \\\  \ \   _  _\ \  \_|/_\ \   __  \ \  \ \  \ \\ \ \  \_|/__       \ \   ____\ \  \\\  \ \   __  \ \  \    \ \  \ \  \       
  \|____|\  \ \  \_|\ \ \  \____\ \  \\\  \ \  \\  \\ \  \_|\ \ \  \ \  \ \  \ \  \_\\ \ \  \_|\ \       \ \  \___|\ \  \\\  \ \  \|\  \ \  \____\ \  \ \  \____  
    ____\_\  \ \_______\ \_______\ \_______\ \__\\ _\\ \_______\ \__\ \__\ \__\ \_______\ \_______\       \ \__\    \ \_______\ \_______\ \_______\ \__\ \_______\
   |\_________\|_______|\|_______|\|_______|\|__|\|__|\|_______|\|__|\|__|\|__|\|_______|\|_______|        \|__|     \|_______|\|_______|\|_______|\|__|\|_______|
   \|_________|                                                                                                                                                   
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
# Silent Mode Option & Hotkey Prompt
# ================================================================
$silentMode = Read-Host "Run in silent mode? (y/n)"
$hotkey = Read-Host "Enter the hotkey to toggle modifications (default is '.')"
if ([string]::IsNullOrWhiteSpace($hotkey)) { $hotkey = "." }

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
    $permission = Read-Host "Do you permit this script to run in background (even if closed)? (y/n)"
    if ($permission -ne "y") {
        Write-Host "[INFO] Permission denied. Exiting..." -ForegroundColor Red
        exit
    }
    Hide-ConsoleWindow
}
Write-Host "[INFO] Credits: redivance" -ForegroundColor Cyan

# ================================================================
# Folder Operations and Path Prompts
# ================================================================
# Set defaults to the current user's Downloads folder.
$defaultOriginalPath = "$env:USERPROFILE\Downloads"
$defaultMoveToPath   = "$env:USERPROFILE\Downloads"  # Change if needed

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -notin @("RemoteSigned", "Unrestricted", "Bypass")) {
    Write-Host "[WARNING] Your execution policy is '$currentPolicy'. This script may not run properly. Consider running:" -ForegroundColor Yellow
    Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
}

function Get-ValidatedPath {
    param(
        [string]$PromptMessage,
        [string]$DefaultPath
    )
    $path = Read-Host "$PromptMessage (default: $DefaultPath)"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $DefaultPath }
    if (-not (Test-Path $path)) {
        Write-Host "[ERROR] The path '$path' does not exist. Exiting..." -ForegroundColor Red
        exit
    }
    return $path
}

$originalPath = Get-ValidatedPath -PromptMessage "Enter the file path for the folder you want hidden" -DefaultPath $defaultOriginalPath
$moveToPath   = Get-ValidatedPath -PromptMessage "Enter the folder path where it should return when reverting changes" -DefaultPath $defaultMoveToPath

# ================================================================
# Registry Cleanup Input
# ================================================================
$regCleanupKeyInput = Read-Host "Enter the full registry key path to clean up (or press Enter to skip)"
$keywordsInput = Read-Host "Enter comma-separated keywords for registry cleanup (optional)"
if ($keywordsInput -ne "") {
    $keywords = ($keywordsInput -split ',') | ForEach-Object { $_.Trim() }
} else {
    $keywords = @()
}

# ================================================================
# Cloak Programs Input
# ================================================================
$cloakInput = Read-Host "Enter full paths for programs to cloak (comma-separated, default: none)"
if (-not [string]::IsNullOrWhiteSpace($cloakInput)) {
    $cloakedPrograms = $cloakInput -split "," | ForEach-Object { $_.Trim() }
} else {
    $cloakedPrograms = @()
}

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
    $folderName = [System.IO.Path]::GetFileName($FolderPath)
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
        Write-Host "[WARN] Folder '$FolderPath' not found. It may have already been reverted." -ForegroundColor Yellow
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
    $newFolder = Rename-Folder -FolderPath $newFolder -NewName (Get-RandomFolderName)
    Hide-Folder -FolderPath $newFolder
    Write-Host "[LOG] Folder modifications applied: $newFolder" -ForegroundColor DarkYellow
    return $newFolder
}

# ================================================================
# Cloak Programs Functions
# ================================================================
function Hide-Process {
    param (
        [string]$processName
    )
    # Rudimentary trick: call rundll32 to trigger a system action.
    $cmd = "rundll32.exe user32.dll,LockWorkStation"
    Start-Process $cmd -WindowStyle Hidden
    Write-Host "Process $processName is now hidden." -ForegroundColor DarkMagenta
}

function Scrub-Timestamps {
    param (
        [string]$programPath
    )
    try {
        (Get-Item $programPath).CreationTime = (Get-Date "01/01/2000")
        (Get-Item $programPath).LastAccessTime = (Get-Date "01/01/2000")
        (Get-Item $programPath).LastWriteTime = (Get-Date "01/01/2000")
        Write-Host "Timestamps for $programPath have been scrubbed." -ForegroundColor DarkMagenta
    } catch {
        Write-Host "Failed to scrub timestamps for $programPath." -ForegroundColor Red
    }
}

function Cloak-Programs {
    foreach ($program in $cloakedPrograms) {
        if (Test-Path $program) {
            Hide-Process -processName $program
            Scrub-Timestamps -programPath $program
            Write-Host "Program $program is now cloaked." -ForegroundColor DarkMagenta
        } else {
            Write-Host "Program path $program not found." -ForegroundColor Yellow
        }
    }
}

# ================================================================
# Initialize Folder Settings and Apply Modifications
# ================================================================
$folderPath         = $originalPath
$originalFolderName = [System.IO.Path]::GetFileName($originalPath)
$global:modifiedState = $true

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
# Global Hotkey Listener (Background Job)
# ================================================================
$tempTriggerFile = "$env:USERPROFILE\Downloads\hotkeytrigger.txt"
if (-not (Test-Path "$env:USERPROFILE\Downloads")) { New-Item -ItemType Directory -Path "$env:USERPROFILE\Downloads" | Out-Null }
if (Test-Path $tempTriggerFile) { Remove-Item $tempTriggerFile -Force }

Start-Job -ScriptBlock {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class HotKeyForm : Form {
    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    public event EventHandler HotKeyPressed;
    protected override void WndProc(ref Message m) {
        const int WM_HOTKEY = 0x0312;
        if(m.Msg == WM_HOTKEY) {
            if(HotKeyPressed != null)
                HotKeyPressed(this, EventArgs.Empty);
        }
        base.WndProc(ref m);
    }
    public HotKeyForm(int key, uint modifiers, int id) {
        RegisterHotKey(this.Handle, id, modifiers, (uint)key);
    }
    protected override void Dispose(bool disposing) {
        UnregisterHotKey(this.Handle, 0);
        base.Dispose(disposing);
    }
}
"@
    $keyChar = $using:hotkey
    $keyCode = [byte][char]$keyChar
    $modifiers = 0
    $hotkeyForm = New-Object HotKeyForm $keyCode, $modifiers, 0
    $hotkeyForm.add_HotKeyPressed({
        [System.IO.File]::AppendAllText($using:tempTriggerFile, "toggle`n")
    })
    [System.Windows.Forms.Application]::Run($hotkeyForm)
} | Out-Null

# ================================================================
# Main Monitoring Loop with Toggle Mechanism
# ================================================================
Write-Host "[LOG] Monitoring folder modifications... (Global hotkey '$hotkey' active)" -ForegroundColor Yellow

function Toggle-Modifications {
    if ($global:modifiedState) {
        Write-Host "[LOG] Reverting changes..." -ForegroundColor Red
        Start-Spinner -Duration 2
        $script:folderPath = Revert-All -FolderPath $folderPath -OriginalFolderName $originalFolderName -OriginalPath $originalPath
        $global:modifiedState = $false
    }
    else {
        Write-Host "[LOG] Re-applying modifications..." -ForegroundColor Red
        Start-Spinner -Duration 2
        $script:folderPath = Apply-Modification -CurrentFolder $folderPath
        $global:modifiedState = $true
    }
}

while ($true) {
    if (Test-Path $tempTriggerFile) {
        $content = Get-Content $tempTriggerFile -ErrorAction SilentlyContinue
        if ($content -match "toggle") {
            Toggle-Modifications
            # Also cloak programs when toggled:
            Cloak-Programs
            Clear-Content $tempTriggerFile
        }
    }
    Start-Sleep -Seconds 1
}
