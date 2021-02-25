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
# this sleep is for mssql container to finish health checks
Start-Sleep -s 30

Write-Host "Running LRE Configuration Wizard" -ForegroundColor  Blue
docker exec -d -w c:\PC_Server\bin lre powershell {HP.Software.HPX.ConfigurationWizard.exe /CFG:..\dat\setup\PCS\Xml\Configurator.xml /G:Install /U:..\dat\setup\PCS\Xml\UserInput.xml /Silent} | Out-GridView
checkError
docker exec lre powershell {wait-process -name HP.Software.HPX.ConfigurationWizard} | Out-GridView
checkError

Write-Host "Configuring LRE IIS" -ForegroundColor  Blue
docker exec lre powershell {C:\windows\system32\inetsrv\appcmd.exe set config "Default Web Site" /section:urlCompression /doDynamicCompression:False}
checkError
docker exec lre powershell {C:\windows\system32\inetsrv\appcmd.exe set config "Default Web Site" /section:urlCompression /doStaticCompression:False}
checkError
docker exec lre powershell iisreset
checkError

Write-Host "LoadRunner Enterprise up." -ForegroundColor  Green