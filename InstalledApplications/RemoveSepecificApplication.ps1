#Specify the application name to remove a specific application from Windows
$app = "Application Name"
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $app } | ForEach-Object { $_.Uninstall() }
Write-Host "$app has been uninstalled."
