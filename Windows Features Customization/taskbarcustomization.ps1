# PowerShell Script for Taskbar Customization (No Restart Required)

# 1. Hide the clock
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

# 4. Open System Icons Configuration Panel
Write-Host "Opening system icons configuration panel..."
Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"

# 5. Restart Explorer Using User Session Method
Write-Host "Restarting Explorer in user session..."
$ExplorerRestartScript = {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
}

# Get Active User Session and Run in Their Context
$UserSession = (Get-WmiObject Win32_Process -Filter "Name='explorer.exe'").SessionId
if ($UserSession) {
    Invoke-Command -ScriptBlock $ExplorerRestartScript -Credential $null -ArgumentList $UserSession
} else {
    Write-Host "No active user session detected. Skipping Explorer restart."
}

Write-Host "Taskbar customization changes applied successfully."
