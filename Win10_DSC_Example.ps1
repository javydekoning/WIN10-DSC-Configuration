configuration Win10
{
  Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
  Import-DscResource -ModuleName 'cChoco'
  Import-DscResource -ModuleName 'PackageManagementProviderResource'
  
  $cred = Import-Clixml C:\Users\jdekoning\pscredobj.cred
  
  node ('Localhost')
  {
    $features = 'Microsoft-Windows-Subsystem-Linux',
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
    $features | % {
      WindowsOptionalFeature "$_"
      {
        Name = $_
        Ensure = 'Enable'
      }
    }

    User 'jdekoning'
    {
        UserName                 = 'jdekoning'
        Disabled                 = $false
        Ensure                   = 'Present'
        FullName                 = 'Javy de Koning'
        PasswordChangeNotAllowed = $false
        PasswordChangeRequired   = $false
        PasswordNeverExpires     = $true
    }

    File 'Profile'
    {
        DestinationPath = 'C:\Users\jdekoning\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
        Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/PowershellTools/master/Microsoft.PowerShell_profile.ps1).content -replace '﻿',''
        DependsOn       = '[user]jdekoning'
        Ensure          = 'Present'
        Force           = $true
        Type            = 'File'
    }

    File 'ISE_Profile'
    {
        DestinationPath = 'C:\Users\jdekoning\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1'
        Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/PowershellTools/master/Microsoft.PowerShellISE_profile.ps1).content -replace '﻿',''
        DependsOn       = '[user]jdekoning'
        Ensure          = 'Present'
        Force           = $true
        Type            = 'File'
    }

    cChocoInstaller installChoco
    {
      InstallDir = 'c:\choco'
    }
    
    $chocopackages = 'googlechrome','filezilla','vlc','sublimetext3','jre8','7zip','atom','keepass','conemu','mysql.workbench','googledrive','f.lux','pidgin','rdcman','unchecky','rufus','vmwarevsphereclient'
    foreach ($p in $chocopackages) {
      cChocoPackageInstaller $p
      {
        Name = "$p"
        DependsOn = '[cChocoInstaller]installChoco'
      }    
    }
  }
}
win10