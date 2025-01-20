USE [WorkCollDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- **************************************************************************************************************************** 
-- * Object Name:    Month End Code
-- * Description:   1) Calculates The Following Metrics To Be Inserted Into The Month End IPD
-- *					- Spend (Designated) Before
-- *					- Fees (Designated) Before
-- *					- Interest (Designated) Before
-- *					- Dilutions (Designated) Before
-- *					- Payment Dilutions/WriteOffs (Designated) Before
-- *					- Interchange (Designated) Before
-- *					- Spend (Designated) After
-- *					- Fees (Designated) After
-- *					- Interest (Designated) After
-- *					- Dilutions (Designated)  After
-- *					- Payment Dilutions/WriteOffs (Designated) After
-- *					- Interchange (Designated) After
-- * WORKCOLLDB.dbo.monthly_file_mend2_desonly -> IANDASH.monthly_update_metrics_desonly -> iandash.oban_designated_perf_table -> Apended To iandash.oban_designated_perf_base2					
-- * Called By:      
-- * Returns:        
-- *
-- * Date           Author			Description 
-- * ----------     ------			------------------------------------------ 
-- * 27/07/2019		Arun G		    Commented Original Code 
-- ***************************************************************************************************************************** 
ALTER PROCEDURE [dbo].[usp_OBAN_Monthly_Redesignation] AS


-- **************************************************************************************************************************** 
-- * Object Name:    Re-Designation Code
-- * Description:   1) Creates the Re-Designation file for Month End OBAN
-- *				2) Takes all accounts that are no longer eligible OBAN customers and re-designates them
-- * 
-- * Called By:      
-- * Returns:        
-- *
-- * Date           Author			Description 
-- * ----------     ------			------------------------------------------ 
-- * 27/07/2019		Arun G		    Commented Original Code 
-- ***************************************************************************************************************************** 

DECLARE @AuditStartTime DATETIME
DECLARE @stage INT
DECLARE @StageDescription VARCHAR(255)
DECLARE @Process VARCHAR(255)
DECLARE @error_flag BIT

SET @AuditStartTime = GETDATE()
SET @stage = 1
SET @StageDescription = 'Redesignation Start'
SET @Process = 'Redesignation'
SET @error_flag = NULL

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
/***********************************************************************************
* Create The Initial Non Mon File From Accounts That Are No Longer Inelgible	   *
* Accounts can be identified as the MISC USER 05 = 0 includes					   *
	- Charged Off Accounts
	- O Balance Accounts
***********************************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Population Of Accounts'
SET @error_flag = NULL


DECLARE @StartDate date = DATEADD(DD,-1,DATEADD(MM,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE())))) 
DECLARE @EndDate date = (DATEADD(DD,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE()))))

IF OBJECT_ID(N'tempdb..#temp1') IS NOT NULL
BEGIN
DROP TABLE #temp1
END

SELECT 
b1.AccountNumber,
b1.snapshotdate
	  ,b2.UserDate05
      ,b2.UserDate06
      ,b2.MiscellaneousUser05
      ,b2.MiscellaneousUser06
      ,b1.CurrentBalance     
into #temp1
  FROM [FirstVision].[dbo].[vw_I2BSBaseSegment2Current] b2
  inner join [FirstVision].[dbo].[vw_I2BSDailyCurrent] b1
  on b2.AccountNumber = b1.AccountNumber
  where  MiscellaneousUser05 is not NULL or
         MiscellaneousUser06 is not NULL or
         UserDate05 is not NULL or 
         UserDate06 is not NULL 

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH

/***********************************************************************************
* Build NonMon File For Service Request
	* Check JULIAN DATE for today is correct (for Field Code 0806 - UserDate06)*
***********************************************************************************/
 
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Name Creation + Temp Table Filter'
SET @error_flag = NULL



IF NOT EXISTS (SELECT * FROM WORKCOLLDB.dbo.OBAN_Redesignation_BaseTableArchive
			   WHERE TheDate > @EndDate 
			  )

BEGIN

DECLARE @DailyTableName  VARCHAR(max) 
set @DailyTableName = (SELECT 'workcolldb.dbo.redesignation_daily_' + REPLACE(convert(varchar,convert(date,GETDATE()),104), '.', '') + '')

DECLARE @NonMonTableName VARCHAR(MAX)
SET @NonMonTableName = (SELECT 'workcolldb.dbo.redesignation_' + REPLACE(convert(varchar,convert(date,GETDATE()),104), '.', '') + '' + '_nonmon' )

DECLARE @TSQL VARCHAR(MAX)  
SET @TSQL = 'select *
			into ' + @DailyTableName + '
			from #temp1
			where MiscellaneousUser06 = 1 and MiscellaneousUser05 <> 1'

--print(@TSQL)
exec(@TSQL)


INSERT INTO WORKCOLLDB.dbo.OBAN_Redesignation_BaseTableArchive
SELECT @DailyTableName, convert(date,GETDATE())


END

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH


/***********************************************************************************
* Build NonMon File For Service Request
	* Check JULIAN DATE for today is correct (for Field Code 0806 - UserDate06)*
***********************************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'NonMon Table Creation'
SET @error_flag = NULL

IF EXISTS (SELECT * FROM WORKCOLLDB.dbo.OBAN_Redesignation_BaseTableArchive
			   WHERE TheDate > @EndDate
			  )

BEGIN

DECLARE @DSQL VARCHAR(MAX)  
SET @DSQL = 'select accountnumber as ReferenceNumber
				  ,''BS'' as FileCode
				  ,''0906'' as FieldCode
				  ,''0'' as todata
		    into ' + @NonMonTableName + '
		    from ' + @DailyTableName + '
		    
		    union all

		    select accountnumber as ReferenceNumber
				  ,''BS'' as FileCode
				  ,''0806'' as FieldCode
				  ,(SELECT convert(nvarchar,datepart(year, GETDATE()) * 1000 + datepart(dy, GETDATE())) /*AS Julian_Date*/) as todata
		    from ' + @DailyTableName +''

--print(@DSQL)
exec(@DSQL)


INSERT INTO WORKCOLLDB.dbo.OBAN_Redesignation_NonMonTableArchive
SELECT @NonMonTableName, convert(date,GETDATE())


END

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH

/***********************************************************************************
* Execute Non Mon Request
	* Check JULIAN DATE for today is correct (for Field Code 0806 - UserDate06)*
***********************************************************************************/
/*
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Non Mon Execution'
SET @error_flag = NULL

IF EXISTS (SELECT * FROM WORKCOLLDB.dbo.OBAN_Redesignation_NonMonTableArchive
			   WHERE TheDate > @StartDate
			   AND TheDate < @EndDate 
			  )

DECLARE @NSQL VARCHAR(MAX)  
SET @NSQL = 
'

USE InterfaceComms;
GO


DECLARE @OBANNonMon [dbo].[udt_NonMonetaryUser];

INSERT INTO @OBANNonMon
(ReferenceNumber 
,FileCode
,FieldCode
,AfterData
)

SELECT * FROM ' + @NonMonTableName +'

IF(SELECT COUNT(1) FROM   @OBANNonMon) > 0
       BEGIN
              EXEC usp_CreateNonMonetaryBatch_nr 
                      ''OBANDesignation''
                     ,@OBANNonMon
					 
       END;


'

--print(@NSQL)
exec(@NSQL)
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
*/

/***********************************************************************************
* If NonMon Creation Is Inocrrect or Neew To Be Cancelled Run Below Code           *
***********************************************************************************/
/*
USE InterfaceComms;
EXEC [dbo].[usp_ManageNonMonetaryBatch_nr]      
 @ActionCode = 'Remove'
,@BatchID = '128940'
*/

/***********************************************************************************
* Email																	           *
***********************************************************************************/
IF OBJECT_ID(N'tempdb..#OBANerrors') IS NOT NULL
BEGIN
DROP TABLE #OBANerrors
END


SELECT *
INTO #OBANerrors
FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes]
WHERE CONVERT(DATE,Starttime) = CONVERT(DATE,GETDATE())
AND Process = 'Redesignation'
AND error_flag = 1
ORDER BY  StartTime

IF (SELECT count(*) FROM #OBANerrors) > 0
BEGIN 

DECLARE @sEmailBody1	VARCHAR(MAX) = '<html><body><font face="Calibri">';
DECLARE @sEmailSubject1 VARCHAR(100)
    


	SET @sEmailBody1 += '<H3>Errors occurred during OBAN Process, please investigate </H3>';
	SET @sEmailBody1 += '<H5>Below table indicates the stage number and header of where the error occurred. Please investigate the error and rerun OBAN procedures. </H5>';
	SET @sEmailBody1 += '<table border = 1><font face="Calibri"<tr><th><center>Stage Run Time</center></th><th><center>Stage number</center></th><th><center>Error Description</center></th><th><center>Department</center></th></tr>';
	SET @sEmailBody1 +=  CAST((
							SELECT StartTime AS td,' ',
							       Stage AS td,' ',
								   description AS td,' ',
								   process AS td
							FROM #OBANerrors
							FOR XML PATH('tr'), ELEMENTS) AS NVARCHAR(MAX))
	SET @sEmailBody1 += '</font></table></br></br>'
	SET @sEmailBody1 += '<br />'
	SET @sEmailBody1 += 'Please see ----> SELECT * FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] WHERE CONVERT(DATE,Starttime) = CONVERT(DATE,GETDATE()) ORDER BY  StartTime'
	SET @sEmailBody1 += '<br />'
	SET @sEmailBody1 += '<br />'
	SET @sEmailBody1 += 'This email trigger is created in [WORKCOLLDB].[dbo].[usp_OBAN_Monthly_Redesignation]'


	EXEC msdb.dbo.sp_send_dbmail 
                           @recipients = 'arun.ghataora@vanquisbank.co.uk; onur.toy@vanquisbank.co.uk',
                           @subject = 'Errors Occured During The OBAN Redesignation Process',
                           @body = @sEmailBody1,
                           @body_format = 'HTML';

END

ELSE




BEGIN

DECLARE @ESQL nvarchar(max)
SET @ESQL = 

'
DECLARE @sEmailBody2   VARCHAR(MAX) = ''<html><body><font face="Calibri">'';
DECLARE @sEmailSubject2 VARCHAR(100)

	SET @sEmailBody2 += ''<H4>1) All steps completed in OBAN Redesignation.</H4>'';
	SET @sEmailBody2 += ''<table border = 1><font face="Calibri"<tr><th><center>Stage Number</center></th><th><center>Stage Start</center></th><th><center>Description</center></th><th><center>Process</center></th><th><center>Duration (Seconds) </center></th></tr>'';
	SET @sEmailBody2 +=  CAST((select distinct 
								      row_number() over(order by stage asc) AS td,'' '',
							          StartTime AS td,'' '',
								      description AS td,'' '',
								      process AS td,'' '',
									  duration as td,'' ''
							FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes]
							WHERE CONVERT(DATE,Starttime) = CONVERT(DATE,GETDATE())
							AND Process = ''Redesignation''
							FOR XML PATH(''tr''), ELEMENTS) AS NVARCHAR(MAX))
	SET @sEmailBody2 += ''</font></table>''

	SET @sEmailBody2 += ''<br />''
	SET @sEmailBody2 += ''<br />''
	SET @sEmailBody2 += ''<H4>2) Output Of Redesignation.</H4>'';
	SET @sEmailBody2 += ''<table border = 1><font face="Calibri"<tr><th><center>Date</center></th><th><center>Accounts</center></th><th><center>Balance</center></th></tr>'';
	SET @sEmailBody2 +=  CAST((SELECT convert(date,getdate())  AS td,'' '',
									  count(*) AS td,'' '',
									  SUM(CurrentBalance)AS td,'' ''
								FROM ' + @DailyTableName + '
							FOR XML PATH(''tr''), ELEMENTS) AS NVARCHAR(MAX))
	SET @sEmailBody2 += ''</font></table>''



	SET @sEmailBody2 += ''<br />''
	SET @sEmailBody2 += ''<br />''
	SET @sEmailBody2 += ''<H6>This trigger email is created in [WORKCOLLDB].[dbo].[usp_OBAN_Monthly_Redesignation].''  + ''</H6>''; 
	SET @sEmailBody2 += ''<H6>Process SME team: Finance Team''  + ''</H6>'';
	SET @sEmailBody2 += ''<H6>Implementation: Insights and Analytics''  + ''</H6>'';  


EXEC msdb.dbo.sp_send_dbmail 
                           @recipients = ''arun.ghataora@vanquisbank.co.uk; onur.toy@vanquisbank.co.uk'',
                           @subject = ''OBAN Redesignation Ran Sucessfully'',
                           @body = @sEmailBody2,
                           @body_format = ''HTML'';

'

EXEC(@ESQL)
END
