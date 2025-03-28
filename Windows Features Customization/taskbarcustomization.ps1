# PowerShell Script for System-Wide Taskbar Customization

# Elevated Privileges Check
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-NOT $windowsPrincipal.IsInRole($adminRole)) {
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
        # Ensure HKU drive is loaded
        if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
            New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
        }

        # Load default user hive
        Write-Log "Applying registry setting: $KeyName to default user profile"
        $defaultProfilePath = "C:\Users\Default\NTUSER.DAT"
        
        if (Test-Path $defaultProfilePath) {
            reg load HKU\DefaultUser $defaultProfilePath | Out-Null

            # Modify default user registry
            $fullKeyPath = "HKU:\DefaultUser\$($RegistryPath.Split(':')[1])"
            
            # Ensure path exists
            $parentPath = Split-Path $fullKeyPath
            if (-not (Test-Path $parentPath)) {
                New-Item -Path $parentPath -Force | Out-Null
            }

            New-ItemProperty -Path $fullKeyPath -Name $KeyName -Value $Value -PropertyType DWord -Force | Out-Null

            # Unload default user hive
            [gc]::Collect()
            reg unload HKU\DefaultUser | Out-Null
        }

        # Apply to all existing user profiles
        $userProfiles = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | 
            Where-Object { 
                $_.PSChildName -match "^S-1-5-21-" -and 
                ($_.GetValue("ProfileImagePath") -like "C:\Users\*" -or $_.GetValue("ProfileImagePath") -like "C:\Windows\System32\config\*")
            }

        foreach ($profile in $userProfiles) {
            $sid = $profile.PSChildName
            $userRegPath = "HKU:\$sid\$($RegistryPath.Split(':')[1])"

            try {
                # Ensure registry path exists
                $parentPath = Split-Path $userRegPath
                if (-not (Test-Path $parentPath)) {
                    New-Item -Path $parentPath -Force | Out-Null
                }

                # Set registry key
                New-ItemProperty -Path $userRegPath -Name $KeyName -Value $Value -PropertyType DWord -Force | Out-Null
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
