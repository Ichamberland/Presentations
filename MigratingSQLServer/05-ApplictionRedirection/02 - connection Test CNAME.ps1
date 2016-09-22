while (1 -eq 1) 
{
    Invoke-Sqlcmd -database 'ANT' -ServerInstance 'DemoCNAME' -Query 'SELECT @@Servername'
    Start-Sleep -Seconds 5Invoke-Sqlcmd -database 'ANT' -ServerInstance 'DemoCNAME' -Query 'SELECT @@Servername'
clear
}

