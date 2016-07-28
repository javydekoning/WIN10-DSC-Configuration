#https://github.com/PowerShell/xHyper-V/blob/dev/DSCResources/MSFT_xVMSwitch/MSFT_xVMSwitch.psm1
#https://msdn.microsoft.com/en-us/powershell/dsc/authoringresourcemof
function Get-TargetResource 
{
    param 
    (       
      [ValidateSet("Present", "Absent")]
      [string]$Ensure = "Present",

      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Name
    )

    $getResult = $null;

    if (Get-AppxPackage -name $Name) {
      $ensureResult = 'Present'
    } else {
      $ensureResult = 'Absent'    
    }

    $getResult = @{
                    Name = $Name; 
                    Ensure = $ensureResult;
                  }

    return $getResult;
}

function Set-TargetResource 
{
    param 
    (       
      [ValidateSet("Present", "Absent")]
      [string]$Ensure = "Present",

      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Name
    )

    $getResult = $null;

    if (Get-AppxPackage -name $Name) {
      $ensureResult = 'Present'
    } else {
      $ensureResult = 'Absent'    
    }

    $getResult = @{
                    Name = $Name; 
                    Ensure = $ensureResult;
                  }

    return $getResult;
}