
$cfg = Get-Content .\deploy\config.json -errorAction stop | ConvertFrom-Json

$cred = Import-Clixml $cfg.credFile
$Session = New-PSSession -ComputerName $cfg.server -Credential $cred

Copy-Item $cfg.srcZip -Destination $cfg.destZip -ToSession $Session

Invoke-Command -ComputerName $cfg.server -ScriptBlock { Remove-Item -path $Using:cfg.destDir -recurse } -credential $cred

Invoke-Command -ComputerName $cfg.server -ScriptBlock { Expand-Archive $Using:cfg.destZip -DestinationPath $Using:cfg.destDir } -credential $cred