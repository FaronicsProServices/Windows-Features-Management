# Taskbar Customization Script for System-Wide Deployment
# Compatible with MECM and other deployment tools

# Elevate to system context if not already running as SYSTEM
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
    Write-Host "This script requires system-level access. Attempting to elevate..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to modify registry for all users
function Set-RegistryForAllUsers {
    param(
        [string]$KeyPath,
        [string]$ValueName,
        [object]$Value,
        [string]$Type = "DWord"
    )

    # Create the key path if it doesn't exist
    if (!(Test-Path $KeyPath)) {
        New-Item -Path $KeyPath -Force | Out-Null
    }

    # Set the registry value
    try {
        Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $Value -Type $Type -ErrorAction Stop
        Write-Host "Successfully set $ValueName in $KeyPath"
    }
    catch {
        Write-Host "Failed to set $ValueName in $KeyPath. Error: $_"
    }
}

# 1. Hide Clock (Machine-Wide)
$clockRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-RegistryForAllUsers -KeyPath $clockRegPath -ValueName "HideClock" -Value 1

# 2. Disable Widgets Policy
$widgetsRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
Set-RegistryForAllUsers -KeyPath $widgetsRegPath -ValueName "AllowNewsAndInterests" -Value 0

# 3. Disable Pinning to Taskbar
$taskbarRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
Set-RegistryForAllUsers -KeyPath $taskbarRegPath -ValueName "NoPinningToTaskbar" -Value 1

# 4. Disable Taskbar Widgets
$widgetsTaskbarRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
Set-RegistryForAllUsers -KeyPath $widgetsTaskbarRegPath -ValueName "EnableFeeds" -Value 0

# 5. Restart Windows Explorer to apply changes
try {
    Stop-Process -Name "explorer" -Force
    Start-Process "explorer.exe"
    Write-Host "Windows Explorer restarted successfully."
}
catch {
    Write-Host "Failed to restart Windows Explorer. Manual restart may be required."
}

Write-Host "Taskbar customization script completed successfully."

# Logging for deployment tools
exit 0
