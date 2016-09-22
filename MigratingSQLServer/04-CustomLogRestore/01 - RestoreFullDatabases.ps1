Import-Module '\\van-nas01\Backups\Scripts\Powershell\Demo\PS_SQL_Functions.psm1'
set-location "c:"

$SourceInstance      = 'VAN-SQL2008v3\sql03' 
$DestinationInstance = 'VAN-SQL2014v3\sql03'

#Script 
$Databases = Get-ChildItem "SQLServer:\SQL\$SourceInstance\Databases\" | where {$_.Name -ne 'DBMaint'}



Foreach ($database in $Databases)
{
    write-host "Restoring Database: $database" -BackgroundColor Red

    Restore-DatabaseBackup -SourceInstance  $SourceInstance  -SourceDatabase $database.Name -DestInstance $DestinationInstance -DestDatabase $database.Name -NoRecovery
}