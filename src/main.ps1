$configName = 'config.json'
# $configName = 'config-test.json'
$cfg = $null
$dt = Get-Date

function SendEmail {
	param( [string]$EmailTo, [string]$EmailBody, [string]$EmailSubject )
	$Message = New-Object Net.Mail.MailMessage($cfg.email.from, $EmailTo, $EmailSubject, $EmailBody)
	$Message.IsBodyHtml = $true
	$SMTPClient = New-Object Net.Mail.SmtpClient($cfg.email.client, $cfg.email.port)
	$SMTPClient.EnableSsl = $true
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cfg.email.user, $cfg.email.pass);
	$SMTPClient.Send($Message)
}

function CreateAndSendPhotos {

	$conditions = { $_.extension -in $cfg.extensions -and $_.CreationTime.Month -eq $dt.Month -and $_.CreationTime.Day -eq $dt.Day }

	foreach ($person in $cfg.persons) {	

		$newFolder = "$($dt.Month)-$($dt.Day)"

		New-Item -Path "$($cfg.outputPathRoot)\$($person.name)" -Name $newFolder -ItemType "directory" -Force -errorAction stop
		
		$filesToSend = (Get-ChildItem -Path $person.srcPath -Recurse -File | where-object $conditions).FullName

		foreach ($file in $filesToSend) {					
			Copy-Item $file -Destination "$($cfg.outputPathRoot)\$($person.name)\$newFolder" -errorAction stop	
		}	

		if ($filesToSend.Count -gt 0) {
			SendEmail $person.email "<a href='$($person.link)'>$($filesToSend.Count) Photos of the day</a>" $cfg.email.subject
		} 
		else {
			Write-Host "no photos for $($person.name) today :("
		}	

	}

}

try { 

	$cfg = Get-Content $configName -errorAction stop | ConvertFrom-Json
	CreateAndSendPhotos

} 
catch {
	Write-Host "ERROR MSG:`n $_.ScriptStackTrace"
	
	if ($cfg) { SendEmail $cfg.email.admin "ERROR MSG:`n $_.ScriptStackTrace" "$($cfg.email.subject) ERROR" }
	
	exit 1
	
}
