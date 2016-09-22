Import-Module SQLPS  | out-null

$ErrorActionPreference = "Stop" 

function Get-Backups
{
    PARAM([string]$Instance,
          [string]$Database, 
          [string]$BackupType,
          [DATETIME]$StartTime,
          [DECIMAL]$LSN)

    IF ($BackupType -eq "FULL")
    {
        $SQLCMD = "EXEC dbo.GetFullBackup @databaseName = '$Database'"
    } 
    ELSEif ($BackupType -eq "DIFF")
    {        
        $SQLCMD = ""
    }
    ELSEIF ($BackupType -eq "LOG")
    { 
         $SQLCMD = "Exec dbo.GetLogBackup @DatabaseName = '$Database', @LSN = $LSN"

    }
    ELSE 
    {
        Write-error "ERROR IN FUNCTION GETBACKUPs: Only LSN OR StartDate can be defined, not both"
    }
     
    if ($BackupType -eq 'LOG')
    {
        Return (Invoke-Sqlcmd -ServerInstance $Instance -Query $SQLCMD -Database "DBMaint" | sort-object backup_start_Date )
    }
    ELSE 
    {
        Return (Invoke-Sqlcmd -ServerInstance $Instance -Query $SQLCMD -Database "DBMaint"  )
    }
}

Function Get-DefaultPaths($Instance)
{
    if ($Instance -match '\\')
    {
        Get-Item "SQLSERVER:\SQL\$Instance"         | SELECT DefaultFile, DefaultLog
    } ELSE {
        Get-Item "SQLSERVER:\SQL\$Instance\Default" | SELECT DefaultFile, DefaultLog
    }

}

Function Relocate-DB-Files 
{
    PARAM ($BackupFile, 
           $DestInstance )
    
    $Paths = Get-DefaultPaths $DestInstance
    $rs = new-object('Microsoft.SqlServer.Management.Smo.Restore')
   
    $Backup = new-object ('Microsoft.SqlServer.Management.Smo.BackupDeviceItem') ($BackupFile, 'File')
    
    $rs.Devices.Add($Backup)
        
    
    $files = $rs.ReadFileList($DestInstance)
    
    $rfl = @()
   
    foreach ($file in $files) 
    {

        $NewFile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')
        $NewFile.LogicalFileName = $file.LogicalName
        
        $fileParts = $file.PhysicalName.Split('\')
        
        if ($file.Type -eq 'D') {
            $NewFile.PhysicalFileName = $Paths.DefaultFile + $fileParts[$fileParts.Length - 1]
            }
        else {
            $NewFile.PhysicalFileName = $Paths.DefaultLog + $fileParts[$fileParts.Length - 1]
            }
        $rfl += $NewFile
    }

    Return $rfl
}

Function Restore-DatabaseBackup
{
    PARAM ( [String]$SourceInstance
           ,[String]$SourceDatabase
           ,[String]$DestInstance
           ,[String]$DestDatabase
           ,[Switch]$NoRecovery
           
           ,[DateTime]$StopAt )



    $FullBackup = Get-Backups -Instance $SourceInstance -Database $SourceDatabase -BackupType "Full"   
    

    $FileList = Relocate-DB-Files -BackupFile $FullBackup[2] -DestInstance $DestInstance
    
    IF ((Get-ChildItem "SQLSERVER:\SQL\$DestInstance\Databases\" | WHERE {$_.Name -eq $DestDatabase}) -ne $Null)
    {
        (Get-item "SQLSERVER:\SQL\$DestInstance\Databases\$DestDatabase").Refresh()  
        IF ( (Get-item "SQLSERVER:\SQL\$DestInstance\Databases\$DestDatabase").Status -eq "Normal")
        {
            Write-host "Database Online: Setting Offline"
            (Get-item "SQLSERVER:\SQL\$DestInstance").KillAllProcesses($DestDatabase)
            (Get-item "SQLSERVER:\SQL\$DestInstance\Databases\$DestDatabase").SetOffline()
        }
    }
    Write-host "Restoring Full"
    Write-host "****Restoring File: $($FullBackup[2])"
    Restore-SqlDatabase -BackupFile $FullBackup[2] -Database $DestDatabase -ServerInstance $DestInstance -RestoreAction Database -ReplaceDatabase -NoRecovery  -RelocateFile $filelist 

    $LastLSN = $FullBackup[6]
    $LogBackups =  @()
    $LogBackups = Get-Backups -Instance $SourceInstance -Database $SourceDatabase -BackupType "LOG" -LSN $LastLSN

    Write-host "Restoring Logs"  

    While ($LogBackups -ne $Null)
    {
        FOREACH ($LOG in $LogBackups)
        {
            $FileList = Relocate-DB-Files -BackupFile $LOG[2].ToString() -DestInstance $DestInstance
            Write-host "****Restoring Log: $($Log[2].ToString())"
            Restore-SqlDatabase -BackupFile $Log[2] -Database $DestDatabase -ServerInstance $DestInstance -RestoreAction Log  -NoRecovery  -RelocateFile $filelist
        }

        $LastLSN = $Logbackups[6]
        $Logbackups[$Logbackups.count - 1]
        $LogBackups = Get-Backups -Instance $SourceInstance -Database $SourceDatabase -BackupType "LOG" -LSN $LastLSN
    }

    if (-not $NoRecovery.IsPresent)
    {
         #Restore-SqlDatabase -Database $DestDatabase -ServerInstance $DestInstance -RestoreAction Log  -BackupFile $Log[2]
         INVOKE-SQLCMD -ServerInstance $DestInstance -query "Restore Database [$DestDatabase] with Recovery;"
    }
    
}

#$DB = @('Tfs_Configuration','Tfs_DefaultCollection','TFS_Warehouse','TfsActivityLogging')
#
#$SecondaryInstance = 'FPTTOOLSPRD\TOOLSPRD'
#$PrincipalInstance ='fptbch8sqlp1v4\pwxtfs' 
#$PrincipalEndpoint ='TCP://fptbch8sqlp1v4.bchydro.adroot.bchydro.bc.ca:5022' 
#$MirrorEndpoint ='TCP://fpttoolsprd.bchydro.bc.ca:5022'
#
#Foreach ($database in $DB)
#{
#    write-host "Restoring Database: $database" -BackgroundColor Red
#    write-host ""
#
#    Restore-DatabaseBackup -SourceInstance  $PrincipalInstance  -SourceDatabase $database -DestInstance $SecondaryInstance -DestDatabase $database -NoRecovery
#
#    $SQLMirror = "ALTER DATABASE $Database SET PARTNER = N'$PrincipalEndpoint';"
#    $SQLPrimary = "ALTER DATABASE $Database SET PARTNER = N'$MirrorEndpoint'; ALTER DATABASE $Database Set Safety Off;"
#
#    Invoke-Sqlcmd -ServerInstance $SecondaryInstance -Query $SQLMirror
#    Invoke-Sqlcmd -ServerInstance $PrincipalInstance -Query $SQLPrimary
#
#}


FUNCTION FIX-AG
{
    PARAM (    
             [Parameter(Mandatory=$true)]
             [STRING]$Instance 
          )   

    $AGGroup =  get-childitem "SQLSERVER:\SQL\$Instance\availabilityGroups\"
    $PrimaryInstance = $AGGroup.PrimaryReplicaServerName

    FOREACH ($DB in ($AGGroup.AvailabilityDatabases ))
    {
        $db.Refresh()

        if ($db.IsJoined -eq $False)
        {
            WRITE-HOST "Restoring Database: $($DB.name)"
            Restore-DatabaseBackup -SourceInstance  $PrimaryInstance  -SourceDatabase $DB.name -DestInstance $Instance -DestDatabase $DB.name -NoRecovery
        
            write-host "Adding $($db.Name) to Availability Group $($AGGroup.Name)"
            Add-SQLAvailabilityDatabase -InputObject $AGGroup -Database $DB.name

        }
    }
}

Set-Location c:\