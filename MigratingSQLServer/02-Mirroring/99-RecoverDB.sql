DECLARE  DBCurs  CURSOR
FOR 
select 'RESTORE DATABASE ' + quotename(db_name(database_id)) + 'With REcovery; '
FROM sys.databases
where state=1

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


