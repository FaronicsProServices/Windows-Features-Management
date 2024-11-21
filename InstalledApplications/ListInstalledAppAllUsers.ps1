# Retrieve and display the names and full package names of all installed app packages for all users
Get-AppxPackage -Allusers | Select Name, PackageFullName
