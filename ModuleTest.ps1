configuration ModuleTest
{
  Import-DscResource -ModuleName 'cChoco'
  
  node ('Localhost')
  {   
    cChocoInstaller choco
    {
      InstallDir = 'c:\testchoco\dsc\choco'
    }
  }
}
ModuleTest