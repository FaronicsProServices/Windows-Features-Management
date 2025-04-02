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
                Write-Log "Error: $_"
            }
        }
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
        $regPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        $keyName = "HideClock"
        $keyValue = 1

        Write-Log "Creating registry key to hide the clock for user $sid..."
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue
        Write-Log "Registry key HideClock added successfully for user $sid."
    }

    # 2. Disable Allow Widgets via Group Policy (HKLM - works for all users)
    $widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
    $widgetsKeyName = "AllowNewsAndInterests"
    $widgetsValue = 0

    Write-Log "Disabling Allow Widgets policy..."
    New-Item -Path $widgetsRegPath -Force | Out-Null
    Set-ItemProperty -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue
    Write-Log "Allow Widgets policy disabled."

    # 3. Enable "Remove pinned programs from the taskbar" Policy (HKLM - works for all users)
    $taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
    $taskbarKeyName = "NoPinningToTaskbar"
    $taskbarValue = 1

    Write-Log "Enabling 'Remove pinned programs from the taskbar' policy..."
    New-Item -Path $taskbarRegPath -Force | Out-Null
    Set-ItemProperty -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue
    Write-Log "'Remove pinned programs from the taskbar' policy enabled."

    # 4. Open System Icons Configuration Panel for each user
    foreach ($sid in $userSIDs) {
        Write-Log "Opening system icons configuration panel for user $sid..."
        # Use psexec to run the command in user context
        Start-Process "psexec.exe" -ArgumentList "-i -u $sid explorer.exe shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons" -WindowStyle Hidden
    }

    # 5. Restart Explorer using the safe method
    Write-Log "Initiating safe Explorer restart..."
    Restart-ExplorerSafely

    Write-Log "Taskbar customization completed successfully."
}
catch {
    Write-Log "An error occurred during script execution: $_"
    exit 1
} 