# PowerShell Script for Taskbar Customization (Deployment-Friendly)
param(
    [switch]$Force = $false
)

# Logging Function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# 1. Add HideClock Registry Key
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $keyName = "HideClock"
    $keyValue = 1
    
    Write-Log "Creating registry key to hide the clock..."
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue -ErrorAction Stop
    Write-Log "Registry key HideClock added successfully."
}
catch {
    Write-Log "Error adding HideClock registry key: $_"
}

# 2. Disable Allow Widgets via Group Policy
try {
    $widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
    $widgetsKeyName = "AllowNewsAndInterests"
    $widgetsValue = 0
    
    Write-Log "Disabling Allow Widgets policy..."
    New-Item -Path $widgetsRegPath -Force | Out-Null
    Set-ItemProperty -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue -ErrorAction Stop
    Write-Log "Allow Widgets policy disabled."
}
catch {
    Write-Log "Error disabling Widgets policy: $_"
}

# 3. Enable "Remove pinned programs from the taskbar" Policy
try {
    $taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
    $taskbarKeyName = "NoPinningToTaskbar"
    $taskbarValue = 1
    
    Write-Log "Enabling 'Remove pinned programs from the taskbar' policy..."
    New-Item -Path $taskbarRegPath -Force | Out-Null
    Set-ItemProperty -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue -ErrorAction Stop
    Write-Log "'Remove pinned programs from the taskbar' policy enabled."
}
catch {
    Write-Log "Error setting taskbar policy: $_"
}

# 4. Restart Explorer Safely
function Restart-ExplorerSafely {
    param([switch]$Force)
    
    try {
        Write-Log "Attempting to restart Explorer..."
        
        # Get all Explorer processes
        $explorerProcesses = Get-Process explorer -ErrorAction SilentlyContinue
        
        if ($explorerProcesses) {
            Write-Log "Found $($explorerProcesses.Count) Explorer processes."
            
            if ($Force) {
                Write-Log "Force closing Explorer processes..."
                $explorerProcesses | Stop-Process -Force -ErrorAction Stop
            }
            else {
                Write-Log "Gracefully closing Explorer processes..."
                $explorerProcesses | Stop-Process -ErrorAction Stop
            }
            
            Start-Sleep -Seconds 2
        }
        
        # Start a new Explorer process
        Start-Process explorer.exe -ErrorAction Stop
        Write-Log "Explorer restarted successfully."
    }
    catch {
        Write-Log "Error restarting Explorer: $_"
        
        # Fallback method: Use Windows API
        try {
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class User32 {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
            }
"@
            $WM_CLOSE = 0x0010
            $hwnd = (Get-Process -Name "explorer").MainWindowHandle
            [User32]::SendMessage($hwnd, $WM_CLOSE, 0, 0)
            
            Start-Sleep -Seconds 2
            Start-Process explorer.exe
            Write-Log "Fallback Explorer restart method used successfully."
        }
        catch {
            Write-Log "Fallback method also failed: $_"
        }
    }
}

# 5. Execute Explorer Restart
Restart-ExplorerSafely -Force:$Force

Write-Log "Taskbar customization script completed."
