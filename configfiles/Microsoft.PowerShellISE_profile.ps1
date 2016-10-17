#If ISEonSteroids is installed, load it. 
if (get-Command 'Start-Steroids') {Start-Steroids}

#ConvertTo-IPwin function regex'es PowerShell code and transforms it into single line automata command.
Function ConvertTo-IPwin ($file) {
  if (!(test-path $file)) {
    Write-Warning "$file does not exist";
    break; 
  }
  $script = Get-Content $file -Raw

  #Remove Command blocks
  $script = $script -replace '\<#[\S\s]*?#\>'
  
  #Remove leading whitespace (only first line!)
  $script = $script -replace '^\s+'
  
  #Replace comments with new lines
  $script = $script -replace '\s*#.*\s*',"`n"

  #Remove any whitespace between '(' AND anything
  $script = [regex]::replace($script,'(\()(\s*)(\S)','$1$3')

  #Remove any whitespace between 'Anything' AND ')'
  $script = [regex]::replace($script,'(\S)(\s*)(\))','$1$3')

  #Remove any whitespace between '] or ,' AND '['
  $script = [regex]::replace($script,'(\]|,)(\s*)(\S)','$1$3')

  #Remove new lines + whitespace on the following line
  $script = $script -replace '\r{0,1}\n\s+',"`n"

  #Remove any whitespace between if/while AND '('
  $script = [regex]::replace($script,'(foreach|for|while|if)(\s*)(\()','$1 $3')

  #Remove any whitespace between " AND " '('
  $script = $script -replace '"\s*,\s*"','","'

  #Remove any whitespace between foreach-object (or similar commands) AND {'
  $script = [regex]::replace($script,'(\w+-object|do|where|select|\?|%)(\s*)({)','$1 $3')

  #Remove any whitespace (incl New Lines) AFTER '{'
  $script = $script -replace '\{\s*',"{"
  
  #Remove any whitespace (incl New Lines) BEFORE '}'  
  $script = $script -replace '\s*\}','}'

  #Remove any whitespace  (incl New Lines) BETWEEN ')' and '{' AND replace with a single space
  $script = $script -replace '\)\s*\{',') {'
  
  #Remove any whitespace (incl New Lines) IN '} else {'
  $script = $script -replace '\}\s*else\s*{','} else {'
  
  #Replace remaining newlines for ';'
  $script = $script -replace '\r{0,1}\n',';'

  #Replace excessive whitespace
  $script = $script -replace '\s+',' '

  $outfile = $file -replace '\.ps1','_IPwin.ps1'
  $script | Out-File $outfile

  ise $outfile
}

#Add keyboard shortcut for ConvertTo-IPwin. (Press CTRL+ALT+I)
Function Add-KeyBoardShortcut {
  $null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
    'ConvertIPwin', {
      if ($psISE.CurrentFile.IsUntitled) {
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog 
        $FileBrowser.Filter = 'Script files (*.ps1)|*.ps1'
        [void]$FileBrowser.ShowDialog()
        if ($FileBrowser.FileName) {
          $psISE.CurrentFile.SaveAs($FileBrowser.FileName)
        } else {
          break;
        }
      } elseif (!$psIse.CurrentFile.IsSaved) {
        $psIse.CurrentFile.save()
      }

      if ($psIse.CurrentFile.IsSaved) {
        ConvertTo-IPwin $PSIse.CurrentFile.FullPath 
      }
    }, 'CTRL+ALT+I'
  ) 
}
Add-KeyBoardShortcut