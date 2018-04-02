FormatTaskName "-------- {0} --------"
. "$PSScriptRoot\Settings.build.ps1"

<# Throw error about not empty git status if .git exists.#>
task -name "GitStatus" -precondition {Test-Path ".git"} -action {
	$status = exec { git status -s }
	if ($status) {
		Write-Error -Message "Git status: $($status -join ', ')"
	}
}#task GitStatus

$UnloadModule_Properties = @{
	description       = "Removes Module from RAM"
	requiredVariables = "ModuleName"
	precondition      = { (Get-module $ModuleName).count -gt 0 }
}

Task -name "UnLoad Module" @UnloadModule_Properties -action {
	Remove-Module $ModuleName
} #Unload module

task -name "Clean temp" -precondition {Test-Path "$env:temp\$ModuleName"} -action {
	Get-ChildItem -Path "$env:temp\$ModuleName" | Remove-Item -Recurse
}
task -name "Clean" -description "Cleans up temp and module directories" -depends "Unload Module","Clean temp" -precondition { Test-Path $InstallPath } -action {
	Get-ChildItem $InstallPath | Remove-Item -Recurse
}#Clean task

task -name "Analyze" -Action {
	$saResults = Invoke-ScriptAnalyzer -Path $SrcRootDir -Severity @('Error', 'Warning') -Settings $ScriptAnalyzerSettingsPath -Recurse #-Verbose:$false
	$Errors = $saResults | Where-Object -FilterScript {$_.Severity -like 'Error'}
	$Warnings = $saResults | Where-Object -FilterScript {$_.Severity -like 'Warning'}
	if ($Errors) {
		$Errors | Format-Table
		Write-Error -Message 'One or more Script Analyzer errors where found. Build cannot continue!'
	}
	if ( $Warnings){
		$Warnings | Format-Table
		Write-Warning -Message "One or more Script Analyzer warnings were found!"
	}
}
task -name "Test" -depends "Unload Module" -action {
	$testResults = Invoke-Pester -Path $UnitTestDir -PassThru -Show None
	if ($testResults.FailedCount -gt 0) {
		$testResults | Format-List
		Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
	}
}

task -name "Manifest" -description "Generates module manifest" -requiredVariables Version,InstallPath -action {
	<#Collect functions available and add them to the "nested modules" #>
	$NestedModules = @()
	$FunctionsToExport = @()
	Get-ChildItem -Path $FunctionDir -Include *.psm1 -Recurse | Select-Object Name, BaseName | ForEach-Object -Process {
		[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
		$NestedModules += (".\Functions\" + $_.Name)
		[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
		$FunctionsToExport += $_.BaseName
	}
	$Manifest_Params = @{
		Path              = "$SrcRootDir\$ModuleName.psd1"
		GUID              = $GUID
		Author            = $Author
		CompanyName       = $CompanyName
		CopyRight         = $CopyRight
		ModuleVersion     = $Version
		PowerShellVersion = $PowerShellVersion
		NestedModules     = $NestedModules
		Description       = $Description
		FunctionsToExport = $FunctionsToExport
		ReleaseNotes      = $ReleaseNotes
	}
	if ( Test-path "$SrcRootDir\$ModuleName.psm1") {
		$Manifest_Params.Add( "RootModule", "$ModuleName.psm1")
	}
	if ( Test-Path "$SrcRootDir\$ModuleName.psd1") {
		$Manifest = Get-Item "$SrcRootDir\$ModuleName.psd1"
		$Settings = Get-Item "$PSScriptRoot\Settings.build.ps1"
		if ( $Manifest.LastWriteTime -lt $Settings.LastWriteTime) {
			Update-ModuleManifest @Manifest_Params
		}#if
	}
	else {
		New-ModuleManifest @Manifest_Params
	}#if manifest doesn't exist
}#Task create manifest

Task -name "Module" -description "Populates module directory" -requiredVariables InstallPath, Version -action {
	Get-ChildItem -Path "$PSScriptRoot\Module" | Copy-Item -Recurse -Destination $InstallPath
}

Task -name "Help" -description "Updates external help files and nested readme.md" -depends "Module" -action {
	New-MarkdownHelp -Module $ModuleName -AlphabeticParamsOrder -OutputFolder "$env:temp\$ModuleName\Docs" -Force | Out-Null
	New-ExternalHelp -Path "$env:temp\$ModuleName\Docs" -OutputPath "$InstallPath\en-US" -Force | Out-Null
	#Get-ChildItem -Path "$env:temp\$ModuleName\Docs" -File | ForEach-Object { Move-Item -Path $_ -Destination ("Functions\" + $_.BaseName + "\ReadMe.MD") -Force }
	Get-ChildItem -Path "$InstallPath\Functions" -Include *.psm1 -Recurse | ForEach-Object -Process {
		<#now remove comment based help from functions#>
		#Write-Host "Processing $_"
		$Content = Get-Content -LiteralPath $_.FullName -Raw

		# the .IndexOf() method is case sensitive
		#    that is why i used -match = to get the actual string that is used
		$Index = $Content.IndexOf("<#")
		$End = $Content.IndexOf("#>") + 2

		if ( ($Index -gt 0) -and ($End -gt 0) ) {
			$OutStuff = $Content.Substring(0, $Index)
			$Length = $Content.Length - $End
			$OutStuff += $Content.Substring($End, $Length)
			Out-File -FilePath $_.FullName -InputObject $OutStuff
		}
	}#foreach function in InstallPath

}

$CodeSigning_Params = @{
	name              = "Code Signing"
	description       = "Signs all module files"
	requiredVariables = @("ModuleName", "Version")
	precondition      = { $env:USERNAME -like "*.admin" }
}
task @CodeSigning_Params -action {
	$Cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
	New-FileCatalog -CatalogVersion 2 -CatalogFilePath "$InstallPath\$ModuleName.cat" -Path $InstallPath
	Get-childitem -Exclude *.xml -File -Path $InstallPath -Recurse | Set-AuthenticodeSignature -Certificate $Cert

}

$PublishProd_Params = @{
	name              = "CorePublish"
	precondition      = {Get-PSRepository -Name $RepositoryName}
	description       = "Publishes module to ProGet distribution points"
	requiredVariables = "Prod_ApiKey"
}
task @PublishProd_Params -action {
	Publish-Module -Name $ModuleName -Repository $RepositoryName -NuGetApiKey $Prod_ApiKey -RequiredVersion $Version
}

task -name "Success" -depends "GitStatus" -action {
	Get-Module -ListAvailable $ModuleName
} #-precondition "GitStatus"
Task ? -description 'Lists the available tasks' {
	"Available tasks:"
	$psake.context.Peek().Tasks.Keys | Sort-Object
}

task -name "Default" -depends Build
task -name "Build" -depends "Analyze", "Test", "Clean", "Module", "Manifest", "Help","Clean temp"
#task -name "Publish" -depends "GitStatus","Analyze","Test","Clean","Module","Manifest","Help","Publish","Success"