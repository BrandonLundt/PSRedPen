Properties {
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$Author = "Brandon Lundt"

	# Default Locale used for help generation, defaults to en-US.
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$DefaultLocale = 'en-US'

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$DocsRootDir = "$PSScriptRoot\docs"

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$GUID = '8e7b8753-74f8-4d7a-be7d-8c62cc4e9c32'
	
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$CompanyName = "Plexus"
	
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$CopyRight = "2017"
	
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$Description = "Powershell module for automated integration testing"

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$FunctionDir = "$PSScriptRoot\Module\Functions"

	# The name of your module should match the basename of the PSD1 file.
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$ModuleName = "PSRedPen"

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$PowerShellVersion = '5.1'

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$ReleaseNotes = Get-Content -path "$PSScriptRoot\ReleaseNotes.md" -Raw

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$SrcRootDir = "$PSScriptRoot\Module"

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$UnitTestDir = "$PSScriptRoot\Tests\"

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$Version = "0.5"

	# The local installation directory for the install task. Defaults to your home Modules location.
	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$InstallPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$ModuleName\$Version\"

	[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
	$ScriptAnalyzerSettingsPath = "$PSScriptRoot\ScriptAnalyzerSettings.psd1"
}