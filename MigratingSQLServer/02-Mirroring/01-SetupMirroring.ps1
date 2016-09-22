Import-Module '\\van-nas01\Backups\Scripts\Powershell\Demo\PS_SQL_Functions.psm1'
set-location "c:"

$PrincipalInstance ='VAN-SQL2008v1\sql01' 
$SecondaryInstance = 'VAN-SQL2014v1\sql01'

$PrincipalEndpoint ='TCP://VAN-SQL2008v1.Iac.Net:5022' 
$MirrorEndpoint ='TCP://VAN-SQL2014v1.iac.net:5022'

#Script 
$Databases = Get-ChildItem "SQLServer:\SQL\$PrincipalInstance\Databases\" | where {$_.Name -ne 'DBMaint'}



Foreach ($database in $Databases)
{
    write-host "Restoring Database: $database" -BackgroundColor Red

    Restore-DatabaseBackup -SourceInstance  $PrincipalInstance  -SourceDatabase $database.Name -DestInstance $SecondaryInstance -DestDatabase $database.Name -NoRecovery

    $SQLMirror = "ALTER DATABASE $($Database.Name) SET PARTNER = N'$PrincipalEndpoint';"
    $SQLPrimary = "ALTER DATABASE  $($Database.Name) SET PARTNER = N'$MirrorEndpoint'; ALTER DATABASE $($Database.Name) Set Safety Off;"

    Invoke-Sqlcmd -ServerInstance $SecondaryInstance -Query $SQLMirror
    Invoke-Sqlcmd -ServerInstance $PrincipalInstance -Query $SQLPrimary

}