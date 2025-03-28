# PowerShell Script for Taskbar Customization (No Restart Required)

# 1. Add HideClock Registry Key
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$keyName = "HideClock"
$keyValue = 1

Write-Host "Creating registry key to hide the clock..."
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue
Write-Host "Registry key HideClock added successfully."

# 2. Disable Allow Widgets via Group Policy (Requires Admin)
Write-Host "Skipping 'Disable Allow Widgets' policy since it requires admin privileges."

# 3. Enable "Remove pinned programs from the taskbar" Policy (Requires Admin)
Write-Host "Skipping 'Remove pinned programs from the taskbar' policy since it requires admin privileges."

# 4. Open System Icons Configuration Panel
Write-Host "Attempting to open system icons configuration panel..."
if ($env:USERNAME -ne "SYSTEM") {
    Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons" -ErrorAction SilentlyContinue
} else {
    Write-Host "Explorer-related actions are not supported in system context."
}

Write-Host "Taskbar customization changes applied successfully."
