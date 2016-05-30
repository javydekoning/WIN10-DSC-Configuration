Configuration WebServer 
{
   Node "Localhost"
   {
      'Web-Server','Web-mgmt-tools' | %{
        WindowsFeature "$_"
        {
            Name = $_
            Ensure = 'Present'
        }      
      } 
   }
}
WebServer