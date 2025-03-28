# PowerShell Script for Taskbar Customization with Enhanced Diagnostics
param(
    [switch]$Verbose = $false
)

# Comprehensive Logging Function
function Write-DetailedLog {
    param(
        [string]$Message,
        [switch]$ErrorLog = $false
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    Write-Host $logMessage
    
    if ($ErrorLog) {
        # Optional: Add error logging to a file
        $logPath = "$env:TEMP\TaskbarCustomization_ErrorLog.txt"
        Add-Content -Path $logPath -Value $logMessage
    }
}

# Diagnostic Function to Check Explorer Process
function Test-ExplorerProcess {
    try {
        $explorerProcesses = Get-Process explorer -ErrorAction Stop
        Write-DetailedLog "Explorer Processes Count: $($explorerProcesses.Count)"
        
        foreach ($process in $explorerProcesses) {
            Write-DetailedLog "Process ID: $($process.Id), MainWindowHandle: $($process.MainWindowHandle)"
        }
        
        return $explorerProcesses
    }
    catch {
        Write-DetailedLog "Error detecting Explorer processes: $_" -ErrorLog
        return $null
    }
}

# Advanced Explorer Restart Function
function Restart-ExplorerAdvanced {
    param([switch]$Force)
    
    try {
        Write-DetailedLog "Initiating Advanced Explorer Restart..."
        
        # Diagnostic Checks
        $processes = Test-ExplorerProcess
        
        if ($processes) {
            Write-DetailedLog "Attempting to close Explorer processes..."
            
            # Multiple Closure Strategies
            try {
                # Strategy 1: Graceful Close
                $processes | ForEach-Object { 
                    try {
                        $_.CloseMainWindow() | Out-Null
                        Write-DetailedLog "Sent close signal to Process ID $($_.Id)"
                    }
                    catch {
                        Write-DetailedLog "Could not gracefully close Process ID $($_.Id): $_" -ErrorLog
                    }
                }
            }
            catch {
                Write-DetailedLog "Graceful close failed. Attempting force close." -ErrorLog
                
                # Strategy 2: Force Close
                $processes | Stop-Process -Force
            }
            
            Start-Sleep -Seconds 2
        }
        
        # Windows API Fallback with Enhanced Logging
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class User32 {
            [DllImport("user32.dll")]
            public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
            
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
        }
"@
        
        $WM_CLOSE = 0x0010
        $explorerWindow = [User32]::FindWindow("Shell_TrayWnd", $null)
        
        if ($explorerWindow -ne [IntPtr]::Zero) {
            Write-DetailedLog "Sending close message to Explorer window handle."
            $result = [User32]::PostMessage($explorerWindow, $WM_CLOSE, 0, 0)
            Write-DetailedLog "Window close message result: $result"
        }
        else {
            Write-DetailedLog "Could not find Explorer window handle." -ErrorLog
        }
        
        Start-Sleep -Seconds 2
        
        # Final Restart Attempt
        Start-Process explorer.exe
        Write-DetailedLog "Explorer restart completed."
    }
    catch {
        Write-DetailedLog "Critical error in Explorer restart: $_" -ErrorLog
    }
}

# Main Script Execution
try {
    # Registry Modifications (Similar to previous script)
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "HideClock" -Value 1

    $widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
    New-Item -Path $widgetsRegPath -Force | Out-Null
    Set-ItemProperty -Path $widgetsRegPath -Name "AllowNewsAndInterests" -Value 0

    $taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
    New-Item -Path $taskbarRegPath -Force | Out-Null
    Set-ItemProperty -Path $taskbarRegPath -Name "NoPinningToTaskbar" -Value 1

    # Advanced Explorer Restart
    Restart-ExplorerAdvanced -Force:$Verbose
}
catch {
    Write-DetailedLog "Unhandled script error: $_" -ErrorLog
}

Write-DetailedLog "Taskbar customization script completed."
