#Requires -Version 5.1
param(
    [switch]$DryRun,
    [switch]$SkipRegistry,
    [switch]$SkipFiles
)

$ErrorActionPreference = 'Continue'

function Write-Step($msg) { Write-Host "  [-] $msg" -ForegroundColor DarkGray }
function Write-Done($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  [--] $msg" -ForegroundColor Yellow }
function Write-Section($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

$removed = 0

function Remove-RegistryPath([string]$Path) {
    if (Test-Path $Path) {
        if ($DryRun) { Write-Step "Would remove: $Path"; return }
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Done "Removed: $Path"
        $script:removed++
    }
}

function Remove-RegistryValue([string]$Path, [string]$Name) {
    if (Test-Path $Path) {
        $val = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $val.$Name) {
            if ($DryRun) { Write-Step "Would remove value: $Path\$Name"; return }
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Done "Removed value: $Path\$Name"
            $script:removed++
        }
    }
}

function Remove-Folder([string]$Path) {
    if (Test-Path $Path) {
        if ($DryRun) { Write-Step "Would remove: $Path"; return }
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Done "Removed: $Path"
        $script:removed++
    }
}

Write-Host "`nLinkUnbound Dev Cleanup" -ForegroundColor White
if ($DryRun) { Write-Host "(DRY RUN - nothing will be deleted)" -ForegroundColor Yellow }

if (-not $SkipRegistry) {
    Write-Section "Registry: LinkUnbound registration (HKCU)"

    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\LinkUnboundURL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Clients\StartMenuInternet\LinkUnbound"
    Remove-RegistryPath "HKCU:\SOFTWARE\LinkUnbound"
    Remove-RegistryValue "HKCU:\SOFTWARE\RegisteredApplications" "LinkUnbound"

    # Legacy Navigate keys
    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\NavigateURL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\Navigate.URL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Clients\StartMenuInternet\Navigate"
    Remove-RegistryPath "HKCU:\SOFTWARE\Navigate"
    Remove-RegistryValue "HKCU:\SOFTWARE\RegisteredApplications" "Navigate"

    # Legacy NaviGate keys
    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\NaviGateURL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\NaviGate.URL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Clients\StartMenuInternet\NaviGate"
    Remove-RegistryPath "HKCU:\SOFTWARE\NaviGate"
    Remove-RegistryValue "HKCU:\SOFTWARE\RegisteredApplications" "NaviGate"

    Write-Section "Registry: URL default browser (UserChoice)"

    @("http", "https") | ForEach-Object {
        $proto = $_
        $ucPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$proto\UserChoice"
        $ucVal = Get-ItemProperty $ucPath -ErrorAction SilentlyContinue
        if ($ucVal -and ($ucVal.ProgId -like '*LinkUnbound*' -or $ucVal.ProgId -like '*Navigate*' -or $ucVal.ProgId -like '*NaviGate*')) {
            if ($DryRun) { Write-Step "Would remove: $ucPath (ProgId=$($ucVal.ProgId))" }
            else {
                try {
                    Remove-Item $ucPath -Force -ErrorAction Stop
                    Write-Done "Removed $proto UserChoice (was $($ucVal.ProgId))"
                    $script:removed++
                } catch {
                    Write-Skip "Cannot remove $proto UserChoice (protected) — change default browser in Windows Settings"
                }
            }
        }
    }

    Write-Section "Registry: File association UserChoice"

    @(".html", ".htm", ".pdf", ".mhtml", ".mht", ".shtml", ".xhtml", ".xht", ".svg", ".webp") | ForEach-Object {
        $ext = $_
        $ucPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice"
        $ucVal = Get-ItemProperty $ucPath -ErrorAction SilentlyContinue
        if ($ucVal -and ($ucVal.ProgId -like '*LinkUnbound*' -or $ucVal.ProgId -like '*Navigate*' -or $ucVal.ProgId -like '*NaviGate*')) {
            if ($DryRun) { Write-Step "Would remove: $ucPath (ProgId=$($ucVal.ProgId))" }
            else {
                try {
                    Remove-Item $ucPath -Force -ErrorAction Stop
                    Write-Done "Removed $ext UserChoice (was $($ucVal.ProgId))"
                    $script:removed++
                } catch {
                    Write-Skip "Cannot remove $ext UserChoice (protected) — reassociate in Windows Settings"
                }
            }
        }
    }

    Write-Section "Registry: OpenWithProgids"

    @(".html", ".htm", ".pdf", ".mhtml", ".mht", ".shtml", ".xhtml", ".xht", ".svg", ".webp") | ForEach-Object {
        $owpPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$_\OpenWithProgids"
        if (Test-Path $owpPath) {
            @("LinkUnboundURL", "NavigateURL", "NaviGateURL", "NaviGate.URL") | ForEach-Object {
                $progId = $_
                $val = Get-ItemProperty -Path $owpPath -Name $progId -ErrorAction SilentlyContinue
                if ($null -ne $val.$progId) {
                    if ($DryRun) { Write-Step "Would remove OpenWithProgids: $progId" }
                    else {
                        Remove-ItemProperty -Path $owpPath -Name $progId -Force -ErrorAction SilentlyContinue
                        Write-Done "Removed OpenWithProgids: $progId"
                        $script:removed++
                    }
                }
            }
        }
    }

    Write-Section "Registry: URL association toasts"

    $toastsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts"
    if (Test-Path $toastsPath) {
        Get-ItemProperty -Path $toastsPath -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -like '*LinkUnbound*' -or $_.Name -like '*Navigate*' -or $_.Name -like '*NaviGate*' } |
            ForEach-Object {
                $propName = $_.Name
                if ($DryRun) { Write-Step "Would remove toast: $propName" }
                else {
                    Remove-ItemProperty -Path $toastsPath -Name $propName -Force -ErrorAction SilentlyContinue
                    Write-Done "Removed toast: $propName"
                    $script:removed++
                }
            }
    }

    Write-Section "Registry: File extension associations"

    $openWithPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\OpenWithList"
    if (Test-Path $openWithPath) {
        Get-ItemProperty -Path $openWithPath -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -match '^[a-z]$' } |
            ForEach-Object {
                $propName = $_.Name
                $propVal = (Get-ItemProperty -Path $openWithPath).$propName
                if ($propVal -eq 'linkunbound.exe' -or $propVal -eq 'navigate.exe') {
                    if ($DryRun) { Write-Step "Would remove value: $openWithPath\$propName" }
                    else {
                        Remove-ItemProperty -Path $openWithPath -Name $propName -Force -ErrorAction SilentlyContinue
                        Write-Done "Removed value: $openWithPath\$propName"
                        $script:removed++
                    }
                }
            }
    }

    Write-Section "Registry: Startup (HKCU Run)"

    Remove-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "LinkUnbound"
    Remove-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "Navigate"
    Remove-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "NaviGate"
    Remove-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "navigate"

    Write-Section "Registry: MuiCache entries"

    $muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $muiPath) {
        Get-ItemProperty -Path $muiPath -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -like '*linkunbound*' -or $_.Name -like '*LinkUnbound*' -or $_.Name -like '*navigate*' -or $_.Name -like '*NaviGate*' } |
            ForEach-Object {
                $propName = $_.Name
                if ($DryRun) { Write-Step "Would remove MuiCache: $propName" }
                else {
                    Remove-ItemProperty -Path $muiPath -Name $propName -Force -ErrorAction SilentlyContinue
                    Write-Done "Removed MuiCache: $propName"
                    $script:removed++
                }
            }
    }

    # Notify Windows shell that associations changed
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class ShellNotify {
            [DllImport("shell32.dll")]
            public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
            public static void NotifyAssocChanged() { SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero); }
        }
"@ -ErrorAction SilentlyContinue
    try { [ShellNotify]::NotifyAssocChanged(); Write-Done "Shell notified of association changes" } catch {}
}

if (-not $SkipFiles) {
    Write-Section "Files: AppData"

    Remove-Folder "$env:APPDATA\LinkUnbound"
    Remove-Folder "$env:APPDATA\Navigate"
    Remove-Folder "$env:APPDATA\navigate"
    Remove-Folder "$env:APPDATA\com.navigate"

    Write-Section "Files: Temp folders"

    Get-ChildItem -Path $env:TEMP -Directory -Filter "linkunbound*" -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Folder $_.FullName }
    Get-ChildItem -Path $env:TEMP -Directory -Filter "navigate*" -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Folder $_.FullName }
    Get-ChildItem -Path $env:TEMP -Directory -Filter "Navigate*" -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Folder $_.FullName }

    Write-Section "Files: Build outputs"

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    if (-not $projectRoot) { $projectRoot = (Get-Location).Path }
    $buildDir = Join-Path $projectRoot "build"
    Remove-Folder $buildDir

    $appsBuildDir = Join-Path $projectRoot "apps\linkunbound\build"
    Remove-Folder $appsBuildDir
}

Write-Host "`n--- Done. $removed items cleaned. ---`n" -ForegroundColor White
