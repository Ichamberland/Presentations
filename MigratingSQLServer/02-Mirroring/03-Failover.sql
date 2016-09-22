/****************************************************
* This script will perform the mirroring failover.
****************************************************/

DECLARE  DBCurs  CURSOR
FOR 
select 'ALTER DATABASE ' + quotename(db_name(database_id)) + ' Set PARTNER FAILOVER; ALTER DATABASE ' + quotename(db_name(database_id)) + ' Set PARTNER OFF; '
FROM sys.database_mirroring
where mirroring_role = 1

OPEN DBCurs

DECLARE @DB VARCHAR(256)

FETCH NEXT FROM DBCurs
INTO @DB

WHILE @@FETCH_STATUS = 0
BEGIN

	Exec (@DB)

	FETCH NEXT FROM DBCurs
	INTO @DB

END

DEALLOCATE DBCurs
