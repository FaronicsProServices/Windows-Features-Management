# PowerShell Script for System-Wide Taskbar Customization

Write-Host "Starting Taskbar customization for all users..."

# 1. Hide Clock (Applies to all users)
$regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$keyName = "HideClock"
$keyValue = 1

Write-Host "Hiding clock for all users..."
New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue
Write-Host "Clock hidden."

# 2. Disable Widgets (Applies to all users)
$widgetsRegPath = "HKLM:\Software\Policies\Microsoft\Dsh"
$widgetsKeyName = "AllowNewsAndInterests"
$widgetsValue = 0

Write-Host "Disabling Widgets for all users..."
New-Item -Path $widgetsRegPath -Force | Out-Null
Set-ItemProperty -Path $widgetsRegPath -Name $widgetsKeyName -Value $widgetsValue
Write-Host "Widgets disabled."

# 3. Prevent Pinning to Taskbar (Applies to all users)
$taskbarRegPath = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
$taskbarKeyName = "NoPinningToTaskbar"
$taskbarValue = 1

Write-Host "Disabling taskbar pinning for all users..."
New-Item -Path $taskbarRegPath -Force | Out-Null
Set-ItemProperty -Path $taskbarRegPath -Name $taskbarKeyName -Value $taskbarValue
Write-Host "Taskbar pinning disabled."

# 4. Remove Pinned Apps (Ensures settings apply system-wide)
$taskbandRegPath = "HKU\*\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"

Write-Host "Removing pinned apps from taskbar for all users..."
Get-ChildItem "HKU:\" | ForEach-Object {
    $sid = $_.PSChildName
    Remove-Item -Path "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "Pinned apps removed."

# 5. Apply Registry Changes for System-Wide Deployment
Write-Host "Forcing group policy update..."
gpupdate /force | Out-Null

# 6. Restart Explorer to Apply Changes
Write-Host "Restarting Explorer..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer
Write-Host "Taskbar customization applied successfully for all users."
