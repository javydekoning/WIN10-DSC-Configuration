#####################
# Pre-Requisites    #
#####################
'cChoco','PackageManagementProviderResource','PowerShellModule','xTimeZone','xHyper-V','cAppxPackage','xPSDesiredStateConfiguration' | %{
    if (-not(get-dscresource -module $_)) {find-module -name $_ | install-module -SkipPublisherCheck -force}
}

if (-not($cred)) {
    $cred = get-credential "$(whoami)"
}
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

#####################
# LCM Configuration #
#####################
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RefreshMode                    = 'Push'
            RebootNodeIfNeeded             = $true
            AllowModuleOverwrite           = $true
            ActionAfterReboot              = 'ContinueConfiguration' 
            ConfigurationMode              = 'ApplyandAutoCorrect'
            ConfigurationModeFrequencyMins = '15'
        }
    }
}
$out        = LCMConfig
$cimsession = New-CimSession -ComputerName localhost

Set-DscLocalConfigurationManager -Path $out.PSParentPath -Force -Verbose -CimSession $cimsession

#####################
# DSC Configuration #
#####################
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowPlainTextPassword = $true
            ChocoPackages               = @('googlechrome','filezilla','vlc','sublimetext3','jre8','7zip','greenshot','keepass','conemu','mysql.workbench','googledrive','f.lux','pidgin','unchecky','rufus','classic-shell','autohotkey','evernote','VisualStudioCode')
            WindowsFeatures             = @('Microsoft-Windows-Subsystem-Linux','Microsoft-Hyper-V','Microsoft-Hyper-V-All','Microsoft-Hyper-V-Hypervisor','Microsoft-Hyper-V-Management-Clients','Microsoft-Hyper-V-Management-PowerShell','Microsoft-Hyper-V-Services','Microsoft-Hyper-V-Tools-All','NetFx3','NetFx4-AdvSrvs')
            PowerShellModules           = @('PSScriptAnalyzer','Pester','PSReadline','PowerShellISE-preview','ISESteroids','RemoteDesktop')
            RemovedApps                 = @('Microsoft.3DBuilder','Microsoft.BingFinance','Microsoft.BingNews','Microsoft.BingSports','Microsoft.BingWeather','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.Office.OneNote','Microsoft.People','Microsoft.SkypeApp','Microsoft.Appconnector','Microsoft.Getstarted','microsoft.windowscommunicationsapps','Microsoft.WindowsMaps','Microsoft.WindowsPhone','Microsoft.XboxApp','Microsoft.XboxIdentityProvider','Microsoft.ZuneMusic','Microsoft.ZuneVideo')
        }
    )
}

configuration Win10
{
    param (
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'cChoco'
    Import-DscResource -ModuleName 'PackageManagementProviderResource'
    Import-DscResource -ModuleName 'PowerShellModule'
    Import-DscResource -ModuleName 'xTimeZone'  
    Import-DscResource -ModuleName 'xHyper-V'
    Import-DscResource -ModuleName 'cAppxPackage'  
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
 
    Node $AllNodes.NodeName
    {
        $Node.WindowsFeatures.ForEach{
            WindowsOptionalFeature "$_"
            {
                Name   = $_
                Ensure = 'Enable'
            }    
        }

        xRemoteFile 'profile'
        {
            DestinationPath = "$home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
            Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/Microsoft.PowerShell_profile.ps1'
            MatchSource     = $True
        }

        xRemoteFile 'ISE_Profile'
        {
            DestinationPath = "$home\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"
            Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/Microsoft.PowerShellISE_profile.ps1'
            MatchSource     = $True
        }

        xRemoteFile 'conemuconfig'
        {
            DestinationPath = "$env:APPDATA\ConEmu.xml"
            Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/ConEmu.xml'
            MatchSource     = $True
            DependsOn       = '[cChocoPackageInstaller]conemu'
        }

        xRemoteFile 'autohotkey'
        {
            DestinationPath = "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\ahkconfig.ahk"
            Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/ahkconfig.ahk'
            MatchSource     = $True
            DependsOn       = '[cChocoPackageInstaller]autohotkey'
        }

        cChocoInstaller installChoco
        {
            InstallDir = 'c:\choco'
        }
       
        $Node.ChocoPackages.ForEach{
            cChocoPackageInstaller $_
            {
                Name                 = "$_"
                DependsOn            = '[cChocoInstaller]installChoco'
                PsDscRunAsCredential = $Credential
                chocoParams          = '--allowemptychecksum --allowemptychecksumsecure'
                AutoUpgrade          = $True
            }
        }
 
        $Node.PowerShellModules.foreach{
            PSModuleResource $_
            {
                Ensure      = 'present'
                Module_Name = "$_"
            }    
        }

        xTimeZone TimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'W. Europe Standard Time'
        }
    
        xVMSwitch defaultSwitch
        {
            Name = 'defaultSwitch'
            Type = 'External'
            Ensure = 'present'
            DependsOn = '[WindowsOptionalFeature]Microsoft-Hyper-V-Management-PowerShell'
            NetAdapterName = 'Ethernet'
        } 
    
        $Node.RemovedApps.ForEach{
            cAppxPackage $_
            {
                Name                 = "$_"
                Ensure               = 'Absent'
                PsDscRunAsCredential = $Credential
            }
        }

        Registry 'DeveloperMode'
        {
            Ensure      = "Present"  
            Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
            ValueName   = "AllowDevelopmentWithoutDevLicense"
            ValueData   = "1"
            ValueType   = "Dword"
            Force       = $true
        }
    }
}

$config = win10 -ConfigurationData $ConfigurationData -credential $cred -verbose

Start-DscConfiguration -Verbose -Path $config.PSParentPath -Wait -force