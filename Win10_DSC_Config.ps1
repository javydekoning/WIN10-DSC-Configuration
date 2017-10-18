#####################
# Pre-Requisites    #
#####################
Enable-PSRemoting -SkipNetworkProfileCheck -Force

$dscresources = 'cChoco','PackageManagementProviderResource','PowerShellModule',
                'xTimeZone','cAppxPackage','xPSDesiredStateConfiguration'

$dscresources.ForEach({
  if (-not(get-dscresource -module $_)) {
    find-module -name $_ | install-module -SkipPublisherCheck -force
  }
})

if (!$cred) {$cred = get-credential "$(whoami)"}

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

Set-DscLocalConfigurationManager -Path $out.PSParentPath -Force -Verbose `
-CimSession $cimsession

#####################
# DSC Configuration #
#####################
$ChocoPackages = @(
  'googlechrome','filezilla','sublimetext3','jre8','7zip','greenshot','keepass',
  'mysql.workbench','f.lux','pidgin','unchecky','rufus','autohotkey','evernote',
  'nodejs','keypirinha','MobaXTerm','visualstudiocode'
)

$WindowsFeatures = @(
  'Microsoft-Windows-Subsystem-Linux','Microsoft-Hyper-V',
  'Microsoft-Hyper-V-All','Microsoft-Hyper-V-Hypervisor',
  'Microsoft-Hyper-V-Management-Clients',
  'Microsoft-Hyper-V-Management-PowerShell','Microsoft-Hyper-V-Services',
  'Microsoft-Hyper-V-Tools-All'
)

$PowerShellModules = @(
  'PSScriptAnalyzer','Pester','ISESteroids','RemoteDesktop','z'
)

$ConfigurationData = @{
  AllNodes = @(
    @{
        NodeName                    = 'Localhost'
        #Not safe but required for cChoco packages
        PSDscAllowPlainTextPassword = $true
        ChocoPackages               = $ChocoPackages
        WindowsFeatures             = $WindowsFeatures
        PowerShellModules           = $PowerShellModules
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

    xRemoteFile 'autohotkey'
    {
      DestinationPath = "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\ahkconfig.ahk"
      Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/ahkconfig.ahk'
      MatchSource     = $True
      DependsOn       = '[cChocoPackageInstaller]autohotkey'
    }

    xRemoteFile 'sublime-package-control'
    {
      DestinationPath = "$env:appdata\Sublime Text 3\Installed Packages\Package Control.sublime-package"
      Uri             = 'https://packagecontrol.io/Package%20Control.sublime-package'
      MatchSource     = $True
      DependsOn       = '[cChocoPackageInstaller]sublimetext3'
    }

    xRemoteFile 'Keypirinha.ini'
    {
      DestinationPath = "$env:APPDATA\Keypirinha\User\Keypirinha.ini"
      Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/Keypirinha/Keypirinha.ini'
      MatchSource     = $True
      DependsOn       = '[cChocoPackageInstaller]Keypirinha'
    }

    xRemoteFile 'apps.ini'
    {
      DestinationPath = "$env:APPDATA\Keypirinha\User\apps.ini"
      Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/Keypirinha/apps.ini'
      MatchSource     = $True
      DependsOn       = '[cChocoPackageInstaller]Keypirinha'
    }

    xRemoteFile 'filebrowser.ini'
    {
      DestinationPath = "$env:APPDATA\Keypirinha\User\filebrowser.ini"
      Uri             = 'https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/configfiles/Keypirinha/filebrowser.ini'
      MatchSource     = $True
      DependsOn       = '[cChocoPackageInstaller]Keypirinha'
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
 
    $Node.PowerShellModules.ForEach{
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
  }
}

$config = win10 -ConfigurationData $ConfigurationData -credential $cred -verbose

Start-DscConfiguration -Verbose -Path $config.PSParentPath -Wait -force