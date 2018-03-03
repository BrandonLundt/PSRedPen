#Collect available plexus modules ahead of time, this speads up the argument completer considerably
$Modules = Get-Module -ListAvailable | Select-Object -Unique | Select-Object -ExpandProperty Name

Register-ArgumentCompleter -ParameterName Application -CommandName Invoke-Plexster, New-PLXSConfig -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
 
    $Modules | ForEach-Object {
        New-Object System.Management.Automation.CompletionResult (
            $_,
            $_,
            'ParameterValue',
            $_
        )
    }#Foreach-object
}#Register-ArugmentCompleter
