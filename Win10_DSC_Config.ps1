'cChoco','PackageManagementProviderResource','PowerShellModule','xTimeZone','xSystemSecurity','xHyper-V','cAppxPackage' | %{
  if (-not(get-dscresource -module $_)) {find-module -name $_ | install-module -SkipPublisherCheck -force}
}

if (-not($cred)) {
  $cred = get-credential
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                   ='Localhost'
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
      [string[]]$removeableapps
  )

  Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
  Import-DscResource -ModuleName 'cChoco'
  Import-DscResource -ModuleName 'PackageManagementProviderResource'
  Import-DscResource -ModuleName 'PowerShellModule'
  Import-DscResource -ModuleName 'xTimeZone'  
  Import-DscResource -ModuleName 'xSystemSecurity'  
  Import-DscResource -ModuleName 'xHyper-V'
  Import-DscResource -ModuleName 'cAppxPackage'  
 
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
      Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/Microsoft.PowerShell_profile.ps1 -usebasicparsing).content -replace '﻿',''
      Ensure          = 'Present'
      Force           = $true
      Type            = 'File'
    }

    File 'ISE_Profile'
    {
      DestinationPath = "$home\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"
      Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/Microsoft.PowerShellISE_profile.ps1 -usebasicparsing).content -replace '﻿',''
      Ensure          = 'Present'
      Force           = $true
      Type            = 'File'
    }

    File 'conemuconfig'
    {
      DestinationPath = "$env:APPDATA\ConEmu.xml"
      Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/ConEmu.xml -usebasicparsing).content -replace '﻿',''
      Ensure          = 'Present'
      Force           = $true
      Type            = 'File'
      DependsOn       = '[cChocoPackageInstaller]conemu'
    }

    File 'autohotkey'
    {
      DestinationPath = "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\hotstring.ahk"
      Contents        = (Invoke-WebRequest -Uri https://raw.githubusercontent.com/javydekoning/WIN10-DSC-Configuration/master/hotstring.ahk -usebasicparsing).content -replace '﻿',''
      Ensure          = 'Present'
      Force           = $true
      Type            = 'File'
      DependsOn       = '[cChocoPackageInstaller]autohotkey'
    }

    cChocoInstaller installChoco
    {
      InstallDir = 'c:\choco'
    }
       
    foreach ($p in $chocopackages) {
      cChocoPackageInstaller $p
      {
        Name                 = "$p"
        DependsOn            = '[cChocoInstaller]installChoco'
        PsDscRunAsCredential = $Credential
        chocoParams          = '--allowemptychecksum --allowemptychecksumsecure'
      }    
    }

    foreach ($m in $modules) {
      PSModuleResource $m
      {
        Ensure      = 'present'
        Module_Name = "$m"
      }
    }

    xTimeZone TimeZone
    {
      IsSingleInstance = 'Yes'
      TimeZone         = 'W. Europe Standard Time'
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
      NetAdapterName = 'Ethernet'
    } 
    
    cAppxPackage 'WindowsAlarms'
    {
      Name = 'Microsoft.WindowsAlarms'
      Ensure = 'Absent'
      PsDscRunAsCredential = $Credential
    }

    Registry 'DeveloperMode'
    {
        Ensure      = "Present"  # You can also set Ensure to "Absent"
        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        ValueName   = "AllowDevelopmentWithoutDevLicense"
        ValueData   = "1"
        ValueType   = "Dword"
        Force       = $true
    }
  }
}

$chocopackages = 'googlechrome','filezilla','vlc','sublimetext3','jre8','7zip','greenshot',
                 'keepass','conemu','mysql.workbench','googledrive','f.lux','pidgin',
                 'unchecky','rufus','classic-shell','autohotkey','mremoteng','evernote','classic-shell'

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

$config = win10 -ConfigurationData $ConfigurationData -credential $cred -ChocoPackages $chocopackages -features $features -removeableapps $removeableapps -modules $modules -verbose

Start-DscConfiguration -Verbose -Path $config.PSParentPath -Wait -Force