find-module 'cChoco','PackageManagementProviderResource','PowerShellModule','xTimeZone','xSystemSecurity','xHyper-V','cAppxPackage' | install-module -force

$cred = get-credential

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName='Localhost'
            PSDscAllowPlainTextPassword=$true
         }
    )
}

configuration Win10
{
  param (
      [Parameter(Mandatory=$false)]
      [PSCredential]$Credential,

      [Parameter(Mandatory=$true)]
      [string[]]$ChocoPackages,     

      [Parameter(Mandatory=$true)]
      [string[]]$features,  

      [Parameter(Mandatory=$true)]
      [string[]]$modules,
      
      [Parameter(Mandatory=$true)]
      [string[]]$removeableapps,

      [Parameter(Mandatory=$true)]
      [string]$SystemTimeZone
  )
  
  
  
  Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
  Import-DscResource -ModuleName 'cChoco'
  Import-DscResource -ModuleName 'PackageManagementProviderResource'
  Import-DscResource -ModuleName 'PowerShellModule'
  Import-DscResource -ModuleName 'xTimeZone'  
  Import-DscResource -ModuleName 'xSystemSecurity'  
  Import-DscResource -ModuleName 'xHyper-V'
  Import-DscResource -ModuleName 'cAppxPackage'  

  #for hkcu changes
  $usersid       = (whoami /user)[-1] -replace '.*(s-\d-\d-\d{2}.*)','$1' 
 
  Node $AllNodes.NodeName
  {
    $features | % {
      WindowsOptionalFeature "$_"
      {
        Name = $_
        Ensure = 'Enable'
      }
    }

    File 'Profile'
    {
      DestinationPath = "$home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
      Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/PowershellTools/master/Microsoft.PowerShell_profile.ps1 -usebasicparsing).content -replace '﻿',''
      Ensure          = 'Present'
      Force           = $true
      Type            = 'File'
    }

    File 'ISE_Profile'
    {
      DestinationPath = "$home\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"
      Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/PowershellTools/master/Microsoft.PowerShellISE_profile.ps1 -usebasicparsing).content -replace '﻿',''
      Ensure          = 'Present'
      Force           = $true
      Type            = 'File'
    }

    cChocoInstaller installChoco
    {
      InstallDir = 'c:\choco'
    }
       
    foreach ($p in $chocopackages) {
      cChocoPackageInstaller $p
      {
        Name = "$p"
        DependsOn = '[cChocoInstaller]installChoco'
        PsDscRunAsCredential = $Credential
      }    
    }

    foreach ($m in $modules) {
      PSModuleResource $m
      {
        Ensure = 'present'
        Module_Name = "$m"
      }
    }

    xTimeZone TimeZoneExample
    {
      IsSingleInstance = 'Yes'
      TimeZone         = $SystemTimeZone
    }
    
    xUac UAC 
    {
        Setting = 'NotifyChangesWithoutDimming'
    }
    
    xVMSwitch defaultSwitch
    {
      Name = 'defaultSwitch'
      Type = 'External'
      Ensure = 'present'
      DependsOn = '[WindowsOptionalFeature]Microsoft-Hyper-V-Management-PowerShell'
    } 
    
    cAppxPackage 'WindowsAlarms'
    {
      Name = 'Microsoft.WindowsAlarms'
      Ensure = 'Absent'
      PsDscRunAsCredential = $Credential
    }
  }
}

$SystemTimeZone= 'W. Europe Standard Time'

$chocopackages = 'googlechrome','filezilla','vlc','sublimetext3','jre8','7zip','greenshot',
                 'keepass','conemu','mysql.workbench','googledrive','f.lux','pidgin',
                 'rdcman','unchecky','rufus','atom'

$features      = 'Microsoft-Windows-Subsystem-Linux','Microsoft-Hyper-V','Microsoft-Hyper-V-All',
                 'Microsoft-Hyper-V-Common-Drivers-Package',
                 'Microsoft-Hyper-V-Guest-Integration-Drivers-Package',
                 'Microsoft-Hyper-V-Hypervisor','Microsoft-Hyper-V-Management-Clients',
                 'Microsoft-Hyper-V-Management-PowerShell','Microsoft-Hyper-V-Services',
                 'Microsoft-Hyper-V-Tools-All','NetFx3','NetFx4-AdvSrvs'

$removeableapps= 'Microsoft.3DBuilder','Microsoft.BingFinance','Microsoft.BingNews',
                 'Microsoft.BingSports','Microsoft.BingWeather','Microsoft.MicrosoftOfficeHub',
                 'Microsoft.MicrosoftSolitaireCollection','Microsoft.Office.OneNote',
                 'Microsoft.People','Microsoft.SkypeApp','Microsoft.Appconnector',
                 'Microsoft.Getstarted','Microsoft.Windows.ParentalControls',
                 'Microsoft.Windows.ShellExperienceHost','microsoft.windowscommunicationsapps',
                 'Microsoft.WindowsMaps','Microsoft.WindowsPhone','Microsoft.XboxApp',
                 'Microsoft.XboxIdentityProvider','Microsoft.ZuneMusic','Microsoft.ZuneVideo'

$modules       = 'PSScriptAnalyzer','Pester','PSReadline','PowerShellISE-preview','ISESteroids'

$config = win10 -ConfigurationData $ConfigurationData -credential $cred -ChocoPackages $chocopackages -features $features -removeableapps $removeableapps -modules $modules -SystemTimeZone 'W. Europe Standard Time'

Start-DscConfiguration -Verbose -Path $config.PSParentPath -Wait -Force