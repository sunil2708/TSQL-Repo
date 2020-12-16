/*============================================================================
USP_ReadErrorLog.sql
Written by Taiob M Ali
SqlWorldWide.com
 
This script will search all available SQL Server Error Log or SQL Server Agent Error Log
for a string.  You can narrow the result set by seraching for a second string with in the first result set.
 
In writing this script I took help from below site to find number of logs available to search.
https://ask.sqlservercentral.com/questions/99484/number-of-error-log-files.html
 
@logFileType= 1 for SQL Server Error Log, 2 for SQL Server Agent Error Log
@searchString1 =any string to search for
@searchString2 =filter the search result further
@start =search start from, if NULL all files will be searched.
@end   =search end at,   if NULL all files will be searched.
@sortOrder = by default ascending, use 'desc' if you need the result in descending order.
 
Instruction to run this script
--------------------------------------------------------------------------
Example of variable values
DECLARE @logFileType smallint        = 1 --Default to SQL Server Error Log, 2 =for SQL Server Agent Error Log
DECLARE @searchString1 nvarchar(256) = N'cpu'
DECLARE @searchString2 nvarchar(256) = N'condition'
DECLARE @start datetime              = NULL --'2017-08-05 09:37'
DECLARE @end datetime                = NULL   --'2017-08-05 10:37'
DECLARE @sortOrder nvarchar (4)      = N'desc' --or N'asc'
 
============================================================================*/
 
DECLARE @logFileType smallint = 1 --Default to SQL Server Error Log, 2 =for SQL Server Agent Error Log
DECLARE @searchString1 nvarchar(256) = N'requests taking longer than 15 seconds to complete' --NULL will output everything
DECLARE @searchString2 nvarchar(256) = NULL  --NULL
DECLARE @start datetime = NULL --'2017-08-05 09:37'  --Start of search, if NULL start from available log file
DECLARE @end datetime = NULL   --'2017-08-05 10:37'    --End of search, if NULL till the end of available log file
DECLARE @sortOrder nvarchar (4) = N'desc' --or N'asc'
DECLARE @logno int =0
DECLARE @ErrorLog nvarchar(4000)
DECLARE @ErrorLogPath nvarchar(4000)
DECLARE @NumberOfLogfiles int
 
DECLARE @FileList AS TABLE (
  subdirectory nvarchar(4000) NOT NULL
  ,DEPTH bigint NOT NULL
  ,[FILE] bigint NOT NULL
 );
 
IF OBJECT_ID('tempdb..#errorlog') IS NOT NULL
DROP TABLE #errorlog
 
CREATE TABLE #errorLog (LogDate datetime, PrcessInfo varchar(20), [Text] nvarchar(4000))
 
SELECT @ErrorLog = CAST(SERVERPROPERTY(N'errorlogfilename') AS NVARCHAR(4000));
SELECT @ErrorLogPath = SUBSTRING(@ErrorLog, 1, LEN(@ErrorLog) - CHARINDEX(N'\', REVERSE(@ErrorLog))) + N'\';
 
 INSERT INTO @FileList
 EXEC xp_dirtree @ErrorLogPath, 0, 1;
 
--Reading how many files available
IF(@logFileType=1)--SQL Server Error Log
 BEGIN
 SET @NumberOfLogfiles = (SELECT COUNT(*) FROM @FileList WHERE [@FileList].subdirectory LIKE N'ERRORLOG%');
 END
ELSE             --SQL Server Agent Error Log
 BEGIN
 SET @NumberOfLogfiles = (SELECT COUNT(*) FROM @FileList WHERE [@FileList].subdirectory LIKE N'SQLAGENT%');
 END
 
--Iterate through each log files
WHILE (@logno<@NumberOflogfiles )
 BEGIN
 INSERT INTO #ErrorLog
 EXEC master.dbo.xp_readerrorlog @logno, @logFileType, @searchString1, @searchString2, @start, @end, NULL ;
 SET @logno = @logno+1
 END
 
-- Reading the data
SELECT *
 FROM #ErrorLog
ORDER BY
CASE WHEN @sortOrder='desc'
 THEN logdate END desc,
CASE WHEN @sortOrder='asc'
THEN logdate END
