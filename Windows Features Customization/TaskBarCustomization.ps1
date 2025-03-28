# PowerShell Script for Taskbar Customization
# Designed to run silently and restart Explorer process

# Suppress all error outputs and continue execution
$ErrorActionPreference = 'SilentlyContinue'

# Function to create registry key with error handling
function Set-RegistryKey {
    param (
        [string]$Path,
        [string]$KeyName,
        [int]$Value
    )
    
    try {
        # Ensure the registry path exists
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Set the registry key
        New-ItemProperty -Path $Path -Name $KeyName -Value $Value -PropertyType DWord -Force | Out-Null
    }
    catch {
        Write-Error "Failed to set registry key: $Path\$KeyName"
    }
}

# 1. Hide Clock in Taskbar
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-RegistryKey -Path $regPath -KeyName "HideClock" -Value 1

# 2. Disable Widgets via Group Policy
$widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
Set-RegistryKey -Path $widgetsRegPath -KeyName "AllowNewsAndInterests" -Value 0

# 3. Remove Pinned Programs from Taskbar
$taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
Set-RegistryKey -Path $taskbarRegPath -KeyName "NoPinningToTaskbar" -Value 1

# 4. Additional Taskbar Customization
$additionalTaskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-RegistryKey -Path $additionalTaskbarPath -KeyName "ShowCortanaButton" -Value 0
Set-RegistryKey -Path $additionalTaskbarPath -KeyName "ShowTaskViewButton" -Value 0

# 5. Restart Explorer Process Reliably
$explorerProcess = Get-Process explorer -ErrorAction SilentlyContinue

if ($explorerProcess) {
    # Stop all Explorer processes
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

# Start a new Explorer process
Start-Process explorer.exe

# Exit with success code
exit 0
