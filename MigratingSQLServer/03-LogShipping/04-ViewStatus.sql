use msdb
go

--Execute on Secondary
--Script uses linked server to compare primary with secondary

select secondary_database
     , p.last_backup_file
	 , c.last_copied_file
     , s.last_restored_file 
	 , CASE
			WHEN  Replace(p.last_backup_file, c.backup_Source_Directory,'') = replace(s.last_restored_file, c.backup_destination_directory, '') then 'Synced'
			ELSE 'BEHIND'
	   END
from [dbo].[log_shipping_secondary_databases] s
Left JOIN lssource.msdb.[dbo].[log_shipping_primary_databases] p
  on p.primary_database = s.secondary_database
JOIN [dbo].[log_shipping_secondary] c
  ON c.primary_database = s.secondary_database
ORder by secondary_database
