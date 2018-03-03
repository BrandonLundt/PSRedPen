Function New-ConfigFile {
    [cmdletbinding()]
    param(
        [parameter( Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {    
                Import-Module $_ 
                if ( (Get-Module $_).Count -ge 1) {
                    $true
                }
                else {
                    throw "$_ is not a valid application"
                }
            }
        )]
        [string]$Application,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
    begin {
        New-Variable -Name ModuleBase -Value (Get-Module $Application).ModuleBase
    }
    process {
        Write-Verbose -Message ("Get Module " + $Application + " path of Module and append appropriate template folder information")
        Write-Verbose -Message ("ModuleBase is : " + $ModuleBase)
        $Template = ($ModuleBase + "\Template\")
        if ( -not (Test-Path $Template)) {
            throw (Write-Error -Message "Application does not contain applicable templates.")
        }
        elseif ( -not (Test-Path "$Template\PlasterManifest.xml")) {
            throw (Write-Error -Message "Application does not contain applicable templates.")
        }		
        Invoke-Plaster -TemplatePath $Template -DestinationPath $Destination -NoLogo
    }#Process
    end {
        Remove-variable -Name ModuleBase, Template
    }#End
}#Function