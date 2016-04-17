$Module = "$PSScriptRoot\..\DSCResources\SimonW_ZoneSite\SimonW_ZoneSite.psm1"
Remove-Module -Name SimonW_ZoneSite -Force -ErrorAction SilentlyContinue
Import-Module -Name $Module -Force -ErrorAction Stop

Describe 'SimonW_ZoneSite' {
        
    InModuleScope -ModuleName SimonW_ZoneSite -ScriptBlock {
        
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
            It 'Returns only server part of FQDN UNC path' {
                Get-ZoneSiteName -Uri '\\server.domain.top\Share\folder\file.ext' | Should Be 'server.domain.top'
            }
            It 'Returns only server part of netbios UNC path' {
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
          
            $Type = 'ftp'
            $Zone = 'Restricted'
            $Uris = @{
                'exists' = 'ftp://existing.really.long.sub.domain.simonw.se'
                'doesn''t exist' = 'ftp://nonexisting.really.long.sub.domain.simonw.se'
            }
                
            Mock Get-ItemProperty -MockWith {}
            Mock Get-ItemProperty -ParameterFilter {
              $Path -like '*\existing.really.long.sub.domain'
            } -MockWith {
                [pscustomobject]@{
                    ftp = 4
                }
            }

            foreach($Platform in 'x86','x64','All') {
                foreach ($key in $Uris.Keys) {
                    foreach($Ensure in @('Present','Absent'))
                    {
                        It "Returns $($key -like 'exists' -xor $Ensure -eq 'Absent') if reg entry $key in $Platform when Ensure = $Ensure" {
                            SimonW_ZoneSite\Test-TargetResource -Uri $Uris[$key] -Ensure $Ensure -Type $Type -Zone $Zone -Platform $Platform | Should Be $($key -like 'exists' -xor $Ensure -eq 'Absent')
                        } 
                    }
                }
            }
        }
    }
}

