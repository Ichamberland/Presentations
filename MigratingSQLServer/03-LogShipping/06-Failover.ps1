$PrimaryInstance =   'van-sql2008v2\sql02'
$SecondaryInstance = 'van-sql2014v2\sql02'
$SQL = 'select primary_database from [dbo].[log_shipping_primary_databases];'
$TailLogBackup = '\\Van-nas01\Backups\BACKUPS\LogShip\tail\'
$Databases = Invoke-Sqlcmd -query $SQL -ServerInstance $PrimaryInstance -Database 'MSDB'

FOREACH ($DB IN $Databases)
{
    Backup-SqlDatabase -ServerInstance $PrimaryInstance    -Database $DB[0] -BackupFile  "$($tailLogBackup)\$($DB[0])Tail_$($DB[0]).trn" -NoRecovery -BackupAction Log -Initialize
    Restore-SqlDatabase -ServerInstance $SecondaryInstance -Database $DB[0] -BackupFile  "$($tailLogBackup)\$($DB[0])Tail_$($DB[0]).trn" -RestoreAction log
}

