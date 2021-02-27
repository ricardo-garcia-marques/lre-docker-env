function checkError{
	if( -not $? )
	{
		write-host "Script stopped. Something has failed." -ForegroundColor  Red
		exit
	}
}

Write-Host "Downloading docker images" -ForegroundColor  Blue
docker-compose pull
checkError


Write-Host "Starting docker images" -ForegroundColor  Blue
docker-compose up -d
checkError


Write-Host "Waitting for mssql health checks" -ForegroundColor  Blue
Start-Sleep -s 30


Write-Host "Configuring LRE Server" -ForegroundColor  Blue
docker exec  lreserver powershell {(Get-Content -Path C:\PC_Server\dat\PCS.config) | ForEach-Object {$_ -replace "http://\w{12}", "http://lreserver"} | Set-Content -Path C:\PC_Server\dat\PCS.config} | Out-GridView
docker exec  lreserver powershell {(Get-Content -Path C:\PC_Server\dat\PCS.config) | ForEach-Object {$_ -replace "http://localhost", "http://lreserver"} | Set-Content -Path C:\PC_Server\dat\PCS.config} | Out-GridView
docker exec lreserver powershell {(Get-Content -Path c:\PC_Server\dat\setup\PCS\Xml\UserInput.xml) | ForEach-Object {$_ -replace "<DbPassword>.*</DbPassword>", "<DbPassword>W3lcome1</DbPassword>"} | Set-Content -Path C:\PC_Server\dat\setup\PCS\Xml\UserInput.xml} | Out-GridView
docker exec lreserver powershell {(Get-Content -Path c:\PC_Server\dat\setup\PCS\Xml\UserInput.xml) | ForEach-Object {$_ -replace "<DbAdminPassword>.*</DbAdminPassword>", "<DbAdminPassword>W3lcome1</DbAdminPassword>"} | Set-Content -Path C:\PC_Server\dat\setup\PCS\Xml\UserInput.xml} | Out-GridView
docker exec lreserver powershell {(Get-Content -Path c:\PC_Server\dat\setup\PCS\Xml\UserInput.xml) | ForEach-Object {$_ -replace "<AdminPassword>.*</AdminPassword>", "<AdminPassword>saqa</AdminPassword>"} | Set-Content -Path C:\PC_Server\dat\setup\PCS\Xml\UserInput.xml} | Out-GridView


Write-Host "Configuring mssql" -ForegroundColor  Blue
## Config database
docker exec mssql powershell {Invoke-Sqlcmd -Query "ALTER LOGIN lre WITH PASSWORD = 'W3lcome1'"} | Out-GridView
docker exec mssql powershell {Invoke-Sqlcmd -Query "ALTER LOGIN lre_db_admin WITH PASSWORD = 'W3lcome1'"}  | Out-GridView


Write-Host "Running LRE Server configuration wizard" -ForegroundColor  Blue
docker exec -d -w c:\PC_Server\bin lreserver powershell {HP.Software.HPX.ConfigurationWizard.exe /CFG:..\dat\setup\PCS\Xml\Configurator.xml /G:Install /U:..\dat\setup\PCS\Xml\UserInput.xml /Silent} | Out-GridView
checkError
docker exec lreserver powershell {wait-process -name HP.Software.HPX.ConfigurationWizard} | Out-GridView
checkError


Write-Host "Configuring LRE IIS" -ForegroundColor  Blue
docker exec lreserver powershell {C:\windows\system32\inetsrv\appcmd.exe set config "Default Web Site" /section:urlCompression /doDynamicCompression:False}
checkError
docker exec lreserver powershell {C:\windows\system32\inetsrv\appcmd.exe set config "Default Web Site" /section:urlCompression /doStaticCompression:False}
checkError
docker exec lreserver powershell iisreset
checkError


Write-Host "LoadRunner Enterprise up." -ForegroundColor  Green