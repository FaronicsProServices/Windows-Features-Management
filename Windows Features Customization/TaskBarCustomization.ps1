# PowerShell Script for Taskbar Customization (Full Steps Included)

# Detect the currently logged-in user
$loggedInUser = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName)

if ($loggedInUser -and $loggedInUser -ne "SYSTEM") {
    # Load the active user's registry hive
    $userSid = (New-Object System.Security.Principal.NTAccount($loggedInUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

    # 1. Add HideClock Registry Key (User-specific key)
    $regHivePath = "HKU:\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $keyName = "HideClock"
    $keyValue = 1

    Write-Host "Creating registry key to hide the clock for user $loggedInUser..."
    if (-not (Test-Path $regHivePath)) {
        New-Item -Path $regHivePath -Force | Out-Null
    }
    Set-ItemProperty -Path $regHivePath -Name $keyName -Value $keyValue
    Write-Host "Registry key HideClock added successfully for $loggedInUser."

    # 2. Disable Allow Widgets via Group Policy
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
    $command = 'explorer.exe "shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}\SystemIcons"'
    Write-Host "Opening system icons configuration panel for user $loggedInUser..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $command -NoNewWindow -LoadUserProfile

    Write-Host "Taskbar customization process completed for $loggedInUser. No restart required."
} else {
    Write-Host "No active user detected. Trying to detect user session and execute commands under their context..."

    # Detect active session and execute in user's context
    $session = (Get-WmiObject -Namespace root\cimv2 -Class Win32_LogonSession | Where-Object { $_.LogonType -eq 2 }).LogonId
    if ($session) {
        Write-Host "Active session found. Attempting to run tasks in user's context..."
        schtasks /create /tn "RunTaskbarCustomization" /tr "powershell.exe -ExecutionPolicy Bypass -File $($MyInvocation.MyCommand.Definition)" /sc once /st 00:00 /ru "$loggedInUser" /f
        schtasks /run /tn "RunTaskbarCustomization"
        schtasks /delete /tn "RunTaskbarCustomization" /f
    } else {
        Write-Host "Unable to detect active user session. Task cannot proceed."
    }
}
