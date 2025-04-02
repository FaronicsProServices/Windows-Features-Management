# PowerShell Script for Taskbar Customization (No Restart Required)
# Requires administrative privileges
# Works with SYSTEM account

# Function to write logs
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
    Add-Content -Path "$env:TEMP\TaskbarCustomization.log" -Value "[$timestamp] $Message"
}

# Function to get all user SIDs
function Get-UserSIDs {
    $users = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }
    return $users | ForEach-Object { $_.SID }
}

# Function to safely restart Explorer
function Restart-ExplorerSafely {
    try {
        Write-Log "Attempting to restart Explorer using method 1..."
        
        # Method 1: Using Get-Process and Stop-Process
        $explorer = Get-Process explorer -ErrorAction SilentlyContinue
        if ($explorer) {
            $explorer.CloseMainWindow()
            Start-Sleep -Seconds 2
        }
        
        # Start Explorer using Start-Process
        Start-Process explorer
        Write-Log "Explorer restarted successfully using method 1."
    }
    catch {
        Write-Log "Method 1 failed. Attempting method 2..."
        try {
            # Method 2: Using WMI
            $shell = New-Object -ComObject Shell.Application
            $shell.Windows() | ForEach-Object { $_.Quit() }
            Start-Sleep -Seconds 2
            Start-Process explorer
            Write-Log "Explorer restarted successfully using method 2."
        }
        catch {
            Write-Log "Method 2 failed. Attempting method 3..."
            try {
                # Method 3: Using taskkill and start
                Start-Process cmd -ArgumentList "/c taskkill /f /im explorer.exe & start explorer.exe" -WindowStyle Hidden
                Write-Log "Explorer restart command sent using method 3."
            }
            catch {
                Write-Log "All restart methods failed. Please restart manually."
                Write-Log "Error: ${_}"
            }
        }
    }
}

# Function to set registry value safely
function Set-RegistryValueSafely {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value
    )
    try {
        # Create the registry key using reg.exe
        $regPath = $Path.Replace("Registry::", "").Replace("HKLM:", "HKLM").Replace("HKCU:", "HKCU")
        $regCommand = "reg add `"$regPath`" /f"
        $result = Invoke-Expression $regCommand
        if ($LASTEXITCODE -eq 0) {
            # Set the value using reg.exe
            $regCommand = "reg add `"$regPath`" /v `"$Name`" /t REG_DWORD /d $Value /f"
            $result = Invoke-Expression $regCommand
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully set registry value $Name at $Path"
                return $true
            }
        }
        Write-Log "Failed to set registry value using reg.exe"
        return $false
    }
    catch {
        Write-Log "Error setting registry value: ${_}"
        return $false
    }
}

# Main script execution
try {
    Write-Log "Starting Taskbar Customization script..."

    # Get all user SIDs
    $userSIDs = Get-UserSIDs
    Write-Log "Found $($userSIDs.Count) user profiles"

    # 1. Add HideClock Registry Key for each user
    foreach ($sid in $userSIDs) {
        Write-Log "Processing user SID: $sid"
        $regPath = "HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        $keyName = "HideClock"
        $keyValue = 1

        Write-Log "Creating registry key to hide the clock for user $sid..."
        Set-RegistryValueSafely -Path $regPath -Name $keyName -Value $keyValue
    }

    # 2. Disable Allow Widgets via Group Policy (HKLM - works for all users)
    $widgetsRegPath = "HKLM\Software\Policies\Microsoft\Dsh"
    $widgetsKeyName = "AllowNewsAndInterests"
    $widgetsValue = 0

    Write-Log "Disabling Allow Widgets policy..."
    Set-RegistryValueSafely -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue

    # 3. Enable "Remove pinned programs from the taskbar" Policy (HKLM - works for all users)
    $taskbarRegPath = "HKLM\Software\Policies\Microsoft\Windows\Explorer"
    $taskbarKeyName = "NoPinningToTaskbar"
    $taskbarValue = 1

    Write-Log "Enabling 'Remove pinned programs from the taskbar' policy..."
    Set-RegistryValueSafely -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue

    # 4. Create a scheduled task to open System Icons Configuration Panel for each user
    foreach ($sid in $userSIDs) {
        Write-Log "Creating scheduled task for user $sid to open system icons panel..."
        try {
            $taskName = "OpenSystemIcons_$($sid.Replace('-', '_'))"
            $taskCommand = "explorer.exe shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"
            
            # Create the scheduled task
            $taskAction = New-ScheduledTaskAction -Execute $taskCommand
            $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
            $taskPrincipal = New-ScheduledTaskPrincipal -UserId $sid -LogonType Interactive -RunLevel Highest
            
            Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Force | Out-Null
            Write-Log "Successfully created scheduled task for user $sid"
        }
        catch {
            Write-Log "Failed to create scheduled task for user $sid: ${_}"
        }
    }

    # 5. Restart Explorer using the safe method
    Write-Log "Initiating safe Explorer restart..."
    Restart-ExplorerSafely

    Write-Log "Taskbar customization completed successfully."
}
catch {
    Write-Log "An error occurred during script execution: ${_}"
    exit 1
} 
