configuration moduletest
{
  Import-DscResource -ModuleName 'powershellmodule'
 
  node ('Localhost')
  {
    PSModuleResource xActiveDirectory
    {
      Ensure = "present"
      Module_Name = "xActiveDirectory"
    }
  }
}
moduletest