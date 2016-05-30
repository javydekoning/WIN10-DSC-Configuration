Configuration PullServer 
{
    param  
    ( 
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string] $RegistrationKey 
     ) 

    Import-DscResource -modulename xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "Localhost"
    {
        $features = 'Web-Server','DSC-Service','Web-mgmt-tools'
        $features | %{
            WindowsFeature "$_"
            {
                Name = $_
                Ensure = 'Present'
            }      
        } 
        
        xdscwebservice "PSDSCPullServer" 
        {
            Ensure = 'present'
            State  = 'started'
            EndPointName = 'PSDSCPullServer'
            Port = '8080'
            CertificateThumbPrint = 'AllowUnencryptedTraffic'
            PhysicalPath = 'C:\inetpub\wwwroot\PSDSCPullServer'
            ModulePath = "$env:ProgramFiles\WinodwsPowerShell\DscService\Modules"
            ConfigurationPath = 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
            DependsOn = "[windowsFeature]DSC-Service"
        }

        File "RegistrationKeyFile"
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }
    }
}
$guid = '2aa1c9de-d3a6-40a5-a80d-52ce5346bcc0'
PullServer -RegistrationKey $guid