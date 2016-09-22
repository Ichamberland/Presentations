import-module SQLPS | out-null

$Instance = "DEMOSQLALIAS"

$SQL = 'SELECT @@ServerNAme As ServerName'

Invoke-SQLCMD -serverinstance $Instance -query $SQL