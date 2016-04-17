$ZoneList = @{
    MyComputer    = 0
    LocalIntranet = 1
    TrustedSite   = 2
    Internet      = 3
    Restricted    = 4
}
$RegistryRootPath = @{
    x86 = 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
    x64 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
}
$PSDefaultParameterValues.Clear()
$PSDefaultParameterValues['Write-PRVerbose:VerbLength'] = 8
$PSDefaultParameterValues['Write-PRVerbose:NounLength'] = 0

function Write-PRVerbose {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Verb,
        [Parameter(Mandatory)]
        [string]
        $Noun,
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $Message,
        [Parameter(Mandatory)]
        [Int]
        $VerbLength,
        [Parameter(Mandatory)]
        [Int]
        $NounLength
    )
    process
    {
        $FormatString = "{0,-$VerbLength} [{1,-$NounLength}] [{2}]"
        $OutputString = $FormatString -f $Verb, $Noun, $Message
        Write-Verbose -Message $OutputString
    }

}

function Get-ZoneSiteName {
    [cmdletbinding()]
    param([String]$Uri)
    if($Uri -match '(?<=^\\\\|^\w{3,5}://)[^\\/]+(?=\\.*$|/.*$|$)')
    {
        $UriToTrust = $Matches[0]
    }
    elseif ($Uri -match '^[\w\.]+$')
    {
        $UriToTrust = $Uri
    }
    else
    {
        throw 'Failed to parse Uri'
    }
    Write-PRVerbose -Verb Get -Noun 'ZoneSite: Name' -Message $UriToTrust
    return $UriToTrust
}

function Get-PartialRegPath {
    [cmdletbinding()]
    param([String]$Uri)
    $UriArray = $Uri -split '\.'
    if($UriArray.Count -gt 2)
    {
        $UriToTrust = $(
            $UriArray[-2..-1] -join '.'
            $UriArray[-($UriArray.Count)..-3] -join '.'
        )
    }
    else
    {
        $UriToTrust = $UriArray -join '.'
    }
    $UriToTrust = $UriToTrust -join '\'
    Write-PRVerbose -Verb Get -Noun 'ZoneSite: PartialRegPath' -Message $UriToTrust
    return $UriToTrust
}

function Get-ItemPropertyPath {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Uri,
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateSet('x86','x64')]
        [String]$Platform
    )
    process
    {
        $Uri = Get-ZoneSiteName -Uri $Uri
        $ChildRegPath = Get-PartialRegPath -Uri $Uri
        $returnString = (Join-Path -Path $RegistryRootPath[$Platform] -ChildPath $ChildRegPath)
        Write-PRVerbose -Verb Get -Noun 'ZoneSite: ItemPropertyPath' -Message $returnString
        return $returnString
    }
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Uri,

        [parameter(Mandatory = $true)]
        [ValidateSet("*","file","ftp","http","https","knownfolder","ldap","news","nntp","oecmd","shell","snews")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [ValidateSet("MyComputer","LocalIntranet","TrustedSite","Internet","Restricted")]
        [System.String]
        $Zone
    )
    $returnValue = @{
        Uri  = Get-ZoneSiteName -Uri $Uri
        Type = $Type
        Zone = $Zone
    }
    $Path = @{
        x86 = Get-ItemPropertyPath -Uri $Uri -Platform x86
        x64 = Get-ItemPropertyPath -Uri $Uri -Platform x64
    }
    $IsPresent = @{
        x86 = $false
        x64 = $false
    }
    foreach($Entry in $Path.Keys)
    {
        if($RegValue = Get-ItemProperty -Path $Path[$Entry] -Name $Type -ErrorAction SilentlyContinue)
        {
            if($RegValue.$Type -eq $ZoneList[$Zone])
            {
                $IsPresent[$Entry] = $true
            }
            else
            {
                $IsPresent[$Entry] = $true
            }
        }
    }
    
    if($IsPresent.Values -notcontains $false)
    {
        $returnValue['Ensure']   = 'Present'
        $returnValue['Platform'] = 'All'
    }
    elseif($IsPresent['x86'])
    {
        $returnValue['Ensure']   = 'Present'
        $returnValue['Platform'] = 'x86'
    }
    elseif($IsPresent['x64'])
    {
        $returnValue['Ensure']   = 'Present'
        $returnValue['Platform'] = 'x64'
    }
    else
    {
        $returnValue['Ensure']   = 'Absent'
        $returnValue['Platform'] = 'All'
    }
   
    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Uri,

        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("*","file","ftp","http","https","knownfolder","ldap","news","nntp","oecmd","shell","snews")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [ValidateSet("MyComputer","LocalIntranet","TrustedSite","Internet","Restricted")]
        [System.String]
        $Zone,

        [ValidateSet("x86","x64","All")]
        [System.String]
        $Platform
    )

    $PathList = Switch -Regex ($Platform)
    {
        'x86|All'
        {
            Get-ItemPropertyPath -Uri $Uri -Platform x86
        }
        'x64|All'
        {
            Get-ItemPropertyPath -Uri $Uri -Platform x64
        }
    }
    Foreach($Path in $PathList)
    {
        if($Ensure -ieq 'Present')
        {
            if(-Not(Test-Path -Path $Path)){[System.Void](New-Item -Path $Path -ItemType Key -Force)}
            if(Get-ItemProperty -Path $Path -Name $Type -ErrorAction SilentlyContinue)
            {
                [System.Void](Set-ItemProperty -Path $Path -Name $Type -Value $ZoneList[$Zone])
            }
            else
            {
                [System.Void](New-ItemProperty -Path $Path -Name $Type -PropertyType DWORD -Value $ZoneList[$Zone])
            }
        }
        else
        {
            if(Get-ItemProperty -Path $Path -Name $Type -ErrorAction SilentlyContinue)
            {
                Remove-ItemProperty -Path $Path -Name $Type -Force
            }
        }
    }

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Uri,

        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("*","file","ftp","http","https","knownfolder","ldap","news","nntp","oecmd","shell","snews")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [ValidateSet("MyComputer","LocalIntranet","TrustedSite","Internet","Restricted")]
        [System.String]
        $Zone,

        [ValidateSet("x86","x64","All")]
        [System.String]
        $Platform
    )
    
    $Get = Get-TargetResource -Uri $Uri -Type $Type -Zone $Zone
    switch ($Ensure) {
        'Present'{$bool = $true}
        'Absent'{$bool = $false}
    }
    Write-PRVerbose -Verb Get -Noun Result:Ensure -Message $Get['Ensure']
    Write-PRVerbose -Verb Get -Noun Result:Platform -Message $Get['Platform']

    if($Get['Ensure'] -eq 'Present')
    {
        if($Get['Platform'] -in @($Platform,'All'))
        {
            return $bool
        }
        else
        {
            if($Platform -eq 'All')
            {
                return $false
            }
        }
    }
    return (-not($bool))

}

Export-ModuleMember -Function *-TargetResource
