<#
.SYNOPSIS
    Saves a single variable for a specified Microsoft 365 tenant a JSON file.

.DESCRIPTION
    Saves the PSCustomObject passed in the DataToSave parameter to a JSON file named after the variable in a directory named after the tenant.
    This is useful for storing custom, potentially nested, PowerShell objects offline for later use or testing.

    To save all the files used in the module, use Export-AbrCsOfflineData.ps1 in the Dev folder.

    Initially created to save sample data for testing purposes. Can also be used to save your own data for later use should for any reason you not want/cannot to connect to the tenant directly.

.PARAMETER SampleTenant
    The name of the sample M365 tenant. This will be used as the folder name under the output path.

.PARAMETER SamplePath
    The root directory where the tenant folder and JSON files are located. Defaults to '../../samples/' relative to the script root.

.EXAMPLE


.NOTES
    Author: Your Name
    Date:   YYYY-MM-DD
#>
function Export-AbrCsOfflineVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$TenantCachePath,
        [Parameter(Mandatory)][string]$VariableName,
        [Parameter(Mandatory)]$DataToSave

    )

    begin {
        # Ensure output directory exists

        if (-not (Test-Path $TenantCachePath)) {
            #Test the parent path exists
            $parentFolder = Split-Path -Path $TenantCachePath -Parent
            if (-not (Test-Path $parentFolder)) {
                throw "The specified cache data path '$parentFolder' doesnt exist. Unable to continue, Exiting."
                #create the tenant folder if it doesnt exist
            }
            #Parent folder exists, create the tenant folder
            Write-PScriboMessage -Plugin 'Module' -Message "Tenant folder '$TenantCachePath' does not exist. Creating it now."
            New-Item -Path $TenantCachePath -ItemType Directory -Force | Out-Null
        }

    }

    process {
        try {
            # Save the array (or single object) as one JSON file
            $json = $DataToSave | ConvertTo-Json -Depth 100
            $filePath = Join-Path -Path $TenantCachePath -ChildPath "$VariableName.json"
            $json | Set-Content -Path $filePath -Encoding UTF8
        } catch {
            Write-PScriboMessage -Plugin 'Module' -Message "Error saving variable '$VariableName' to JSON file: $_" -Level 'Error'
            throw "Error saving variable '$VariableName' to JSON file: $_ Exiting"
        }
    }

    end {
        Write-Verbose "Offline data saved for variable '$VariableName' in '$TenantCachePath'"
    }
}
