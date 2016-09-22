use master
go

--All Logins are Scripted
exec sp_help_revlogin

--Specific Login is Scripted
exec sp_help_revlogin 'Ant_Srvc'

--Reference: https://support.microsoft.com/en-us/kb/918992