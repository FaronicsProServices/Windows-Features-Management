# PowerShell Script for Taskbar Customization (Full Steps Included)

# Define function to run commands in the context of the logged-in user
function Invoke-AsUser {
    param (
        [string]$Command
    )
    $userSessionId = (Get-WmiObject -Query "SELECT * FROM Win32_LogonSession WHERE LogonType = 2").LogonId | Select-Object -First 1
    if ($userSessionId) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Command" -NoNewWindow -LoadUserProfile
        Write-Host "Command executed: $Command"
    } else {
        Write-Host "No active user session found. Cannot execute command."
    }
}

# 1. Add HideClock Registry Key
$hideClockKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$keyName = "HideClock"
$keyValue = 1

Write-Host "Creating registry key to hide the clock..."
if (-not (Test-Path $hideClockKeyPath)) {
    New-Item -Path $hideClockKeyPath -Force | Out-Null
}
Set-ItemProperty -Path $hideClockKeyPath -Name $keyName -Value $keyValue
Write-Host "Registry key HideClock added successfully."

# 2. Disable Allow Widgets via Registry (HKLM)
$widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
$widgetsKeyName = "AllowNewsAndInterests"
$widgetsValue = 0

Write-Host "Disabling Allow Widgets policy..."
if (-not (Test-Path $widgetsRegPath)) {
    New-Item -Path $widgetsRegPath -Force | Out-Null
}
Set-ItemProperty -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue
Write-Host "Allow Widgets policy disabled."

# 3. Enable "Remove pinned programs from the taskbar" Policy
$taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
$taskbarKeyName = "NoPinningToTaskbar"
$taskbarValue = 1

Write-Host "Enabling 'Remove pinned programs from the taskbar' policy..."
if (-not (Test-Path $taskbarRegPath)) {
    New-Item -Path $taskbarRegPath -Force | Out-Null
}
Set-ItemProperty -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue
Write-Host "'Remove pinned programs from the taskbar' policy enabled."

# 4. Open System Icons Configuration Panel
$systemIconsCommand = 'explorer.exe "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"'
Write-Host "Opening system icons configuration panel..."
Invoke-AsUser -Command $systemIconsCommand

# 5. Restart Explorer to Apply Changes
Write-Host "Restarting Explorer to apply changes..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe

Write-Host "Taskbar customization changes applied successfully."
