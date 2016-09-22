--Get Log Backups that have occured on the source
--via the linked server created
With LogBackups as (
SELECT bu.database_name
      ,ms.physical_device_name
	  ,bu.backup_start_date
FROM Source.msdb.dbo.backupset bu
JOIN Source.msdb.dbo.backupmediafamily ms
  ON bu.media_set_id = ms.media_set_id
WHERE bu.type = 'L'
),

--Get the log restores that have occured locally
LogRestores as (
select bu.database_Name, ms.physical_device_name
from msdb.dbo.restorehistory rs
join msdb.dbo.backupset bu
  on rs.backup_set_id =bu.backup_set_id
join msdb.dbo.backupmediafamily ms
  on ms.media_set_id = bu.media_set_id
where bu.type = 'L'
)
--Join the backups and restores. Find backups that have not been restored. 		
select b.* 
from LogBackups b
LEft join LogRestores r 
  on r.physical_device_name = b.physical_device_name 
 where r.physical_device_name is null
   and b.database_name <> 'DBMAINT'


