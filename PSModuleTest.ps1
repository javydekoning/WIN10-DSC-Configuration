configuration moduletest
{
  Import-DscResource -ModuleName 'powershellmodule'
  
  $modules = "PSScriptAnalyzer","Pester","PSReadline","PowerShellISE-preview","ISESteroids"
  node ('Localhost')
  {
    PSModuleResource ISESteroids
    {
      Ensure = "present"
      Module_Name = "ISESteroids"
    }
  }
}
moduletest



  