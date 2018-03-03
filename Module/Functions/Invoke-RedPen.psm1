Function Invoke-RedPen {
    <#
	.Synopsis
	   Wrapper module for Powershell Module Pester, to assist in test promotion processes.
	.DESCRIPTION
	   Module to allow for scheduled execution of integration tests with results e-mailed. 
	.EXAMPLE
	   Invoke-RedPen -ConfigFile ./Demo.psd1 -Application Demo -EmailAddress sys.admin@gmail.com
	.Notes
		Name: Invoke-RedPen
		Author: Brandon Lundt
		Requires: PowerShell v5 and Pester 3.4.3 or newer		
	#>
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ -like "*.json") {
                    if ( Test-Path $_) {
                        $True
                    }#Test-Path True
                    else {
                        Throw "Unable to locate $_"
                    }#Test-Path false
                }#if match json true
                else {
                    Throw "$_ must be a valid psd1 or JSON file"
                }#if match json false
            }
        )]
        [string]$ConfigFile,
        [parameter(
            Mandatory = $false
        )]
        [ValidateSet("Simple", "Comprehensive")]
        [string]$TestType = "Simple",
        [parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Tags,
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {    
                Import-Module $_ 
                if ( (Get-Module $_).Count -ge 1) {
                    $true
                }
                else {
                    throw "$_ is not a valid application module"
                }
            }
        )]
        [string]$Application,
        [Parameter(Mandatory = $True)]
        [string]$SmtpServer,
        [Parameter(Mandatory = $True)]
        [string]$From,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$To
    )
    begin {
        New-Variable -Name Application
        New-Variable -Name Config
        New-Variable -Name HTMLFile
        New-Variable -Name Pester_Variables
        New-Variable -Name Test_Results
        #############################
        Write-Verbose -Message "Need to create a temp file to store our HTML"
        $HTMLFile = ($env:TEMP + "Body.html")
        if ( Test-Path $HTMLFile) {
            Remove-Item $HTMLFile
        }#if
		
        $Pester_Variables = @{
            Script       = $TestsPath
            OutputFile   = ($env:TEMP + "\TestResults.xml")
            OutputFormat = "NUnitxml"
        }#Pester_Variables
    }
    process {
        Write-Verbose -Message ("Get Module " + $Application + " path of Module and append appropriate diagnostics folder information")
        Write-Verbose -Message ("ModuleBase is : " + (Get-Module $Application).ModuleBase)
        $TestsPath = ((Get-Module $Application).ModuleBase + "\Diagnostics\" + $TestType)
        #############################
        Write-Verbose -Message ("Import JSON file:  " + $ConfigFile )
        #ConvertPSObjectToHashtable is defined at the top of this file
        #we need the function to do appropriate conversion of multiple nested levels
        #(ConvertFrom-Json $json).psobject.properties | ForEach-Object { $config[$_.Name] = $_.Value }
        #only gives one level deep of a hashtable
		
        #This probably needs to be reviewed as it assumes the integration tests will utilize $Config
        $Config = Get-Content -Path $ConfigFile | ConvertFrom-Json | ConvertTo-PLXSHashtable

        <#
        Honestly, I have had worse ideas than this, but not many
        and I can't remember what they were.
        The reportunit.exe provides some very nice output for "graphical" view of the results.
        #>
        $ReportUnit = (Get-Module PLXS_RedPen).ModuleBase + "\Private\ReportUnit.exe"
        Write-Verbose "Scripts directory is $TestsPath"
        Write-Verbose "Checking configuration first"
        $Test_Results = Invoke-Pester -Tags "Config" -PassThru @Pester_Variables
		
        If ( $Test_Results.FailedCount -gt 0) {		
            Write-Error "Invalid Configuration, please correct config definition failures."
        }#if
        else {
            <#
				If the configuration tests pass, run the rest of the integration tests.
			#>
            $Test_Results = Invoke-Pester -Tag $Tags -PassThru -ExcludeTag "Config" @Pester_Variables
        }#else
        <#
			The -PassThru parameter allows for the test results to be passed back and to formulate an e-mail.
			Because we get all test reults back, we need to check just the failed count.
		#>
        . $ReportUnit $env:TEMP\TestResults.xml $env:TEMP\TestResults.html
        $Subject = ($Application + " : " + $ConfigFile + " Configuration failures identified")
        $Body = Get-Content -Path $env:TEMP\TestResults.html -Raw
        Send-MailMessage -From $From -To $To -SmtpServer $SmtpServer -Subject $Subject -BodyAsHtml $Body
    }#Process
    end {
        Remove-variable -Name Application, Config, HTMLFile, Pester_Variables, Test_Results
    }#End
}#Function