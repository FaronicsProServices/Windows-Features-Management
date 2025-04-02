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

# Function to set registry value safely
function Set-RegistryValueSafely {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value
    )
    try {
        # Check if the key exists
        if (!(Test-Path $Path)) {
            Write-Log "Creating registry path: $Path"
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-Log "Successfully set registry value $Name at $Path"
        return $true
    }
    catch {
        Write-Log "Error setting registry value: $_"
        return $false
    }
}

# Function to get psexec path
function Get-PsExecPath {
    $possiblePaths = @(
        "$env:SystemRoot\System32\psexec.exe",
        "$env:SystemRoot\SysWOW64\psexec.exe",
        "$env:ProgramFiles\Sysinternals\psexec.exe",
        "$env:ProgramFiles(x86)\Sysinternals\psexec.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# Main script execution
try {
    Write-Log "Starting Taskbar Customization script..."

    # Get psexec path
    $psexecPath = Get-PsExecPath
    if (-not $psexecPath) {
        Write-Log "Warning: psexec.exe not found. Some features may not work."
    }

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
        Set-RegistryValueSafely -Path $regPath -Name $keyName -Value $keyValue
    }

    # 2. Disable Allow Widgets via Group Policy (HKLM - works for all users)
    $widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
    $widgetsKeyName = "AllowNewsAndInterests"
    $widgetsValue = 0

    Write-Log "Disabling Allow Widgets policy..."
    Set-RegistryValueSafely -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue

    # 3. Enable "Remove pinned programs from the taskbar" Policy (HKLM - works for all users)
    $taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
    $taskbarKeyName = "NoPinningToTaskbar"
    $taskbarValue = 1

    Write-Log "Enabling 'Remove pinned programs from the taskbar' policy..."
    Set-RegistryValueSafely -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue

    # 4. Open System Icons Configuration Panel for each user
    if ($psexecPath) {
        foreach ($sid in $userSIDs) {
            Write-Log "Opening system icons configuration panel for user $sid..."
            try {
                Start-Process $psexecPath -ArgumentList "-i -u $sid explorer.exe shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons" -WindowStyle Hidden -Wait
                Write-Log "Successfully opened system icons panel for user $sid"
            }
            catch {
                Write-Log "Failed to open system icons panel for user $sid: $_"
            }
        }
    }
    else {
        Write-Log "Skipping system icons configuration panel - psexec not available"
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
