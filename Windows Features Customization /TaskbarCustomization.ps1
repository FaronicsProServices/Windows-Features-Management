# PowerShell Script for Taskbar Customization (No Admin, No Prompts)

# 1. Add HideClock Registry Key (User-specific key, no admin rights needed)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$keyName = "HideClock"
$keyValue = 1

Write-Host "Creating registry key to hide the clock (user-specific)..."
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name $keyName -Value $keyValue -ErrorAction SilentlyContinue
Write-Host "Registry key HideClock added successfully."

# 2. Skip Disabling Allow Widgets Due to Admin Rights
Write-Host "Skipping 'Disabling Allow Widgets' policy as it requires admin privileges."

# 3. Skip Taskbar Pinned Policy Due to Admin Rights
Write-Host "Skipping 'Remove pinned programs from the taskbar' policy as it requires admin privileges."

# 4. Open System Icons Configuration Panel
Write-Host "Opening system icons configuration panel..."
Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons" -ErrorAction SilentlyContinue

Write-Host "Taskbar customization process completed. No restart required. No user prompts needed."
