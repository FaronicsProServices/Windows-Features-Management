# PowerShell Script for Taskbar Customization (System Account Compatible)

# Detect the currently logged-in user
$loggedInUser = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName)

if ($loggedInUser -and $loggedInUser -ne "SYSTEM") {
    # Load the active user's registry hive
    $userSid = (New-Object System.Security.Principal.NTAccount($loggedInUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $regHivePath = "HKU:\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    # 1. Add HideClock Registry Key (User-specific key)
    $keyName = "HideClock"
    $keyValue = 1
    Write-Host "Creating registry key to hide the clock for user $loggedInUser..."
    if (-not (Test-Path $regHivePath)) {
        New-Item -Path $regHivePath -Force | Out-Null
    }
    Set-ItemProperty -Path $regHivePath -Name $keyName -Value $keyValue
    Write-Host "Registry key HideClock added successfully for $loggedInUser."

    # 2. Inform that admin-specific tasks are skipped
    Write-Host "Disabling Allow Widgets policy requires admin privileges. This step will be skipped."
    Write-Host "'Remove pinned programs from the taskbar' policy requires admin privileges. This step will be skipped."

    # 3. Open System Icons Configuration Panel in the logged-in user's context
    $command = 'explorer.exe "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"'
    Write-Host "Opening system icons configuration panel for user $loggedInUser..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $command -NoNewWindow -LoadUserProfile

    Write-Host "Taskbar customization process completed for $loggedInUser. No restart required."
} else {
    Write-Host "No active user detected or script running under SYSTEM account. Task cannot proceed."
}
