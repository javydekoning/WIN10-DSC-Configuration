function prompt {
   "[JavydeKoning.com] $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))"
}

ls $home\github\PowershellTools\ *.psm1 -ea 0 | % {import-module $_.fullname -ea 0}

$CredFile = "$HOME\modules\CredFile.cred"
if (Test-Path $CredFile) {
   $c = Import-Clixml $CredFile
} else {
   Write-Warning "No Credential file found at $CredFile"
} 

Register-EngineEvent PowerShell.Exiting –Action {
   Export-Clixml -InputObject $c -Path $CredFile
}

function Unlock-ADUser {
   param ($User);
   $User = [adsi]([adsisearcher]"samaccountname=$user").findone().path;
   $User.psbase.InvokeSet('IsAccountLocked',$false);
   $User.SetInfo()
}  
