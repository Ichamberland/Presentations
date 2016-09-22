/****************************************************
* This script will set all mirrored databases
* on primary instance to be full safety mode. 
* This ensures before cutover that the database 
* is in sync before cutover. 
****************************************************/

DECLARE  DBCurs  CURSOR
FOR 
select 'ALTER DATABASE ' + quotename(db_name(database_id)) + ' Set Safety FULL;'
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

