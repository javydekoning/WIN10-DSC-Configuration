configuration Win10
{
  #Load resources
  Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
  Import-DscResource -ModuleName 'cChoco'
  Import-DscResource -ModuleName 'PackageManagementProviderResource'
  Import-DscResource -ModuleName 'PowerShellModule'
  
  #for hkcu changes
  $usersid       = (whoami /user)[-1] -replace '.*(s-\d-\d-\d{2}.*)','$1' 

  #some choco packages might not install because DSC runs in system context by default
  $chocopackages = 'googlechrome',
                    'filezilla',
                    'vlc',
                    'sublimetext3',
                    'jre8',
                    '7zip',
                    'greenshot',
                    'keepass',
                    'conemu',
                    'mysql.workbench',
                    'googledrive',
                    'f.lux',
                    'pidgin',
                    'rdcman',
                    'unchecky',
                    'rufus'

  $features       = 'Microsoft-Windows-Subsystem-Linux',
                    'Microsoft-Hyper-V',
                    'Microsoft-Hyper-V-All',
                    'Microsoft-Hyper-V-Common-Drivers-Package',
                    'Microsoft-Hyper-V-Guest-Integration-Drivers-Package',
                    'Microsoft-Hyper-V-Hypervisor',
                    'Microsoft-Hyper-V-Management-Clients',
                    'Microsoft-Hyper-V-Management-PowerShell',
                    'Microsoft-Hyper-V-Services',
                    'Microsoft-Hyper-V-Tools-All',
                    'NetFx3',
                    'NetFx4-AdvSrvs' 		

  $modules       = 'PSScriptAnalyzer',
                   'Pester',
                   'PSReadline',
                   'PowerShellISE-preview',
                   'ISESteroids'
  
  node ('Localhost')
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
        PsDscRunAsCredential = $cred
      }    
    }

    foreach ($m in $modules) {
      PSModuleResource $m
      {
        Ensure = 'present'
        Module_Name = "$m"
      }
    }
  }
}
win10