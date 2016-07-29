#https://github.com/PowerShell/xHyper-V/blob/dev/DSCResources/MSFT_xVMSwitch/MSFT_xVMSwitch.psm1
#https://msdn.microsoft.com/en-us/powershell/dsc/authoringresourcemof
#https://msdn.microsoft.com/en-us/powershell/dsc/authoringresourceclass
enum Ensure
{
    Absent
    Present
}

[DscResource()]
class AppxResource
{
    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Mandatory=$false)]
    [string]$InstallLocation = $null
   
    [void] Set()
    {
        Write-Verbose "Set AppxPackage $($this.name) to $($this.ensure) as $env:username"  

        if ($this.TestSystemPriv()) {
          throw {'Running in System Context is not supported for Adding/Removing builtin AppxPackages'}
        }
        
        $appxInstalled = $this.TestAppxPresent($this.Name)
        if ($this.ensure -eq [Ensure]::Present)
        {
            if (-not $appxInstalled)
            {
                Write-Verbose -Message "Installing AppxPackage $($this.name)"
                if ($this.InstallLocation) {
                  Add-AppxPackage -register "$($this.InstallLocation)\appxmanifest.xml" -DisableDevelopmentMode
                } else {
                  Get-AppxPackage -Name $this.name -AllUsers | foreach {Add-AppxPackage -register "$($_.InstallLocation)\appxmanifest.xml" -DisableDevelopmentMode}
                }
            } else {
                Write-Verbose -Message "AppxPackage $($this.name) is installed, nothing to set"
            }
        }
        else
        {
            if ($appxInstalled)
            {
                Write-Verbose -Message "Removing AppxPackage $($this.name)"
                Get-AppxPackage -Name $this.name | Remove-AppxPackage
            } else {
                Write-Verbose -Message "AppxPackage $($this.name) is NOT installed, nothing to set"
            }
        }
    }

    [bool] Test()
    {
        Write-Verbose -Message "Testing if AppxPackage $($this.name) is installed as $env:username"
        $present = $this.TestAppxPresent($this.Name)

        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [AppxResource] Get()
    {
        Write-Verbose "Get current config for AppxPackage $($this.name) as $env:username"    
        $present = $this.TestAppxPresent($this.Name)
        
        if ($present)
        {
            $Package = Get-AppXPackage -Name $this.Name
            $this.Ensure = [Ensure]::Present
            $this.InstallLocation = $Package.InstallLocation
        }
        else
        {
            $this.InstallLocation = $null
            $this.Ensure = [Ensure]::Absent
        }

        return $this
    }

    [bool] TestAppxPresent([string]$name)
    {
        $present = $true

        $item = Get-AppxPackage -name $name -ErrorAction Ignore
        if ($item -eq $null)
        {
            $present = $false
        }

        return $present
    }
    
    [bool] TestSystemPriv()
    {
        $system = $false
        if ($env:COMPUTERNAME -match $env:USERNAME) {
          $system = $true
        }
        return $system
    }
}