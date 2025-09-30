<#
    .SYNOPSIS
    This file is used to run a test report using test data rather than scraping a production tenant

    .DESCRIPTION
    This script is to setup a persistent test environment for testing the AsBuiltReport.Microsoft.Teams module.
    It does not follow best practice in allowing parameter input, as it is designed to be set and forget.
    Addtionally it allows for offline data stored in the /Dev/Samples folder to simulate a real tenant for both interactive and automated testing.


    .EXAMPLE
    ./Test-AbrReport.ps1

    .INPUTS
    None

#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='File')] #Required when dotsourcing from legacy scripts or when using dev code instead of module.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='File')] #we are litterally showing something on screen for interactive purposes.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Scope='File')] #We need to overwrite $PSScriptRoot to point to the module root, as we are running this from the /Dev folder

Param
    (

    ) #No parameters

#Overwite PSScriptRoot to match the module root, as we are running this from the /Dev folder
$PSScriptRoot = (Get-Item "$PSScriptRoot\..").FullName


## Settings for your test environment

#region Settings
### Global Settings
$ErrorActionPreference = 'Stop' #Stop on all errors
$VerbosePreference = 'Continue' #Show verbose messages

# ABR Config files. Reminder, these will typically be stored in the user profile in production.
# Sample files have been provided, however in production users would create their own using New-AsBuiltConfig and New-AsBuiltReportConfig and modify as required.

## Path to files. These can be absolute paths if you want to store them outside the repo
$Script:AsBuiltConfigFilePath = "$PSScriptRoot\Dev\Samples\AbrConfig\AsBuiltReport.json" #Path to the AsBuiltReport.json config file you want to test with
$Script:ReportConfigFilePath = "$PSScriptRoot\Dev\Samples\AbrConfig\AsBuiltReport.Microsoft.Teams.json" #Path to the AsBuiltReport.Microsoft.Teams.json config file
$Script:SampleFolderPath = "$PSScriptRoot\Dev\Samples" #Path to the sample data folder

## Report Data Source Settings
$Script:DataSource = 'Offline' #Options are 'Live' or 'Offline'. Live will connect to the tenant, Offline will use the sample data path

## Offline Data Settings, only used if DataSource is set to 'Offline'
$Script:UseOfflineData = $True #Use offline data from the sample data path
$Script:SampleTenant = 'TestTeannt1' #The name of the folder in /Dev/Samples to use

## Live Data Settings, only used if DataSource is set to 'Live'
$TenantId = '' #The tenant ID to use for live data. Leave blank to use the first tenant found in the credential
$Credential = $Null #The credential to use for live data. Leave blank to use MFA
$MFA = $True #Use MFA for live data. Set to $False to use the credential above

## Report Settings
$Format = 'Html' #The format to generate. Comma separate for multiple formats. Options are: Word, Html, Text
$OutputFolderPath = "$PSScriptRoot\reports" #The path to save the report to
$Timestamp = $True #Append a timestamp to the report file name

#endregion Settings

#region config sanity checks

Switch ($DataSource) {
    'Offline' {
        $Script:UseOfflineData = $True
        $Script:SaveOfflineData = $False
    }
    'Live' {
        $Script:UseOfflineData = $False
        $Script:SaveOfflineData = $False
        if ($MFA -and $Credential) {
            throw "You cannot use both MFA and a Credential at the same time. Please select one or the other. Report Aborted."
        }
    }
    Default {
        throw "Invalid DataSource value '$DataSource' in Test-AbrReport.ps1. Please use 'Live' or 'Offline'. Report Aborted."
    }
}

#Build the Tenant Cache Path based on Sample Data Path and SampleTenant
$Global:TenantCachePath = (Join-Path -Path $SampleFolderPath -ChildPath $SampleTenant)

#endregion config sanity checks

#region Prepare the environment



# Now, test the ABR functions import
    . $PSScriptRoot\Dev\Test-ImportFunction.ps1    #Dot source the script to import the test function
    $ImportTest = (Test-ImportFunction -Private)   #Test the import of the private functions
    if (-not $ImportTest) { throw "Failed to import the functions, Aborting Report" }

#The test passed, import the module
Import-Module "$PSScriptRoot\AsBuiltReport.Microsoft.Teams.psm1" -Force -ErrorAction Stop

#Dot source the private functions we need for testing
    . $PSScriptRoot\Dev\Export-AbrCsOfflineData.ps1
    . $PSScriptRoot\Dev\Import-AbrCsOfflineVariable.ps1
    . $PSScriptRoot\Dev\Test-AbrCsOfflineData.ps1
    . $PSScriptRoot\Dev\Save-AbrCsOfflineVariable.ps1

#Test the offline data if we are using it
if ($UseOfflineData) {

    $TestOffline = (Test-AbrCsOfflineData -TenantCachePath $TenantCachePath)
    if (-not $TestOffline) { throw "Failed to validate the offline data, Aborting Report" }
}


#Then, make sure we have the required modules

#Check for requied modules, throws error and exits if not found
    @(
        @{ Name = 'AsBuiltReport.Core'; Version = '1.4.0' }
        @{ Name = 'MicrosoftTeams'; Version = '5.0.0' }
       # @{ Name = 'PnP.PowerShell'; Version = '2.0.0' }
    ) | Test-RequiredModule



#Import the AsBuiltReport config files, this section modified from AsBuiltReport.Core, Thanks Tim


# Import the AsBuiltReport JSON configuration file
        # If no path was specified, or the specified file doesn't exist, Throw an error and exit
        if ($AsBuiltConfigFilePath) {
            if (Test-Path -Path $AsBuiltConfigFilePath) {
                $Global:AsBuiltConfig = Get-Content -Path $AsBuiltConfigFilePath | ConvertFrom-Json
                # Verbose Output for As Built Report configuration
                Write-Verbose -Message "Loading As Built Report configuration from '$AsBuiltConfigFilePath'."
            } else {
                Write-Error "Could not find As Built Report configuration in path '$AsBuiltConfigFilePath'."
                break
            }
        } else {
            Write-Error "No As Built Report configuration file path specified. What did you expect me to do? Aborting Test."
            break
        }

        # Import the Report Configuration file
         if ($ReportConfigFilePath) {
            # If ReportConfigFilePath was specified, ensure the file provided in the path exists, otherwise exit with error
            if (-not (Test-Path -Path $ReportConfigFilePath)) {
                Write-Error "Could not find report configuration file in path '$ReportConfigFilePath'."
                break
            } else {
                #Import the Report Configuration in to a variable
                Write-Verbose -Message "Loading report configuration file from path '$ReportConfigFilePath'."
                $Global:ReportConfig = Get-Content -Path $ReportConfigFilePath | ConvertFrom-Json
            }
        } else {
            Write-Error "No As Built Report Module configuration file path specified. What did you expect me to do? Aborting Test."
            break
        }


        #endregion Prepare the environment


        #We now have an enviroment like what ABR sets up for the module
# Old testing code, disabled for now
<#
#Invoke the report



    new-AsBuiltReport -Report Microsoft.Teams -Target '78872ca8-56cd-44d6-af6f-4b6263a8cf3c' -MFA -Format Html -OutputFolderPath 'C:\UcMadScientist\AsBuiltReport.Microsoft.Teams\reports' -Timestamp -AsBuiltConfigFilePath c:\users\atrei\asbuiltreport\asbuiltreport.json -ReportConfigFilePath C:\users\atrei\asbuiltreport\AsBuiltReport.Microsoft.Teams.json #BSL
$bug = $error[0]


#$mfa = $True
#$target
#$target.TenantId = "ccb889e6-dc8d-4fe4-b842-d8efb6094a75"

#invoke-asbuiltreport.microsoft.teams -MFA -target "ccb889e6-dc8d-4fe4-b842-d8efb6094a75"


#Return true if we didnt catch anything
#Return $True

#New-AsBuiltReportConfig -Report Microsoft.Teams -FolderPath C:\UcMadScientist\AsBuiltReport.Microsoft.Teams\reports
remove-module 'AsBuiltReport.Microsoft.Teams'
Import-Module 'AsBuiltReport.Microsoft.Teams'
#pause
#new-AsBuiltReport -Report Microsoft.Teams -Target 'ccb889e6-dc8d-4fe4-b842-d8efb6094a75' -MFA -Format Html -OutputFolderPath 'C:\UcMadScientist\AsBuiltReport.Microsoft.Teams\reports' -Timestamp -AsBuiltConfigFilePath c:\users\atrei\asbuiltreport\asbuiltreport.json -ReportConfigFilePath C:\users\atrei\asbuiltreport\AsBuiltReport.Microsoft.Teams.json
new-AsBuiltReport -Report Microsoft.Teams -Target '78872ca8-56cd-44d6-af6f-4b6263a8cf3c' -MFA -Format Html -OutputFolderPath 'C:\UcMadScientist\AsBuiltReport.Microsoft.Teams\reports' -Timestamp -AsBuiltConfigFilePath c:\users\atrei\asbuiltreport\asbuiltreport.json -ReportConfigFilePath C:\users\atrei\asbuiltreport\AsBuiltReport.Microsoft.Teams.json #BSL
$bug = $error[0]


#$mfa = $True
#$target
#$target.TenantId = "ccb889e6-dc8d-4fe4-b842-d8efb6094a75"

#invoke-asbuiltreport.microsoft.teams -MFA -target "ccb889e6-dc8d-4fe4-b842-d8efb6094a75"

#>
