Param(
    $Name = 'SimonW_ZoneSite',
    $FriendlyName = 'ZoneSite'
)
Remove-Module -Name [x]DSCResourceDesigner
Import-Module D:\git\xDSCResourceDesigner\xDSCResourceDesigner.psd1

Update-xDscResource -Path "$PSScriptRoot\..\DSCResources\$Name" -FriendlyName $FriendlyName -Property $(
    New-xDscResourceProperty -Name Uri -Type String -Attribute Key -Description "Address to configure, i.e. site.domain.com"
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Absent','Present' -Description "Sets Uri to be Present or Absent on machine"
    New-xDscResourceProperty -Name Type -Type String -Attribute Required -ValidateSet "*","file","ftp","http","https","knownfolder","ldap","news","nntp","oecmd","shell","snews" -Description "Sets protocol to be added, use * for any"
    New-xDscResourceProperty -Name Zone -Type String -Attribute Required -ValidateSet 'MyComputer','LocalIntranet','TrustedSite','Internet','Restricted' -Description "Specifies Zone"
    New-xDscResourceProperty -Name Platform -Type String -Attribute Write -ValidateSet 'x86','x64','All' -Description "Add for 32-bit, 64-bit or All applications"
)

if(-Not(Test-xDscResource "$PSScriptRoot\..\DSCResources\$Name")) {Throw 'Test resource failed'}
if(-Not(Test-xDscSchema "$PSScriptRoot\..\DSCResources\$Name\$Name.schema.mof")) {Throw 'Test resource failed'}

$error.Clear()
Import-Module "$PSScriptRoot\.." -Force
If ($error.count -ne 0) {
       Throw "Module was not imported correctly. Errors returned: $error"
}
