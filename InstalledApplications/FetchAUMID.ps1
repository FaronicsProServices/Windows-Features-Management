# This script scans installed applications on the system, extracts their AUMID (Application User Model ID) from the AppxManifest.xml files, and outputs a list of app names along with their AUMID.
# The AUMID is useful for identifying and interacting with apps through system-level operations.
$allApps = Get-ChildItem "C:\Program Files\WindowsApps\*", "C:\Windows\SystemApps\*", "C:\Windows\*"
$aumidList = @{}
foreach ($appFolder in $allApps)
{
    $appxManifest = $appFolder.FullName + "\AppxManifest.xml"
    if(Test-Path $appxManifest)
    {
        $xml = [xml](Get-Content $appxManifest)
        $aumidNodes = $xml.GetElementsByTagName("Application")
        foreach ($aumidNode in $aumidNodes)
        {
            if($aumidNode.Id)
            {
                $appName = ($appFolder.Name -split "_.*__")
                if($appName[1])
                {
                    $newName = $appName[0] + '_' + $appName[1]
                }
                else
                {
                    $newName = $appName[0]
                }
                $aumid = $newName + "!" + $aumidNode.Id
                $aumidList[$newname] = $aumid
            }
        }
    }
}
$aumidList | fl -Property Name, Value
