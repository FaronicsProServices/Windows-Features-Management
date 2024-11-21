# Set the registry key to deny apps access to the user's location by creating or updating the policy
$Name = "LetAppsAccessLocation"

$Value = 2 

$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"

If ((Test-Path $Path) -eq $false){  

New-Item -Path $Path -ItemType Directory  

}  

If (-!(Get-ItemProperty -Path $Path -Name $name -ErrorAction SilentlyContinue)){  

New-ItemProperty -Path $Path -Name $Name -Value $Value  

}  

else{  

Set-ItemProperty -Path $Path -Name $Name -Value $Value  

}
