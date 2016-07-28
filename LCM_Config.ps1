[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $true
            AllowModuleOverwrite = $true
            ActionAfterReboot = 'ContinueConfiguration' 
            ConfigurationMode = 'ApplyandAutoCorrect'
            ConfigurationModeFrequencyMins = '15'
        }
    }
}
LCMConfig