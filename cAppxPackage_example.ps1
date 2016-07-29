$cred = get-credential

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName='Localhost'
            PSDscAllowPlainTextPassword=$true
         }
    )
}

configuration AppxExample
{
  param (
      [Parameter(Mandatory=$false)]
      [PSCredential]$Credential
  )
  
  Import-DscResource -ModuleName 'cAppxPackage'

  Node $AllNodes.NodeName {
    AppxResource 'Profile'
    {
      Name = 'Microsoft.WindowsAlarms'
      Ensure = 'Present'
      PsDscRunAsCredential = $Credential
    }
  }
}
$config = AppxExample -ConfigurationData $ConfigurationData -credential $cred


Start-DscConfiguration -Verbose -Path $config.PSParentPath -Wait -Force