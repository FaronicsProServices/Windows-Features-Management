# PowerShell Script for System-Wide Taskbar Customization

# Elevated Privileges Check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRoleAsync([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an Administrator."
    exit
}

# Logging Function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# Function to Modify Registry for All Users
function Set-RegistryForAllUsers {
    param(
        [string]$RegistryPath,
        [string]$KeyName,
        [int]$Value
    )

    try {
        # System-wide registry path
        $systemPath = $RegistryPath -replace "HKCU:", "HKEY_USERS"

        # Load default user hive
        Write-Log "Applying registry setting: $KeyName to default user profile"
        REG LOAD HKU\DefaultUser C:\Users\Default\NTUSER.DAT | Out-Null

        # Modify default user registry
        New-ItemProperty -Path "HKU:\DefaultUser\$($RegistryPath.Split(':')[1])" -Name $KeyName -Value $Value -PropertyType DWord -Force | Out-Null

        # Unload default user hive
        [gc]::Collect()
        REG UNLOAD HKU\DefaultUser | Out-Null

        # Apply to all existing user profiles
        $userProfiles = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.GetValue("ProfileImagePath") -like "C:\Users\*" }

        foreach ($profile in $userProfiles) {
            $sid = $profile.PSChildName
            $userRegPath = "HKU:\$sid\$($RegistryPath.Split(':')[1])"

            try {
                # Ensure registry path exists
                New-Item -Path $userRegPath -Force | Out-Null

                # Set registry key
                Set-ItemProperty -Path $userRegPath -Name $KeyName -Value $Value -ErrorAction Stop
                Write-Log "Applied $KeyName to user profile: $sid"
            }
            catch {
                Write-Log "Could not modify registry for user profile $sid"
            }
        }

        Write-Log "Successfully applied $KeyName system-wide"
    }
    catch {
        Write-Log "Error applying system-wide registry setting: $_"
    }
}

# 1. Hide Clock for All Users
try {
    Write-Log "Configuring system-wide clock visibility..."
    $clockRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    Set-RegistryForAllUsers -RegistryPath $clockRegPath -KeyName "HideClock" -Value 1
}
catch {
    Write-Log "Error configuring clock visibility: $_"
}

# 2. Disable Widgets for All Users
try {
    Write-Log "Disabling widgets system-wide..."
    $widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
    New-Item -Path $widgetsRegPath -Force | Out-Null
    Set-ItemProperty -Path $widgetsRegPath -Name "AllowNewsAndInterests" -Value 0
}
catch {
    Write-Log "Error disabling widgets: $_"
}

# 3. Remove Pinned Programs from Taskbar
try {
    Write-Log "Preventing taskbar pinning system-wide..."
    $taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
    New-Item -Path $taskbarRegPath -Force | Out-Null
    Set-ItemProperty -Path $taskbarRegPath -Name "NoPinningToTaskbar" -Value 1
}
catch {
    Write-Log "Error preventing taskbar pinning: $_"
}

# 4. Optional: Open System Icons Configuration
Write-Log "Opening system icons configuration panel..."
Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"

# 5. Restart Explorer Processes for All Users
try {
    Write-Log "Attempting to restart Explorer for all active sessions..."
    
    # Get all active user sessions
    $sessions = Get-Process -Name explorer | ForEach-Object { 
        try {
            $_.UserName
        }
        catch {
            $null
        }
    } | Where-Object { $_ -ne $null } | Select-Object -Unique

    foreach ($session in $sessions) {
        try {
            Write-Log "Restarting Explorer for user: $session"
            Stop-Process -Name explorer -Force -ErrorAction Stop
        }
        catch {
            Write-Log "Could not restart Explorer for $session"
        }
    }

    # Start Explorer for current user
    Start-Process explorer
    Write-Log "Explorer restart completed."
}
catch {
    Write-Log "Error during Explorer restart: $_"
}

Write-Log "Taskbar customization script completed successfully."
