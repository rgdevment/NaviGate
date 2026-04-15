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

Write-Host "`nNaviGate Dev Cleanup" -ForegroundColor White
if ($DryRun) { Write-Host "(DRY RUN - nothing will be deleted)" -ForegroundColor Yellow }

if (-not $SkipRegistry) {
    Write-Section "Registry: NaviGate registration (HKCU)"

    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\NaviGateURL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Classes\NaviGate.URL"
    Remove-RegistryPath "HKCU:\SOFTWARE\Clients\StartMenuInternet\NaviGate"
    Remove-RegistryPath "HKCU:\SOFTWARE\NaviGate"
    Remove-RegistryValue "HKCU:\SOFTWARE\RegisteredApplications" "NaviGate"

    Write-Section "Registry: URL association toasts"

    Remove-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" "NaviGate.URL_http"
    Remove-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" "NaviGate.URL_https"
    Remove-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" "NaviGateURL_http"
    Remove-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" "NaviGateURL_https"

    Write-Section "Registry: File extension associations"

    $openWithPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\OpenWithList"
    if (Test-Path $openWithPath) {
        Get-ItemProperty -Path $openWithPath -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -match '^[a-z]$' } |
            ForEach-Object {
                $propName = $_.Name
                $propVal = (Get-ItemProperty -Path $openWithPath).$propName
                if ($propVal -eq 'navigate.exe') {
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

    Remove-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "NaviGate"
    Remove-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "navigate"

    Write-Section "Registry: MuiCache entries"

    $muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $muiPath) {
        Get-ItemProperty -Path $muiPath -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -like '*navigate*' -or $_.Name -like '*NaviGate*' } |
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
}

if (-not $SkipFiles) {
    Write-Section "Files: AppData"

    Remove-Folder "$env:APPDATA\navigate"
    Remove-Folder "$env:APPDATA\com.navigate"

    Write-Section "Files: Temp folders"

    Get-ChildItem -Path $env:TEMP -Directory -Filter "NaviGate*" -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Folder $_.FullName }

    Write-Section "Files: Build outputs"

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    if (-not $projectRoot) { $projectRoot = (Get-Location).Path }
    $buildDir = Join-Path $projectRoot "build"
    Remove-Folder $buildDir

    $appsBuildDir = Join-Path $projectRoot "apps\navigate\build"
    Remove-Folder $appsBuildDir
}

Write-Host "`n--- Done. $removed items cleaned. ---`n" -ForegroundColor White
