<#
.SYNOPSIS
    Checks offline data cache for a specified Microsoft 365 tenant as JSON files.

.DESCRIPTION
    Sets up the environment to use offline data for testing purposes.
    Mainly testing to see if the data exists and can be loaded before calling the main report function loop.
    But can also be used to validate your own offline data cache before using it.

.PARAMETER TenantCachePath
    Path to the tenant folder containing the JSON file cache.
    Can either your own custom data or the sample data provided in the repo.
    Samples are ./Dev/Samples/<tenantname>

.EXAMPLE


.NOTES
    Author: Your Name
    Date:   YYYY-MM-DD
#>
function Test-AbrCsOfflineData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$TenantCachePath
    )
    #check if the base path exists
        if (-Not (Test-Path -Path $TenantCachePath)) {
            Throw "The specified tenant cache data path '$TenantCachePath' does not exist. Please check the path and try again."
        } else {
            Write-PScriboMessage -Plugin 'Module' -Message "Using offline data from path '$TenantCachePath'." #Todo update file list as we add more files
            $RequiredFiles = @(
                "Get-CsTenant.json",
                "Get-CsPSTNNumber.json",
                "Get-CsPSTNCallRouting.json",
                "Get-CsOnlineUser.json",
                "Get-CsHealthCheck.json"
            )
            #Check if all required files exist
            foreach ($File in $RequiredFiles) {
                $FilePath = Join-Path -Path $TenantCachePath -ChildPath $File
                if (-Not (Test-Path -Path $FilePath)) {
                    Throw "The required file '$File' is missing from the sample data path '$TenantCachePath'. Please check the files and try again."
                }
            }
            Write-PScriboMessage -Plugin 'Module' -Message 'All required files are present.'
        }

}
