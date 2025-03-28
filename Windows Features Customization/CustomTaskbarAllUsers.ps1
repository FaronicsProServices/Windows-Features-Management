# PowerShell Script for Taskbar Customization (No Restart Required)

# 1. Add HideClock Registry Key for All Users
$regPathAllUsers = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$keyName = "HideClock"
$keyValue = 1

Write-Host "Creating registry key to hide the clock for all users..."
New-Item -Path $regPathAllUsers -Force | Out-Null
Set-ItemProperty -Path $regPathAllUsers -Name $keyName -Value $keyValue
Write-Host "Registry key HideClock added successfully for all users."

# 2. Disable Allow Widgets via Group Policy for All Users
$widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
$widgetsKeyName = "AllowNewsAndInterests"
$widgetsValue = 0

Write-Host "Disabling Allow Widgets policy for all users..."
New-Item -Path $widgetsRegPath -Force | Out-Null
Set-ItemProperty -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue
Write-Host "Allow Widgets policy disabled for all users."

# 3. Enable "Remove pinned programs from the taskbar" Policy for All Users
$taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
$taskbarKeyName = "NoPinningToTaskbar"
$taskbarValue = 1

Write-Host "Enabling 'Remove pinned programs from the taskbar' policy for all users..."
New-Item -Path $taskbarRegPath -Force | Out-Null
Set-ItemProperty -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue
Write-Host "'Remove pinned programs from the taskbar' policy enabled for all users."

# 4. Open System Icons Configuration Panel
Write-Host "Opening system icons configuration panel..."
Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"

# 5. Restart Explorer to Apply Changes
Write-Host "Restarting Explorer to apply changes..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer
Write-Host "Taskbar customization changes applied successfully."
