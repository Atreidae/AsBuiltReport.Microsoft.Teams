<#
    .SYNOPSIS
    This powershell script attempts to dot source all the modules in this repository.

    .DESCRIPTION
    Returns $True if no error was found

    .EXAMPLE
    Test-Importfunctions

    .INPUTS
    None

    .REQUIRED FUNCTIONS
    None

    .LINK
    http://www.UcMadScientist.com
    https://github.com/Atreidae/UcmPSTools

    .ACKNOWLEDGEMENTS
    Thanks to Adam the Automater for getting me started on Pipeline automation.
    Check out https://adamtheautomator.com/powershell-devops/ for more info!

    .NOTES
    Version:		1.1
    Date:			19/09/2025

    .VERSION HISTORY
    1.1: Added progress bars and verbose output
         Better error handling
         Better path handling

    1.0: Initial Public Release

#>
Function Test-ImportFunction {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required when dotsourcing from legacy scripts or when using dev code instead of module.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='Function')] #we are litterally showing something on screen for interactive purposes.

Param
  (
    [Parameter(Position=1)] [switch]$Private #Set to true to also import private functions
  )

$Global:LogFileLocation = $PSCommandPath -replace '.ps1','.log'

#Track if we imported anything
$AnythingImported = $False

## PS1 files should be in the Src folder, Public and Private subfolders
try
    {
    $PublicFuncFolderPath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Src') -ChildPath 'Public' | Resolve-Path -ErrorAction Stop
    $PrivateFuncFolderPath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Src') -ChildPath 'Private' | Resolve-Path -ErrorAction Stop
    }
catch
    {
    Write-Error "Unable to locate the Src folder, cannot continue"
    Return $False
    }

#Check there is actually files here
if ((Test-Path -Path $publicFuncFolderPath) -and ($publicFunctionNames = Get-ChildItem -Path $publicFuncFolderPath -Filter '*.ps1' | Select-Object PsPath))
{
  #Run through each file to import
  $total = $publicFunctionNames.PsPath.Count
  $current = 0

  ForEach ($FunctionName in $publicFunctionNames)
  {
    $current++
    Write-Progress -Activity "Importing Public Functions" -Status "Importing $($FunctionName.PsPath)" -PercentComplete (($current / $total) * 100)
    #Import the function
    Try
    {
      Write-verbose -Message "Importing $($FunctionName.PsPath)"
      .$FunctionName.PsPath
      $AnythingImported = $True
    }

    #Error during import
    Catch
    {
      Write-Error "Error importing $($FunctionName.pspath)"
      Write-Progress -Activity "Importing Public Functions" -Completed
      Return $False
    }
  }
  Write-Progress -Activity "Importing Public Functions" -Completed

}
#No files to import
else
{
  Write-Warning "No Public Modules to import, try with the Private flag set. Keep in mind you must expose at least one public function for the module to work correctly."
}

#Include importing the private functions
If ($private)
{
  #Check there is actually files here
  if ((Test-Path -Path $PrivateFuncFolderPath) -and ($PrivateFunctionNames = Get-ChildItem -Path $PrivateFuncFolderPath -Filter '*.ps1' | Select-Object PsPath))
  {
    $total = $PrivateFunctionNames.PsPath.Count
    $current = 0
    #Run through each file to import
    ForEach ($FunctionName in $PrivateFunctionNames)
    {
        $current++
        Write-Progress -Activity "Importing Private Functions" -Status "Importing $($FunctionName.PsPath)" -PercentComplete (($current / $total) * 100)
        #Import the function
        Try
        {
            Write-host "Importing $FunctionName"
            .$FunctionName.PsPath
            $AnythingImported = $True
        }

      #Error during import
      Catch
      {
        Write-Error "Error importing $FunctionName"
        Write-Progress -Activity "Importing Private Functions" -Completed
        Return $False
      }
    }
    Write-Progress -Activity "Importing Private Functions" -Completed
  }
  #No files to import
  else
  {
    Write-Warning "No Private Modules to import"
  }
}

#Return true if we didnt catch anything
if (-not $AnythingImported) { Write-Warning "No functions were imported, check the paths are correct" }
Return $AnythingImported
}
