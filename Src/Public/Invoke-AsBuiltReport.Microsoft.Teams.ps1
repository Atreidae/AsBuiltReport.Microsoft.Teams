function Invoke-AsBuiltReport.Microsoft.Teams {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function')] #The product name is "Teams", this is incorrectly being flagged as plural
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft Teams in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft Teams in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
        Author:         James Arber
        Twitter:        UCMadScientist
        Github:         Atreidae
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
                        Tim Carman (@tpcarman) - AsBuiltReport core project
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Teams
    #>

    param (
        [String[]] $Target,
        [PSCredential] $Credential,
        [Switch] $MFA
    )

    Write-PScriboMessage -Plugin 'Module' -Message 'Please refer to the AsBuiltReport.Microsoft.Teams GitHub website for more detailed information about this project.'
    Write-PScriboMessage -Plugin 'Module' -Message 'Do not forget to update your report configuration file after each new version release: https://www.asbuiltreport.com/user-guide/new-asbuiltreportconfig/'
    Write-PScriboMessage -Plugin 'Module' -Message 'Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Teams'
    Write-PScriboMessage -Plugin 'Module' -Message 'Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Teams/issues'
    Write-PScriboMessage -Plugin 'Module' -Message 'Support or consultancy: https://www.ucmadscientist.com/contact/'


    # Check the current AsBuiltReport.Microsoft.Teams module
    $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Microsoft.Teams -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

    if ($InstalledVersion) {
        Write-PScriboMessage -Plugin 'Module' -Message "AsBuiltReport.Microsoft.Teams $($InstalledVersion.ToString()) is currently installed."
        $LatestVersion = Find-Module -Name AsBuiltReport.Microsoft.Teams -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
        if ($LatestVersion -gt $InstalledVersion) {
            Write-PScriboMessage -Plugin 'Module' -Message "AsBuiltReport.Microsoft.Teams $($LatestVersion.ToString()) is available."
            Write-PScriboMessage -Plugin 'Module' -Message "Run 'Update-Module -Name AsBuiltReport.Microsoft.Teams -Force' to install the latest version."
        }
    }

    #Check for requied modules, throws error and exits if not found
    @(
        @{ Name = 'MicrosoftTeams'; Version = '5.0.0' }
        @{ Name = 'PnP.PowerShell'; Version = '2.0.0' } #Todo Why? we need graph dont we?
    ) | Test-RequiredModule


    # Import Report Configuration
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options
    $Healthcheck = $ReportConfig.Healthcheck

    #External optional files path for LIS and Direct Routing Numbers
    $SiteContactsPath = $ReportConfig.SiteContactsPathToFile
    $DirectRoutingNumbersPath = $ReportConfig.DirectRoutingNumberRangesPathToFile

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    # Whilst AsBuiltReport.Core supports multiple targets, due to the interactive nature of Microsoft logins, this module only supports a single target. If you wish to support multiple targets, you will need to use token authentication and update the code below to support this.
    # I may look to add support for multiple targets in the future using tokens, but for now, this is not a priority. -UcMadScientist

    #region foreach loop
    foreach ($TenantId in $Target) {
        if (-not $useOfflineData) {
            #If we are not using offline data, connect to the tenant
            try {
                Write-PScriboMessage "Checking for connection to $TenantId'."
                if ((Get-CsTenant).tenantid -ne $TenantId) {
                    Write-PScriboMessage "Wrong Tenant'." -IsWarning
                    throw 'Connected to Wrong Tenant, Reconnecting'
                } else {
                    Write-PScriboMessage "Already connected to $TenantId'."
                    $CsAccount = $true
                }
            } catch {
                try {
                    Write-PScriboMessage "Connecting to Teams Tenant ID '$TenantId'."
                    if ($MFA) {
                        $CsAccount = Connect-MicrosoftTeams -TenantId $TenantId -ErrorAction Stop
                    } else {
                        $CsAccount = Connect-MicrosoftTeams -Credential $Credential -TenantId $TenantId -ErrorAction Stop
                    }
                } catch {
                    Write-Error $_
                }


            }
        } else {
            #No need to connect, we are using offline data
            Write-PScriboMessage -Plugin 'Module' -Message "Using offline data for tenant '$TenantId'."
            $CsAccount = $true
        }
        #Only proceed if we have a valid connection or are using offline data
        if ($CsAccount) {
            #Collect Teams Tenant information
            Write-PScriboMessage "Connectivity to tenant '$TenantId' successful."
            Else {
                throw "Failed to connect to tenant '$TenantId'. Aborting report."
            }

            #Start building the report
            Section -Style Heading1 "$($CsTenant.DisplayName) Basic Tenant Information" {
                Get-AbrCsTenant -UseOfflineData:$UseOfflineData -SaveOfflineData:$SaveOfflineData -TenantCachePath $TenantCachePath
            }
            PageBreak
            Section -Style Heading1 'PSTN Calling Configuration' {
                if ($Options.ShowSectionBlurb) {
                    if (!$options.ShowSectionFullDescription) {
                        #We dont want the blurb and the full description if the user selects both
                        Paragraph 'This section covers the configuration of PSTN Calling within your Teams Tenant.'
                        BlankLine
                    }
                }
                if ($Options.ShowSectionFullDescription) {
                    Paragraph { Text 'Calls in Microsoft Teams can be broken down into two types,' ; Text 'Teams Calls' -Bold ; Text 'and'; Text 'PSTN Calls'-Bold }
                    Paragraph { Text 'Teams calls'-Bold ; Text 'are calls between two Teams users. These calls are routed via the Microsoft Teams infrastructure and do not require any additional configuration.'
                        Text 'PSTN Calls'-Bold; Text 'are calls to and from the'; Text 'Public Switched Telephone Network (PSTN)' -Bold ; Text 'similar to you mobile phone or a payphone'
                        Text 'As there are so many ways of connecting to the PSTN, these calls require additional configuration to route calls to and from your Teams environment depending on country and carrier.'
                        Text 'This section covers PSTN Calling settings that affect PSTN calls within your Teams Tenant.' }
                    BlankLine
                }

                Get-AbrCsPSTNNumber
                Get-AbrCsPSTNCallRouting
            }
            PageBreak
            Section -Style Heading1 "$($CsTenant.DisplayName) Teams and Channels" {
                #todo stuff
            }
            PageBreak
            Section -Style Heading1 "$($CsTenant.DisplayName) Devices" {
                #todo stuff
            }
            PageBreak
            Section -Style Heading1 "$($CsTenant.DisplayName) User Checks" {
                #todo stuff
            }
            PageBreak
            Section -Style Heading1 "$($CsTenant.DisplayName) Health Checks" {
                Get-AbrCsHealthCheck
            }
            PageBreak

            Section -Style Heading1 "Locations in the Tenant" {
                Get-AbrCsOnlineLisLocation
                Paragraph { Text "<a href='https://www.bing.com'>Click here to visit Bing</a>" }

            }

        }
    }
    #endregion foreach loop
}
