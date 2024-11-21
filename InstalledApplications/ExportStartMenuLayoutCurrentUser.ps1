# Exports the Start Menu layout of the current logged in user
try{ 
    # Determining the current logged-in user 
    $currentLoggedInuser="" 
    $signedInUsers = get-wmiobject win32_process | where-object {$_.processname -eq "explorer.exe"} | Foreach { $_.getowner().user } 
    foreach ($user in $signedInUsers) 
    { 
        $isactive = C:\windows\system32\qwinsta.exe $user 
        if ($isactive -like "*  Active*") 
        { 
            $currentLoggedInuser = $user 
            break 
        } 
    } 
    if ($currentLoggedInuser -eq "") 
    { 
        Write-Host "Cannot find any logged-in user, so skipping script execution`nTo execute this script, at least one user must be logged in to the device." 
    } 
    else 
    { 
        Write-Host "The start layout for the user $currentLoggedInuser has been exported successfully." 
        $script = "Start-Process ""$file"" -PassThru -Wait" 
        # Unregistering ShowNotificationTask task from task scheduler (if we have already registered using script execution) 
        try 
        { 
            $a = Unregister-ScheduledTask -TaskName "ShowNotificationTask" -Confirm:$false -ErrorAction:Ignore 
        } 
        catch 
        { 
            Write-Host "Error while unregistering scheduled task-->", $_.Exception.Message 
        } 
        # Scheduling task 
        $actions = (New-ScheduledTaskAction -Execute 'powershell.exe' -WorkingDirectory C:\Faronics\Logs -Argument "-ExecutionPolicy unrestricted -WindowStyle Hidden -NoLogo -command `"&{Export-StartLayout -Path C:\Path\to\the\file\Filename.xml }`"") 
        $principal = New-ScheduledTaskPrincipal -UserId $currentLoggedInuser -RunLevel Highest 
        $settings = New-ScheduledTaskSettingsSet -WakeToRun -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -Hidden -AllowStartIfOnBatteries -Priority 0 -StartWhenAvailable 
        $task = New-ScheduledTask -Action $actions -Principal $principal -Settings $settings 
        $reg = Register-ScheduledTask 'ShowNotificationTask' -InputObject $task 
        Start-ScheduledTask -TaskName "ShowNotificationTask" -Verbose 
    } 
} 
catch 
{ 
    Write-Host "Exception inside running script-->", $_.Exception.Message 
}
