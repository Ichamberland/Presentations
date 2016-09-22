$SourceInstance =   'van-sql2008v3\sql03'
$DestinationInstance = 'van-sql2014v3\sql03'

$TailLogBackup = '\\Van-nas01\Backups\BACKUPS\DemoBackupRestore\tail'
$Databases = Get-ChildItem "SQLServer:\SQL\$SourceInstance\Databases\" | where {$_.Name -ne 'DBMaint'}

FOREACH ($DB IN $Databases)
{
    Backup-SqlDatabase  -ServerInstance $SourceInstance      -Database $DB.Name -BackupFile  "$($tailLogBackup)\$($DB.Name)Tail_$($DB.Name).trn" -NoRecovery -BackupAction Log -Initialize
    Restore-SqlDatabase -ServerInstance $DestinationInstance -Database $DB.Name -BackupFile  "$($tailLogBackup)\$($DB.Name)Tail_$($DB.Name).trn" -RestoreAction log
}

# Alternative: Continue using ola hallengren to backup the tail log
# Restore with Similar script to Script # 3 but with recovery instead. 