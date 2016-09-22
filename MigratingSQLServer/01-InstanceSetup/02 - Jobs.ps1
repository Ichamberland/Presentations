import-module sqlps | out-null
clear


$SourceInstance = 'van-sql2008v1\sql01'
$DestInstance   = 'van-sql2014v1\sql01'


# Create a collection consisting
# of all of the job from the source server
$Jobs = Get-ChildItem "SQLSERVER:\\SQL\\$SourceInstance\\JobServer\\Jobs\\" | where {$_.Name -inotmatch '##' -and $_.Name -inotmatch 'sa' -and $_.Name -inotmatch 'NT '}

$SQL = ''


# Loop through the jobs scripting 
FOREACH ($Job in $Jobs)
{
    $SQL += $Job.Script()
    $SQL += "`n"
}

$SQL

# Can execute the generated SQL Commands againt the destination Server

#Invoke-Sqlcmd -ServerInstance $DestInstance -Query $SQL

