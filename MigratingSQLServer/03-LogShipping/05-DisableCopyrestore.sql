DECLARE DBCurse CURSOR FOR

select 'EXEC msdb.dbo.sp_update_job @Job_Name = N''' +  name + ''', @Enabled=0;'
from msdb.dbo.sysjobs
where name like 'LSCOPY%'
   OR name like 'LSRESTORE%'

OPEN Dbcurse

Declare @sql VARCHAR(256) 

FETCH NEXT From DBCurse INTO @SQL

WHILE @@FETCH_STATUS =0 
BEGIN

	EXEC (@sql)

	FETCH NEXT From DBCurse INTO @SQL
END
CLOSE DBCurse

DEALLOCATE DBCURSE
