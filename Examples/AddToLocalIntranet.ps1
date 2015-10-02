configuration Sample_ZoneSite_AddToLocalIntranet
{
    param
    (
        [string]
        [ValidateSet("Absent","Present")]
        $Ensure = 'Present',

        [string]
        $Uri = 'http://site.corp.contoso.com',

        [string]
        [ValidateSet("*","file","ftp","http","https","knownfolder","ldap","news","nntp","oecmd","shell","snews")]
        $Type = 'http',

        [string]
        [ValidateSet("MyComputer","LocalIntranet","TrustedSite","Internet","Restricted")]
        $Zone = 'LocalIntranet',
        
        [string]
        [ValidateSet("x86","x64","All")]
        $Platform = 'All'
    )
    Import-DscResource -Name ZoneSite -ModuleName InternetSettings

    Node $AllNodes.NodeName
    {
        ZoneSite "${Uri}_${Zone}"
        {
            Ensure = 'Present'
            Uri = $Uri
            Type = $Type
            Zone = $Zone
            Platform = $Platform
        }
    
    }

}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $Env:COMPUTERNAME
        }
    )
}

Sample_ZoneSite_AddToLocalIntranet -ConfigurationData $ConfigData

Start-DscConfiguration -Path .\Sample_ZoneSite_AddToLocalIntranet -Wait -Verbose -Force