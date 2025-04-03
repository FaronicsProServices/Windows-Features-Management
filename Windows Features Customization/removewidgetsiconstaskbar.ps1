# PowerShell Script for Taskbar Customization (No Restart Required)

# 1. Add HideClock Registry Key
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$keyName = "HideClock"
$keyValue = 1

Write-Host "Creating registry key to hide the clock..."
New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue
Write-Host "Registry key HideClock added successfully."

# 2. Disable Allow Widgets via Group Policy
$widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
$widgetsKeyName = "AllowNewsAndInterests"
$widgetsValue = 0

Write-Host "Disabling Allow Widgets policy..."
New-Item -Path $widgetsRegPath -Force | Out-Null
Set-ItemProperty -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue
Write-Host "Allow Widgets policy disabled."

# 3. Enable "Remove pinned programs from the taskbar" Policy
$taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
$taskbarKeyName = "NoPinningToTaskbar"
$taskbarValue = 1

Write-Host "Enabling 'Remove pinned programs from the taskbar' policy..."
New-Item -Path $taskbarRegPath -Force | Out-Null
Set-ItemProperty -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue
Write-Host "'Remove pinned programs from the taskbar' policy enabled."

# 4. Remove all pinned apps from the taskbar
$taskbandRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"

Write-Host "Removing all pinned apps from the taskbar..."
Remove-Item -Path $taskbandRegPath -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Pinned apps removed successfully."

Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Force -Recurse -ErrorAction SilentlyContinue

# 5. Force Restart Explorer for the Active User
Write-Host "Restarting Explorer for the active user..."

# Find active user session ID
$UserSession = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object -First 1
if ($UserSession) {
    $SessionID = $UserSession.SessionId
    Write-Host "Active user session detected: $SessionID"

    # Stop Explorer if running
    Write-Host "Stopping explorer.exe process..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    # Restart Explorer in the correct user session
    $Command = "C:\Windows\System32\cmd.exe /c start explorer.exe"
    Start-Process -FilePath "C:\Windows\System32\cmd.exe" -ArgumentList "/c start explorer.exe" -NoNewWindow
    Write-Host "Explorer restarted successfully."
} else {
    Write-Host "No active user session found. Explorer restart skipped."
}

Write-Host "Taskbar customization changes applied successfully."
