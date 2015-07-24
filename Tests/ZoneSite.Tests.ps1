$Module = "$PSScriptRoot\..\DSCResources\SimonW_ZoneSite\SimonW_ZoneSite.psm1"
Remove-Module -Name SimonW_ZoneSite -Force -ErrorAction SilentlyContinue
Import-Module -Name $Module -Force -ErrorAction Stop

InModuleScope SimonW_ZoneSite {
    
    Describe 'SimonW_ZoneSite' {
        Context Get-ZoneSiteName {
            It 'Returns only address-part of URI for http Uri' {
                Get-ZoneSiteName -Uri 'http://site.domain.top/something/page.html' | Should Be 'site.domain.top'
            }
            It 'Returns only address-part of URI for ftp Uri' {
                Get-ZoneSiteName -Uri 'ftp://site.domain.top/something/file.ext' | Should Be 'site.domain.top'
            }
            It 'Returns all of an FQDN' {
                Get-ZoneSiteName -Uri 'server.domain.top' | Should Be 'server.domain.top'
            }
            It 'Returns only server part of UNC path' {
                Get-ZoneSiteName -Uri '\\server.domain.top\Share\folder\file.ext' | Should Be 'server.domain.top'
                Get-ZoneSiteName -Uri '\\server\Share\folder\file.ext' | Should Be 'server'
            }
            It 'Throws on invalid Uri' {
                {Get-ZoneSiteName -Uri 'ftp:invalid.uri'} | Should throw
            }
        }

        Context Get-PartialRegPath {
            It 'Splits a long domain name in two and joins them to a partial path' {
                Get-PartialRegPath -Uri 'this.is.a.long.domain.name.top' | Should be 'name.top\this.is.a.long.domain'
            }
            It 'Returns a short domain name as a partial path' {
                Get-PartialRegPath -Uri 'name.top' | Should be 'name.top'
            }
        }

        Context Get-ItemPropertyPath {
            It 'Converts a Uri to a full registry path' {
                Get-ItemPropertyPath -Uri 'ftp://site.domain.top/something/file.ext' -Platform 'x86' | Should be 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\domain.top\site'
            }
        }
        
        Context Test-TargetResource {
            $Uri  = '\\server.doman.top\share\folder'
            $Type = '*'
            $Zone = 'LocalIntranet'
            
            It 'Returns true if reg entry exists' {
                mock Get-ItemProperty { [pscustomobject]@{$Type = $ZoneList[$Zone]} }
                Test-TargetResource -Uri $Uri -Ensure Present -Type $Type -Zone $Zone -Platform x86 | Should Be $true
            }

            It 'Returns false if reg entry doesn''t exist' {
                mock Get-ItemProperty {}
                Test-TargetResource -Uri $Uri -Ensure Present -Type $Type -Zone $Zone -Platform x86 | Should Be $false
            }
        }
    }
}
