function Get-AbrCsPSTNNumber {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft Teams PSTN Numbers
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         James Arber
        Twitter:        @UcMadScientist
        Github:         atreidae
    .EXAMPLE

    .LINK

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope = 'Function')] #we are litterally showing something on screen for interactive purposes.


    [CmdletBinding()]
    param (
        [Switch] $UseOfflineData, #Use offline data from the sample data path
        [Switch] $SaveOfflineData, #Save the data retrieved to the sample data path for future use
        [String] $SampleTenant = "TestTenant1" #The name of the folder in /Dev/Samples to use
    )

    begin {
        Write-PScriboMessage "PhoneNumbers InfoLevel set at $($InfoLevel.PhoneNumbers)."
    }

    process {
        #Check to see if UseOfflineData and SaveOfflineData are both set, if so, throw an error
        if ($UseOfflineData -and $SaveOfflineData) {
            throw "You cannot use both UseOfflineData and SaveOfflineData at the same time. Please select one or the other. Report Aborted."
        }

        if ($UseOfflineData) {
            # Example: Load sample tenant data
            Write-PScriboMessage 'Using Offline Phone Number Data'
            Write-Verbose 'Using Offline Phone Number Data'
            $CsTenant = Get-Content -Path (Join-Path $SampleDataPath 'Tenant.json') | ConvertFrom-Json
        } else {
            Write-Host "Collecting Phone Numbers, This may take some time" -ForegroundColor Green
            Write-PScriboMessage 'Collecting Phone Numbers.'
            $PhoneNumbers = Get-CsPhoneNumberAssignment -Top 1000000 | Sort-Object PhoneNumber
            #Save the data if required
            if ($SaveOfflineData) {
                # Save object to file
                $PhoneNumbers | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $SampleDataPath 'PhoneNumbers.json')
            }
        }

        #Region Phone Numbers


        if (($InfoLevel.PhoneNumbers -gt 0) -and ($PhoneNumbers)) {
            Section -Style Heading2 'Telephone Numbers' {
                Write-Host "Calculating phone number properties, This may take some time" -ForegroundColor Green
                #Measure the numbers to display in the blurb
                $UserNumbers = ($PhoneNumbers | Where-Object { ($_.Capability -contains 'UserAssignment') })
                $ServiceNumbers = ($PhoneNumbers | Where-Object { ($_.Capability -contains 'VoiceApplicationAssignment') })
                $AssignedUserNumbers = ($PhoneNumbers | Where-Object { ($_.Capability -contains 'UserAssignment') -and ($_.PstnAssignmentStatus -ne 'Unassigned') })
                $AssignedServiceNumbers = ($PhoneNumbers | Where-Object { ($_.Capability -contains 'VoiceApplicationAssignment') -and ($_.PstnAssignmentStatus -ne 'Unassigned') })
                $UnassignedUserNumbers = ($PhoneNumbers | Where-Object { ($_.Capability -contains 'UserAssignment') -and ($_.PstnAssignmentStatus -eq 'Unassigned') })
                $UnassignedServiceNumbers = ($PhoneNumbers | Where-Object { ($_.Capability -contains 'VoiceApplicationAssignment') -and ($_.PstnAssignmentStatus -eq 'Unassigned') })
                $DirectRoutingNumbers = ($PhoneNumbers | Where-Object { ($_.NumberType -eq 'DirectRouting') })
                $MSCallingPlanNumbers = ($PhoneNumbers | Where-Object { ($_.NumberType -eq 'CallingPlan') -and ($_.PstnPartnerName -eq 'Microsoft') })
                $OperatorConnectNumbers = ($PhoneNumbers | Where-Object { ($_.NumberType -eq 'CallingPlan') -and ($_.PstnPartnerName -ne 'Microsoft') })
                $UniqueCities = ($PhoneNumbers | Select-Object -ExpandProperty City -Unique)
                $NumberProviders = ($PhoneNumbers | Select-Object -ExpandProperty PstnPartnerName -Unique)
                $HundredNumberBlocks = ($PhoneNumbers.TelephoneNumber -replace '(.*)\d{2}$', '$1' | Select-Object -Unique)

                if ($Options.ShowSectionBlurb) {
                    if (!$options.ShowSectionFullDescription) {
                        #We dont want the blurb and the full description if the user selects both
                        Paragraph 'Telephone Numbers are globaly unique numbers assigned to users and voice applications to allow them to connect to the PSTN'
                        BlankLine
                    }
                }
                if ($Options.ShowSectionFullDescription) {
                    Paragraph 'Telephone Numbers are globaly uniquie numbers assigned to users and voice applications to allow them to connect to the PSTN'
                    Paragraph {
                        Text 'These are provided by your PSTN provider and are used to uniquely identify your users and voice applications. '
                        Text 'They come in two variants, '; Text 'Service Numbers' -Bold; Text 'and'; Text 'User Numbers' -Bold
                        Text 'Service Numbers are used to provide a single number for a service such as a Call Queue, Auto Attendant, or Conference Bridge. '
                        Text 'User Numbers are used to provide a number for a user to receive calls on. '
                        Text 'For more information see https://learn.microsoft.com/en-us/microsoftteams/different-kinds-of-phone-numbers-used-for-calling-plans?WT.mc_id=M365-MVP-5003444' }
                    BlankLine
                }

                Section -Style Heading3 'Phone Number Summary' {
                    Paragraph "The following table shows a summary of PSTN numbers within $($CsTenant.DisplayName) tenant."

                    $PhoneNumbersSummary = @()
                    #Im sure there is a better way of doing this with an array and get-variable. But this works.
                    $InObj = [Ordered]@{
                        'Name' = 'Total Numbers'
                        'Count' = $PhoneNumbers.Count
                        'Description' = 'Total Number of PSTN Numbers Present in the Tenant'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'User Numbers'
                        'Count' = $UserNumbers.Count
                        'Description' = 'Total Number of User Numbers Present in the Tenant'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Service Numbers'
                        'Count' = $ServiceNumbers.Count
                        'Description' = 'Total Number of Service Numbers Present in the Tenant'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Assigned User Numbers'
                        'Count' = $AssignedUserNumbers.Count
                        'Description' = 'User Numbers Assigned to Users'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Assigned Service Numbers'
                        'Count' = $AssignedServiceNumbers.Count
                        'Description' = 'Service Numbers Assigned to Voice Applications'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Unassigned User Numbers'
                        'Count' = $UnassignedUserNumbers.Count
                        'Description' = 'Unassgined User Numbers'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Unassigned Service Numbers'
                        'Count' = $UnassignedServiceNumbers.Count
                        'Description' = 'Unassigned Service Numbers'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Calling Plan Numbers'
                        'Count' = $MSCallingPlanNumbers.Count
                        'Description' = 'Numbers provided by Microsoft Calling Plans'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Direct Routing Numbers'
                        'Count' = $DirectRoutingNumbers.Count
                        'Description' = 'Numbers provided by Direct Routing'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Operator Connect Numbers'
                        'Count' = $OperatorConnectNumbers.Count
                        'Description' = 'Numbers provided by Operator Connect Partners'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = 'Uniqiue Cities'
                        'Count' = $UniqueCities.Count
                        'Description' = 'Number of unique number regions by city'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        'Name' = '100 Number Blocks'
                        'Count' = $HundredNumberBlocks.Count
                        'Description' = 'Number of unique 100 number blocks'
                    }
                    $PhoneNumbersSummary += [PSCustomObject]$InObj


                    ##Todo fix this, presently it assumes the values are properties, when they are not.
                    if ($Healthcheck.PhoneNumbers.LowAvailability) {
                        Write-PScriboMessage 'Low Availability Healthcheck'
                        $PhoneNumbersSummary | Where-Object { $_.'Available User Numbers' -lt ((($PhoneNumbersSummary.UserNumbers.count) / 10)) } | Set-Style -Style Critical -Property 'Available User Numbers'
                        $PhoneNumbersSummary | Where-Object { $_.'Available Service Numbers' -lt ((($PhoneNumbersSummary.ServiceNumbers.count) / 50)) } | Set-Style -Style Critical -Property 'Available Service Numbers'
                    }


                    $TableParams = @{
                        Name = 'Number Summary'
                        List = $false
                        Columns = 'Name', 'Count', 'Description'
                        ColumnWidths = 40, 10, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $PhoneNumbersSummary | Table @TableParams
                }
                Section -Style Heading3 'Phone Numbers by City' {
                    [array]$CityNumberInfo = @()
                    foreach ($UniqueCity in $UniqueCities) {
                        $InObj = [Ordered]@{
                            'City' = $UniqueCity
                            'Total Numbers' = ($PhoneNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                            'User Numbers' = ($UserNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                            'Service Numbers' = ($ServiceNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                            'Assigned User Numbers' = ($AssignedUserNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                            'Assigned Service Numbers' = ($AssignedServiceNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                            'Available User Numbers' = ($UnassignedUserNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                            'Available Service Numbers' = ($UnassignedUserNumbers | Where-Object { $_.City -eq $UniqueCity }).count
                        }
                        $CityNumberInfo += [PSCustomObject]$InObj
                    }

                    if ($Healthcheck.PhoneNumbers.LowAvailability) {
                        Write-PScriboMessage 'Low Availability Healthcheck'
                        $CityNumberInfo | Where-Object { $_.'Available User Numbers' -lt 10 } | Set-Style -Style Critical -Property 'Available User Numbers'
                        $CityNumberInfo | Where-Object { $_.'Available Service Numbers' -lt 1 } | Set-Style -Style Critical -Property 'Available Service Numbers'
                    }
                    if (($InfoLevel.PhoneNumbers -le 2) -and ($PhoneNumbers)) {
                        Paragraph 'The following table show a summary of PSTN numbers broken down by their city.'
                        $TableParams = @{
                            Name = 'Numbers By City'
                            List = $false
                            Columns = 'City', 'User Numbers', 'Service Numbers', 'Available User Numbers', 'Available Service Numbers', 'Total Numbers'
                            ColumnWidths = 20, 16, 16, 16, 16, 16
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $CityNumberInfo | Table @TableParams
                    } else {

                        Paragraph 'The following tables show a summary of PSTN numbers broken down by their city.'
                        foreach ($UniqueCityInfo in $CityNumberInfo) {
                            Section -Style Heading4 "$($UniqueCityInfo.City)" {
                                $TableParams = @{
                                    Name = "Numbers By City - $($UniqueCityInfo.City)"
                                    List = $true
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $UniqueCityInfo | Table @TableParams
                            }
                        }
                    }
                }
                Section -Style Heading3 'Phone Numbers by Provider' {
                    $ProviderNumberInfo = @()

                    #Direct Routing Numbers
                    $InObj = [Ordered]@{
                        'Provider' = 'Direct Routing'
                        'Total Numbers' = ($PhoneNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                        'User Numbers' = ($UserNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                        'Service Numbers' = ($ServiceNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                        'Assigned User Numbers' = ($AssignedUserNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                        'Assigned Service Numbers' = ($AssignedServiceNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                        'Available User Numbers' = ($UnassignedUserNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                        'Available Service Numbers' = ($UnassignedUserNumbers | Where-Object { $_.NumberType -eq 'DirectRouting' }).count
                    }
                    $ProviderNumberInfo += [PSCustomObject]$InObj

                    #Operator Connect Providers
                    foreach ($NumberProvider in $NumberProviders) {
                        $InObj = [Ordered]@{
                            'Provider' = $NumberProvider
                            'Total Numbers' = ($PhoneNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                            'User Numbers' = ($UserNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                            'Service Numbers' = ($ServiceNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                            'Assigned User Numbers' = ($AssignedUserNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                            'Assigned Service Numbers' = ($AssignedServiceNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                            'Available User Numbers' = ($UnassignedUserNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                            'Available Service Numbers' = ($UnassignedUserNumbers | Where-Object { $_.PstnPartnerName -eq $NumberProvider }).count
                        }
                        $ProviderNumberInfo += [PSCustomObject]$InObj
                    }
                    if (($InfoLevel.PhoneNumbers -le 2) -and ($PhoneNumbers)) {
                        Paragraph 'The following table show a summary of PSTN numbers broken down by their provider.'
                        $TableParams = @{
                            Name = 'Numbers By Provider'
                            List = $false
                            Columns = 'Provider', 'User Numbers', 'Service Numbers', 'Available User Numbers', 'Available Service Numbers', 'Total Numbers'
                            ColumnWidths = 20, 16, 16, 16, 16, 16
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ProviderNumberInfo | Table @TableParams
                    } else {

                        Paragraph 'The following tables show a summary of PSTN numbers broken down by their provider.'
                        foreach ($UniqueProviderNumberInfo in $ProviderNumberInfo) {
                            Section -Style Heading4 "$($UniqueProviderNumberInfo.Provider)" {
                                $TableParams = @{
                                    Name = "Numbers By Provider - $($UniqueProviderNumberInfo.Provider)"
                                    List = $true
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $UniqueCityInfo | Table @TableParams
                            }
                        }
                    }
                }
                Section -Style Heading3 'Phone Numbers by Number Range' {
                    $HundredNumberInfo = @()
                    foreach ($HundredNumberBlock in $HundredNumberBlocks) {
                        #Calculate provider
                        if ( ($PhoneNumbers | Where-Object { ($_.TelephoneNumber -match "\$($HundredNumberBlock)*") -and ($_.NumberType -eq 'DirectRouting') })) {
                            $Provider = 'Direct Routing'
                        } else {
                            $Provider = ($PhoneNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)*" } | Select-Object -ExpandProperty PstnPartnerName -Unique)
                        }

                        $InObj = [Ordered]@{
                            'NumberBlock' = "$($HundredNumberBlock)xx"
                            'Total Numbers' = ($PhoneNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'User Numbers' = ($UserNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'Service Numbers' = ($ServiceNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'Assigned User Numbers' = ($AssignedUserNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'Assigned Service Numbers' = ($AssignedServiceNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'Available User Numbers' = ($UnassignedUserNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'Available Service Numbers' = ($UnassignedServiceNumbers | Where-Object { $_.TelephoneNumber -match "\$($HundredNumberBlock)\d{2}$" }).count
                            'Provider' = $Provider
                        }
                        [System.Collections.ArrayList]$HundredNumberInfo += [PSCustomObject]$InObj
                    }

                    if ($Healthcheck.PhoneNumbers.WeirdNumberRanges) {
                        Write-PScriboMessage 'Weird Phone Range Healthcheck'
                        $HundredNumberInfo | Where-Object { $_.'Total Numbers' -lt 10 } | Set-Style -Style Critical -Property 'Total Numbers'
                    }
                    if ($Healthcheck.PhoneNumbers.LowAvailability) {
                        Write-PScriboMessage 'Low Availability Healthcheck'
                        $HundredNumberInfo | Where-Object { $_.'Available User Numbers' -lt 10 } | Set-Style -Style Critical -Property 'Available User Numbers'
                        $HundredNumberInfo | Where-Object { $_.'Available Service Numbers' -lt 1 } | Set-Style -Style Critical -Property 'Available Service Numbers'
                    }

                    if (($InfoLevel.PhoneNumbers -le 2) -and ($PhoneNumbers)) {
                        Paragraph 'The following table show a summary of PSTN numbers broken down by their number range.'
                        $TableParams = @{
                            Name = 'Numbers By Range'
                            List = $false
                            Columns = 'NumberBlock', 'User Numbers', 'Service Numbers', 'Available User Numbers', 'Available Service Numbers', 'Total Numbers', 'Provider'
                            ColumnWidths = 30, 10, 10, 10, 10, 10 , 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $HundredNumberInfo | Table @TableParams
                    } else {

                        Paragraph 'The following tables show a summary of PSTN numbers broken down by their number range.'
                        foreach ($HundredNumberblock in $HundredNumberInfo) {
                            Section -Style Heading4 "$($HundredNumberblock.NumberBlock)" {
                                $TableParams = @{
                                    Name = "Numbers By Range - $($HundredNumberblock.NumberBlock)"
                                    List = $true
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($HundredNumberblock.NumberBlock)"
                                }
                                $HundredNumberblock | Table @TableParams
                            }
                        }
                    }




                }
                #Application instances that are not AA or CQ's


            }
        } else {
            Section -Style Heading2 'Telephone Numbers' {
                Paragraph 'No Telephone Numbers found, Your Tenant will be uable to make and recieve phone calls using the PSTN.'
                Paragraph 'See https://learn.microsoft.com/en-us/microsoftteams/getting-phone-numbers-for-your-users?WT.mc_id=M365-MVP-5003444 for more information.'
            }
        }
        #endregion Phone Numbers
    }

    end {}
}
