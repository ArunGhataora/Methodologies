USE [WorkCollDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- **************************************************************************************************************************** 
-- * Object Name:    Cash Flow Month End Code
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
-- * 27/07/2021		Arun G		    Commented Original Code 
-- * 26/11/2021		Arun G		    Added Audit Tracking 
-- ***************************************************************************************************************************** 
ALTER PROCEDURE [dbo].[usp_OBAN_Monthly_CashFlow] AS


DECLARE @AuditStartTime DATETIME
DECLARE @stage INT
DECLARE @StageDescription VARCHAR(255)
DECLARE @Process VARCHAR(255)
DECLARE @error_flag BIT

SET @AuditStartTime = GETDATE()
SET @stage = 1
SET @StageDescription = 'Cash Flow Start'
SET @Process = 'Cash Flow'
SET @error_flag = NULL

EXEC [WORK_Customer].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
/*******************************************************
* Stage 1: Populate Desginated Acounts At Start Date   *
********************************************************/
DECLARE @StartDate date = DATEADD(DD,-1,DATEADD(MM,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE())))) 
DECLARE @EndDate date = (DATEADD(DD,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE()))))


BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Populate Desginated Acounts At Start Date'
SET @error_flag = NULL


IF OBJECT_ID(N'tempdb..#temp1') IS NOT NULL
BEGIN
DROP TABLE #temp1
END

SELECT  accountnumber,MiscellaneousUser06
into #temp1
from [FirstVision].[dbo].[vw_I2BSBaseSegment2] as b
where b.filedate <= @StartDate and 
	 (b.enddate >= @StartDate
	  or b.enddate is null) 
  and b.MiscellaneousUser06 = '1'


TRUNCATE TABLE workdb.dbo.designated_before

INSERT INTO workdb.dbo.designated_before
select *,
(SELECT	dateadd(dd,0,dateadd(mm,-1,(CONVERT(Date,DATEADD(mm,DATEDIFF(mm,0,getdate()),0)))))) as bmonth, 
(SELECT dateadd(mm,-1,CONVERT(Date,DATEADD(mm,DATEDIFF(mm,0,getdate())+1,0)))) as emonth
from #temp1

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/*****************************************************************
* Stage 2: Spend - Designated BEFORE   *
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Spend - Designated Before'
SET @error_flag = NULL

TRUNCATE TABLE workdb.dbo.cflow_spend_dry

INSERT INTO workdb.dbo.cflow_spend_dry
select GETDATE() as thedate, 
sum(CASE WHEN b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Principal_Spend
from workdb.dbo.designated_before as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.bmonth <= b.filedate
    and a.emonth > b.filedate
where 
b.filedate >= '20210101'
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684,
5624,3818,3814,3816,2028,5625,2027,3813)

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/*****************************************************************
* Stage 3: Fees and Charges - Designated BEFORE   *
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Fees and Charges - Designated Before'
SET @error_flag = NULL

TRUNCATE TABLE workdb.dbo.cflow_fees_chgs

INSERT INTO workdb.dbo.cflow_fees_chgs
select GETDATE() as thedate,
sum(
CASE WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)    
        and b.transactiontype01 in ('C','3') then -1*b.transactionamount 
	 WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)  
	and transactiontype01 = 'D' then b.transactionamount
	ELSE 0 end) as net_Fees_Charges,
sum(
CASE WHEN B.TRANSACTIONCODE in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and b.transactiontype01 in ('C','3') then -1*b.transactionamount 
	when b.transactioncode in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and transactiontype01 = 'D' then b.transactionamount
	else 0 end) as net_interest_charges
from workdb.dbo.designated_before as a
left join Firstvision.dbo.vw_I2gtgeneratedtransactions as b
	on a.accountnumber = b.accountnumber
    and a.bmonth <= b.filedate
	and a.emonth > b.filedate
where 
b.filedate >= '20201201'
AND 
b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,0005,0006,0401,0419,0420,0427,2534,2617,2618,2560,417,418,481,480)   


EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/*****************************************************************
* Stage 4: Dilutions - Designated Before						 *
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Dilutions - Designated Before'
SET @error_flag = NULL

/*DILUTIONS FIGURES - BEFORE*/
  TRUNCATE TABLE workdb.dbo.dilutions_check_cflow
  
  INSERT INTO workdb.dbo.dilutions_check_cflow
  select GETDATE() as TheDate,
		sum(b.transactionamount) as total_dilutions_cflow
  from workdb.dbo.designated_before as a
  left join firstvision.dbo.vw_i2ptpostedtransactions as b
  on a.accountnumber =  b.accountnumber 
  where  b.filedate >= a.bmonth
  and  b.filedate < a.emonth
  and ((b.logicmodule = 2 and  b.transactioncode in (208,4146,206,212,4110)) or (b.logicmodule = 4 and  b.transactioncode = 2608) or (b.logicmodule = 97 and b.transactioncode = 97))

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/*****************************************************************
* Stage 5: Payment Dilutions - Designated Before				 *
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Payment Dilutions - Designated Before'
SET @error_flag = NULL

/*PAYMENT DILUTIONS PIECE - BEFORE*/
TRUNCATE TABLE workdb.dbo.payment_dilutions_cflow

INSERT INTO workdb.dbo.payment_dilutions_cflow
select GETDATE() as TheDate,
sum(CASE WHEN b.transactiontype01 in ('C','3') then b.transactionamount 
	 WHEN  b.transactiontype01 = 'D' then -1*b.transactionamount 
	ELSE 0 end) as Other_Payment_dilutions
from workdb.dbo.designated_before as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
        and a.bmonth <= b.filedate
	    and a.emonth > b.filedate
where 
b.filedate >= '20210101'
AND b.TransactionCode IN 
(2100,2534,4994,2532,2530,2518,2065,2560,
4096,2610,2614,2602,4938,2032,4084,2613,2609,4085)

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/*****************************************************************
* Stage 6: Interchange - Before									 *
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Interchange - Before'
SET @error_flag = NULL

/*SPEND RETAIL ONLY for Interchange*/
TRUNCATE TABLE workdb.dbo.cflow_interchange

INSERT INTO workdb.dbo.cflow_interchange
select
GETDATE() as TheDate,
sum(CASE WHEN b.LogicModule IN (1,2) 
		  and b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.LogicModule IN (1,2) 
		 and b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Net_Retail_spend
from workdb.dbo.designated_before as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.bmonth <= b.filedate
    and a.emonth > b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (1,2)
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,97,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2532,2534,2560,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684,5624,3818,3814,3816,2028,5625,2027,3813)
and b.creditplannumber = 10002

TRUNCATE TABLE workdb.dbo.cflow_interchange2

INSERT INTO workdb.dbo.cflow_interchange2
select 
GETDATE() as TheDate,
sum(round(Net_Retail_spend*0.003,2)) as interchange
from workdb.dbo.cflow_interchange

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/*****************************************************************
* Stage 7: Defaults - All *
/*DEFAULTS - REDESIGNATION - FOR DEFAULTS FIGURES - END OF OF MONTH BALANCES OF REDESIGNATED WITHIN THE MONTH - 
ALL ACTIONS OF THESE ACCOUNTS ARE CONSIDERED IN THE CALCULATIONS ALREADY HENCE END OF MONTH BALANCES ARE TAKEN OUT
DO NOT FORGET TO CHANGE THE REDESIGNATION FILE NAME/DATES AS WELL AS THE MONTH END DATE TO THE LATEST MONTH END FILEDATE/SNAPSHOTDATE*/
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Defaults - All'
SET @error_flag = NULL


DECLARE @DesginationTable nvarchar(max)
SET @DesginationTable = (SELECT Table_Name FROM WORKCOLLDB.dbo.OBAN_Redesignation_BaseTableArchive
						 WHERE TheDate > @StartDate
						 AND TheDate < @EndDate
						 )

DECLARE @NSQL VARCHAR(MAX)  
SET @NSQL = 
'
DECLARE @StartDate date = DATEADD(DD,-1,DATEADD(MM,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE())))) 
DECLARE @EndDate date = (DATEADD(DD,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE()))))

TRUNCATE TABLE workdb.dbo.principaldefaults_cflow

INSERT INTO workdb.dbo.principaldefaults_cflow
select GETDATE() as TheDate, 
	   sum(b.principlebalance) as  principal_balance_defaulted,sum(b.currentbalance) as total_balance
from ' + @DesginationTable + ' as a
left join firstvision.dbo.vw_i2psplansegments as b
on a.accountnumber = b.accountnumber 
where (b.filedate <= @EndDate and (b.enddate is null or b.enddate >= @EndDate))
--and b.status = 1 

/*TOTAL DEFAULTS TO GO INTO CASH FLOW MODEL*/
select accountnumber,currentbalance
into #temp
from firstvision.dbo.vw_i2bsdaily
where snapshotdate = @EndDate


DROP TABLE workdb.dbo.principaldefaultsDC_cflow
select GETDATE() as TheDate,
	   sum(currentbalance) as bals
INTO workdb.dbo.principaldefaultsDC_cflow
from #temp
where accountnumber in (select accountnumber from ' + @DesginationTable + ')
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
/*****************************************************************
* Stage 8: Final Table*
Take all outputs and
******************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Final Insert - Before'
SET @error_flag = NULL

TRUNCATE TABLE workdb.dbo.OBANIPD_Final

INSERT INTO workdb.dbo.OBANIPD_Final

SELECT 'Principal Spend' as Metric, Principal_Spend as Value ,TheDate, 'Before' as Category
FROM workdb.dbo.cflow_spend_dry
UNION
SELECT 'Fees', net_Fees_Charges ,TheDate, 'Before'
FROM workdb.dbo.cflow_fees_chgs
UNION
SELECT 'Interest', net_Interest_Charges ,TheDate, 'Before'
FROM workdb.dbo.cflow_fees_chgs
UNION
SELECT 'Dilutions', total_dilutions_cflow,TheDate, 'Before'
FROM workdb.dbo.dilutions_check_cflow
UNION
SELECT 'Payment Dilutions', Other_Payment_dilutions,TheDate, 'Before'
FROM workdb.dbo.payment_dilutions_cflow
UNION
SELECT 'Interchange', interchange,thedate, 'Before'
FROM workdb.dbo.cflow_interchange2
UNION 
SELECT 'Princpial Defaults', principal_balance_defaulted,TheDate, 'Defaults'
FROM workdb.dbo.principaldefaults_cflow
UNION 
SELECT 'Defaults', total_balance ,TheDate, 'Defaults'
FROM workdb.dbo.principaldefaults_cflow


EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH
/**********************************************************************************
* Optional:  Designated AFTER - Check to see if any accounts are Designated After *
***********************************************************************************/
BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'Final Insert - Before'
SET @error_flag = NULL


TRUNCATE TABLE  workdb.dbo.designated_after

INSERT INTO workdb.dbo.designated_after
SELECT  accountnumber
	  ,currentbalance
	  ,convert(date,snapshotdate) as bmonth
	  ,(SELECT dateadd(mm,0,CONVERT(Date,DATEADD(mm,DATEDIFF(mm,0,snapshotdate)+1,0)))) as emonth
  FROM [BusinessProcesses].[dbo].[vw_OBANDesignation]
  where snapshotdate >= @StartDate
    and snapshotdate <= @EndDate

EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH

/*****************************************************************
* Optional Stage 2: Spend - Designated AFTER   *
******************************************************************/
IF EXISTS (SELECT * FROM workdb.dbo.designated_after)

BEGIN 

BEGIN TRY
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 (ISNULL(Stage,0) + 1 ) FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = 'After'
SET @error_flag = NULL

/*****************************************************************
* Optional Stage 2: Spend - Designated AFTER   *
******************************************************************/
/*SPEND ONLY - DESIGNATED AFTER*/
TRUNCATE TABLE workdb.dbo.cflow_spend_dry_after

INSERT INTO workdb.dbo.cflow_spend_dry_after
select 
GETDATE() as TheDate,
sum(CASE WHEN b.transactiontype01 = 'D' then b.transactionamount 
    WHEN  b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Principal_Spend
from workdb.dbo.designated_after as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.bmonth < b.filedate
    and a.emonth > b.filedate
where 
b.filedate >= '20201201'
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,2186,2528,2530,2616,2618,2692,
3906,4028,4142,4143,4144,4145,2683,2684,5624,3818,3814,3816,2028,5625,2027,3813)


/*****************************************************************
* Optional Stage 3: Fees and Charges - Designated AFTER *
******************************************************************/
/*FEES AND CHARGES - DESIGNATED AFTER*/
TRUNCATE TABLE workdb.dbo.cflow_fees_chgs_after

INSERT INTO workdb.dbo.cflow_fees_chgs_after
select 
GETDATE() as TheDate,
sum(
CASE WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)    
        and b.transactiontype01 in ('C','3') then -1*b.transactionamount 
	 WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)  
	and transactiontype01 = 'D' then b.transactionamount
	ELSE 0 end) as net_Fees_Charges,
sum(
CASE WHEN B.TRANSACTIONCODE in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and b.transactiontype01 in ('C','3') then -1*b.transactionamount 
	when b.transactioncode in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and transactiontype01 = 'D' then b.transactionamount
	else 0 end) as net_interest_charges
from workdb.dbo.designated_after as a
left join Firstvision.dbo.vw_I2gtgeneratedtransactions as b
	on a.accountnumber = b.accountnumber
    and a.bmonth < b.filedate
	and a.emonth > b.filedate
where 
b.filedate >= '20201201'
AND 
b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,0005,0006,0401,0419,0420,0427,2534,2617,2618,2560,417,418,481,480)   

select * from workdb.dbo.cflow_fees_chgs
select * from workdb.dbo.cflow_fees_chgs_after

/*****************************************************************
* Optional Stage 4: Dilutions											 *
******************************************************************/

TRUNCATE TABLE workdb.dbo.dilutions_check_cflow_after

INSERT INTO workdb.dbo.dilutions_check_cflow_after

  /*DILUTIONS FIGURES - AFTER*/
  select GETDATE() as TheDate,
		 sum(b.transactionamount) as total_dilutions_cflow
  from workdb.dbo.designated_after as a
  left join firstvision.dbo.vw_i2ptpostedtransactions as b
  on a.accountnumber =  b.accountnumber 
  where  b.filedate > a.bmonth
  and  b.filedate < a.emonth
  and ((b.logicmodule = 2 and  b.transactioncode in (208,4146,206,212,4110)) or (b.logicmodule = 4 and  b.transactioncode = 2608) or (b.logicmodule = 97 and b.transactioncode = 97))
 

/*****************************************************************
* Optional Stage 5: PAYMENT DILUTIONS - After				     *
******************************************************************/
TRUNCATE TABLE workdb.dbo.payment_dilutions_cflow_after

INSERT INTO workdb.dbo.payment_dilutions_cflow_after

select
GETDATE() as TheDate,
sum(CASE WHEN b.transactiontype01 in ('C','3') then b.transactionamount 
	 WHEN  b.transactiontype01 = 'D' then -1*b.transactionamount 
	ELSE 0 end) as Other_Payment_dilutions
from workdb.dbo.designated_after as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
        and a.bmonth < b.filedate
	    and a.emonth > b.filedate
where 
b.filedate >= '20210101'
AND b.TransactionCode IN 
(2100,2534,4994,2532,2530,2518,2065,2560,
4096,2610,2614,2602,4938,2032,4084,2613,2609,4085)


/*****************************************************************
* Optional Stage 6: Interchange - After							 *
******************************************************************/
/*SPEND RETAIL ONLY for Interchange*/
TRUNCATE TABLE workdb.dbo.cflow_interchange_after

INSERT INTO workdb.dbo.cflow_interchange_after

select
GETDATE() as TheDate,
sum(CASE WHEN b.LogicModule IN (1,2) 
		  and b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.LogicModule IN (1,2) 
		 and b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Net_Retail_spend
from workdb.dbo.designated_after as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.bmonth <= b.filedate
    and a.emonth > b.filedate
where 
b.filedate >= '20210101'
AND b.LogicModule IN (1,2)
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,97,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2532,2534,2560,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684,5624,3818,3814,3816,2028,5625,2027,3813)
and b.creditplannumber = 10002

TRUNCATE TABLE workdb.dbo.cflow_interchange2_after

INSERT INTO workdb.dbo.cflow_interchange2_after

select 
*,round(Net_Retail_spend*0.003,2) as interchange
from workdb.dbo.cflow_interchange_after

SELECT * FROM workdb.dbo.OBANIPD_Final
/*****************************************************************
* Stage 8: Final Table*
Take all outputs and
******************************************************************/

INSERT INTO workdb.dbo.OBANIPD_Final

SELECT 'Principal Spend' as Metric, Principal_Spend as Value ,TheDate, 'After' as Category
FROM workdb.dbo.cflow_spend_dry_after
UNION
SELECT 'Fees',net_Fees_Charges, TheDate,'After'
FROM workdb.dbo.cflow_fees_chgs_after
UNION
SELECT 'Interest', net_Interest_Charges,TheDate,'After'
FROM workdb.dbo.cflow_fees_chgs_after
UNION
SELECT 'Dilutions',total_dilutions_cflow, TheDate,'After'
FROM workdb.dbo.dilutions_check_cflow_after
UNION
SELECT 'Payment Dilutions',Other_Payment_dilutions,TheDate, 'After'
FROM workdb.dbo.payment_dilutions_cflow_after
UNION
SELECT 'Interchange',interchange,thedate ,'After'
FROM workdb.dbo.cflow_interchange2_after


EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END TRY
BEGIN CATCH
SET @AuditStartTime = GETDATE()
SET @stage = (SELECT TOP 1 ISNULL(Stage,0)+1 FROM [WORK_Customer].[dbo].[t_OBAN_Audit_StageTimes] ORDER BY StartTime DESC)
SET @StageDescription = (SELECT ERROR_MESSAGE())
SET @error_flag = 1 
EXEC [WORKCollDB].[dbo].[usp_OBAN_auditTimings] @AuditStartTime,@stage,@StageDescription,@Process,@error_flag
END CATCH

END

/*****************************************************************
* Email															 *
******************************************************************/

DECLARE @sEmailBody2   VARCHAR(MAX) = '<html><body><font face="Calibri">';
DECLARE @sEmailSubject2 VARCHAR(100)

	SET @sEmailBody2 += '<H4>1) All steps completed in OBAN Monthly Cash Flow Job.</H4>';
	SET @sEmailBody2 += '<table border = 1><font face="Calibri"<tr><th><center>Stage Number</center></th><th><center>Stage Start</center></th><th><center>Description</center></th><th><center>Process</center></th><th><center>Duration (Seconds) </center></th></tr>';
	SET @sEmailBody2 +=  CAST((select row_number() over(order by stage asc) AS td,' ',
							          StartTime AS td,' ',
								      description AS td,' ',
								      process AS td,' ',
									  duration as td,' '
							FROM [WORKCollDB].[dbo].[t_OBAN_Audit_StageTimes]
							WHERE CONVERT(DATE,Starttime) = CONVERT(DATE,GETDATE())
							AND Process = 'Cash Flow'
							ORDER BY StartTime desc
							FOR XML PATH('tr'), ELEMENTS) AS NVARCHAR(MAX))
	SET @sEmailBody2 += '</font></table>'

	SET @sEmailBody2 += '<br />'
	SET @sEmailBody2 += '<br />'
	SET @sEmailBody2 += '<H4>2) Output of Cash Flow.</H4>';
	SET @sEmailBody2 += '<table border = 1><font face="Calibri"<tr><th><center>Metric</center></th><th><center>Date</center></th><th><center>Category</center></th><th><center>Value</center></th></tr>';
	SET @sEmailBody2 +=  CAST((SELECT Metric   				AS td,'',
									  convert(date,TheDate) AS td,'',
									  Category				AS td,'',
									  Value	   				AS td,''
								FROM workdb.dbo.OBANIPD_Final
							FOR XML PATH('tr'), ELEMENTS) AS NVARCHAR(MAX))
	SET @sEmailBody2 += '</font></table>'



	SET @sEmailBody2 += '<br />'
	SET @sEmailBody2 += '<br />'
	SET @sEmailBody2 += '<H6>This trigger email is created in [WORKCOLLDB].[dbo].[usp_OBAN_Monthly_CashFlow].'  + '</H6>'; 
	SET @sEmailBody2 += '<H6>Process SME team: Finance Team'  + '</H6>';
	SET @sEmailBody2 += '<H6>Implementation: Insights and Analytics'  + '</H6>';  


EXEC msdb.dbo.sp_send_dbmail 
                           @recipients = 'arun.ghataora@vanquisbank.co.uk',
                           @subject = 'OBAN Monthly Cash Flow Ran Sucessfully',
                           @body = @sEmailBody2,
                           @body_format = 'HTML';
