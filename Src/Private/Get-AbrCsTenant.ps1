function Get-AbrCsTenant {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Teams Tenant information
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
        Author:         James "UcMadScientist" Arber
        Twitter:        @UCMadScientist
        Github:         Atreidae
    .EXAMPLE

    .LINK

    .VERSION HISTORY
    0.2.0: Refactored to use Import-JsonData function for offline data loading
            Added SaveOfflineData switch to save retrieved data for future use
            Improved error handling and messages
            Added more detailed comments and documentation

    0.1.0: Initial build for AsBuiltReport.Microsoft.Teams

    #>
    [CmdletBinding()]
    param (
        [Switch] $UseOfflineData, #Use offline data from the sample data path
        [Switch] $SaveOfflineData, #Save the data retrieved to the sample data path for future use
        [String] $TenantCachePath = $Global:TenantCachePath  #The name of the folder in /Dev/Samples to use
    )

    begin {
        Write-PscriboMessage "Collecting Teams Tenant information."
    }

    process {
        #swtch mode based on UseOfflineData and SaveOfflineData

        #Offline data mode
        if ($UseOfflineData) {
            $CsTenant = Import-JsonData -FilePath "$TenantCachePath/Get-CsTenant.json"
            if (-not $CsTenant) {
                Throw "Failed to load offline data for Get-CsTenant from path '$TenantCachePath/Get-CsTenant.json'. Please check the file and try again."
            } else {
                Write-PScriboMessage -Plugin 'Module' -Message "Using offline data for Get-CsTenant from path '$TenantCachePath/Get-CsTenant.json'."
            }
        } else {
            #Online data mode
            $CsTenant = Get-CsTenant -ErrorAction SilentlyContinue
            if (-not $CsTenant) {
                Throw "Failed to retrieve Teams Tenant information using Get-CsTenant. Please check connectivity and permissions and try again."
            } else {
                Write-PScriboMessage -Plugin 'Module' -Message "Successfully retrieved Teams Tenant information using Get-CsTenant."

                #Save data mode
                if ($SaveOfflineData) {
                    Save-JsonData -InputObject $CsTenant -FilePath "$TenantCachePath/Get-CsTenant.json" -Force
                    Write-PScriboMessage -Plugin 'Module' -Message "Saved offline data for Get-CsTenant to path '$TenantCachePath/Get-CsTenant.json'."
                }
            }
        }


        #Save data mode







        $CSTenantInfo = [PSCustomObject]@{
            'Tenant Name' = $CsTenant.DisplayName
            'Tenant ID' = $CsTenant.TenantId
            'Sip Domains' = $CsTenant.SipDomain
            'Service Instance' = $CsTenant.ServiceInstance
            'Location' = "$($CsTenant.Street) ($($CsTenant.StateorProvince) $($CsTenant.PostalCode) $($CsTenant.CountryorRegion))"
        }

        $TableParams = @{
            Name = "Tenant - $($CsTenant.DisplayName)"
            List = $true
            ColumnWidths = 50, 50
        }
        if ($Report.ShowTableCaptions) {
            $TableParams['Caption'] = "- $($TableParams.Name)"
        }
        $CsTenantInfo | Table @TableParams
    }

    end {}
}
