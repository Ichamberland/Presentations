import-module sqlps
Clear-Host

$PrimaryInstance    = 'van-sql2008v2\sql02'
$SecondaryInstance  = 'van-sql2014v2\sql02'
$PrimaryBackup = '\\van-nas01\Backups\BACKUPS\LogShip\SQL02\'
$SecondaryBackup = '\\van-nas01\Backups\BACKUPS\LogShip\SQL02\'
$Databases = Get-ChildItem "SQLServer:\SQL\$PrimaryInstance\Databases\" | where {$_.Name -ne 'DBMaint'}
$BackupDir = '\\Van-nas01\Backups\BACKUPS\LogShip\'

ForEach ($Database in $Databases)
{
    $SQL1 = "EXEC master.dbo.sp_delete_log_shipping_primary_secondary
                    @primary_database = N'$($Database.Name)'
                   ,@secondary_server = N'$SecondaryInstance'
                   ,@secondary_database = N'$($Database.Name)'"
    $SQL2 = "exec master.dbo.sp_delete_log_shipping_secondary_database @secondary_database = '$($Database.Name)'; 
             exec master.dbo.sp_delete_log_shipping_secondary_primary @primary_server ='$PrimaryInstance' , @primary_database = '$($Database.Name)'"
    $SQL3 = "exec master.dbo.sp_delete_log_shipping_primary_database @database = '$($Database.Name)'"
    Invoke-Sqlcmd -Query $sql1 -ServerInstance $PrimaryInstance
    Invoke-Sqlcmd -query $SQL2 -ServerInstance $SecondaryInstance
    Invoke-Sqlcmd -Query $sql3 -ServerInstance $PrimaryInstance
}

set-location $BackupDir

Get-ChildItem "*.TRN" -Recurse | Remove-Item


