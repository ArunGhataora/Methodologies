-- **************************************************************************************************************************** 
-- * Object Name:    Investor
-- * Description:   Calculates Metrics For OBAN Investor Report - Portfolio breakdown
-- *				Section 1
-- *					i) Payments Per Account
-- *					ii) Spend Per Account
-- *					iii) Fees and Charges Per Account 
-- *				Output = workcolldb.dbo.monthly_file_mend2 and workcolldb.dbo.monthlyspend_interchange
-- * Called By:      
-- * Returns:        
-- *
-- * Date           Author			Description 
-- * ----------     ------			------------------------------------------ 
-- * 27/07/2019		Arun G		    Commented Original Code 
-- ***************************************************************************************************************************** 



/*******************************************************
* SECTION 1: Entire Portfolio	KPIs				   *
********************************************************/

/*******************************************************
* i) Payments Per Account							*
********************************************************/


/* Payments Based On Set Trans Codes? */
drop table workcolldb.dbo.monthlypayments

select a.accountnumber,
	   a.monthendposition,
	   a.begmonth,
	   a.reportdate,
sum(CASE WHEN b.LogicModule IN (30,31) 
      and b.transactiontype01 in ('C','3') then b.transactionamount 
	 WHEN  b.LogicModule IN (30,31) 
          and b.transactiontype01 = 'D' then -1*b.transactionamount 
	ELSE 0 end) as Net_Payment
into workcolldb.dbo.monthlypayments
from workcolldb.dbo.monthly_file_mend as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
    and a.begmonth <= b.filedate
	and a.reportdate >= b.filedate
where 
b.filedate >= '20210101'
AND b.LogicModule IN (30,31)
AND	b.TransactionCode IN (130,131,132,133,160,161,162,163,164,165,176,177,216,217,218,219,222,223,436,1350,1351,2502,2503,2504,2505,2506,2507,2508,2509,2510,2511,2512,2514,2515,2516,
2517,2520,2521,2522,2523,2524,2525,2526,2527,2538,2540,2541,2542,2558,2559,2562,2563,2580,2581,2584,2585,2588,2589,2594,2595,2596,2597,2694,2695,4114,4132,4133,4196,
2560,2064,4994,2534,2065,2100,2532,2530,2518,2528,2065)
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate

/* Payments Based On Logic Module */
drop table workcolldb.dbo.monthlypayments2
select a.accountnumber,
	   a.monthendposition,
	   a.begmonth,
	   a.reportdate,
sum(CASE WHEN b.LogicModule IN (30,31) 
      and b.transactiontype01 in ('C','3') then b.transactionamount 
	 WHEN  b.LogicModule IN (30,31) 
          and b.transactiontype01 = 'D' then -1*b.transactionamount 
	ELSE 0 end) as Other_Payment_dilutions
into workcolldb.dbo.monthlypayments2
from workcolldb.dbo.monthly_file_mend as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
        and a.begmonth <= b.filedate
	    and a.reportdate >= b.filedate
where 
b.filedate >= '20210101' /*Just a filedate to reduce run times*/
AND b.LogicModule IN (30,31)
AND	b.TransactionCode IN 
(2100,2534,4994,2532,2530,2518,2065,2560)
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate

/* MontlyPayments2 Should have more payments than MonthlyPayments */

/*******************************************************
* ii) Spend Per Account								  *
********************************************************/
drop table workcolldb.dbo.monthlyspend
select a.accountnumber,
		  a.monthendposition,
		  a.begmonth,
	      a.reportdate,
sum(CASE WHEN b.LogicModule IN (1,2) 
		  and b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.LogicModule IN (1,2) 
		 and b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Net_Spend
into workcolldb.dbo.monthlyspend
from workcolldb.dbo.monthly_file_mend as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.begmonth <= b.filedate
    and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (1,2)
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,97,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2532,2534,2560,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684)
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate 

/*******************************************************
* iii) Fees and Charges Per Account					   *
********************************************************/
drop table workcolldb.dbo.monthly_fees_chgs
select a.accountnumber,
		  a.monthendposition,
		    a.begmonth,
	      a.reportdate,
sum(
CASE WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)    
        and b.transactiontype01 = 'C' then -1*b.transactionamount 
	 WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)  
	and transactiontype01 = 'D' then b.transactionamount
	ELSE 0 end) as net_Fees_Charges,
sum(
CASE WHEN B.TRANSACTIONCODE in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and b.transactiontype01 = 'C' then -1*b.transactionamount 
	when b.transactioncode in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and transactiontype01 = 'D' then b.transactionamount
	else 0 end) as net_interest_charges
into workcolldb.dbo.monthly_fees_chgs
from workcolldb.dbo.monthly_file_mend as a
left join Firstvision.dbo.vw_I2gtgeneratedtransactions as b
	on a.accountnumber = b.accountnumber
    and a.begmonth <= b.filedate
	and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND 
b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,0005,0006,0401,0419,0420,0427,2534,2617,2618,2560,417,418,481,480)   
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate

/*******************************************************
* iv) Fraud Dilutions Per Account					   *
********************************************************/

 drop table workcolldb.dbo.dilutions_fraud_check
 select
 a.accountnumber,a.monthendposition,
  sum(b.transactionamount) as spend_Fraud_dilutions
  into workcolldb.dbo.dilutions_fraud_check
  from workcolldb.dbo.monthly_file_mend as a
  left join firstvision.dbo.vw_i2ptpostedtransactions as b
  on a.accountnumber =  b.accountnumber 
  where  b.filedate >= a.begmonth
  and  b.filedate <= a.reportdate
  and ((b.logicmodule = 2 and  b.transactioncode in (208,4146,206,212,4110)) or (b.logicmodule = 4 and  b.transactioncode = 2608) or (b.logicmodule = 97 and b.transactioncode = 97))
  group by a.accountnumber,a.monthendposition


/*******************************************************
*  Final Table										*
********************************************************/
drop table workcolldb.dbo.monthly_file_mend2;
select a.*,
	   b.Net_Payment,
	   c.Other_Payment_dilutions,
	   d.Net_Spend,
	   e.net_Fees_Charges,
	   e.net_interest_charges,
	   f.spend_Fraud_dilutions
into workcolldb.dbo.monthly_file_mend2
from workcolldb.dbo.monthly_file_mend as a
left join workcolldb.dbo.monthlypayments as b
	on a.accountnumber = b.accountnumber 
	and a.MonthEndPosition = b.MonthEndPosition
left join workcolldb.dbo.monthlypayments2 as c
	on a.accountnumber = c.accountnumber 
	and a.MonthEndPosition = c.MonthEndPosition
left join workcolldb.dbo.monthlyspend as d
    on a.accountnumber = d.accountnumber 
	and a.MonthEndPosition = d.MonthEndPosition
left join workcolldb.dbo.monthly_fees_chgs as e
    on a.accountnumber = e.accountnumber 
	and a.MonthEndPosition = e.MonthEndPosition
left join workcolldb.dbo.dilutions_fraud_check as f
    on a.accountnumber = f.accountnumber 
	and a.MonthEndPosition = f.MonthEndPosition

/*******************************************************
*  v)	Interchange									   *
********************************************************/
	--select * from workcolldb.dbo.monthly_file_mend2
	--select top 1000 * from workcolldb.dbo.Month_end_full1_ot_ch2	
/*SPEND RETAIL ONLY*/
drop table workcolldb.dbo.monthlyspend_interchange
select a.accountnumber,
		  a.monthendposition,
		  a.begmonth,
	      a.reportdate,
sum(CASE WHEN b.LogicModule IN (1,2) 
		  and b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.LogicModule IN (1,2) 
		 and b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Net_Retail_spend
into workcolldb.dbo.monthlyspend_interchange
from workcolldb.dbo.monthly_file_mend as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.begmonth <= b.filedate
    and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (1,2)
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,97,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2532,2534,2560,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684)
and b.creditplannumber = 10002
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate 

drop table workcolldb.dbo.monthlyspend_interchange2
select 
*,round(Net_Retail_spend*0.003,2) as interchange
into workcolldb.dbo.monthlyspend_interchange2
from workcolldb.dbo.monthlyspend_interchange


/*Select To Check*/
select top 10000 * from workcolldb.dbo.monthly_file_mend2

/*******************************************************
* SECTION 1: Entire Portfolio	END						*
* Return to SAS VIYA and run from there
********************************************************/



/*******************************************************
* SECTION 2: Pre Production						*
* Run Before beginning Section 2 in SAS VIYA
********************************************************/

DECLARE @StartDate date = DATEADD(DD,-1,DATEADD(MM,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE())))) 
DECLARE @EndDate date = (DATEADD(DD,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE()))))

/*SECTION 2 DESIGNATED AT THE END - RUN THIS BEFORE RUNNING THE VA INVESTOR REPORTING CODE*/
/*TO SEND TO VIYA*/
/*MAIN CURRENT CHECK - CHANGE THE DATE to last monthend positiondate */
drop table #temp1
SELECT 
b2.AccountNumber,
b2.filedate,
b2.customernumber
	  ,b2.UserDate05
      ,b2.UserDate06
      ,b2.MiscellaneousUser05
      ,b2.MiscellaneousUser06    
into #temp1
  FROM [FirstVision].[dbo].[vw_I2BSBaseSegment2] b2
  where  
 (b2.filedate <= @EndDate and (b2.enddate is null or b2.enddate >= @EndDate))
  and b2.MiscellaneousUser06 = '1'

drop table workcolldb.dbo.designated_end
select a.*,b.postalcode,1 as designated
into workcolldb.dbo.designated_end
from #temp1 as a 
left join firstvision.dbo.vw_I2NANameAddressCurrent as b
on a.customernumber = b.customernumber

--select top 1000 * from workcolldb.dbo.designated_end

SELECT count(*) FROM workcolldb.dbo.designated_end

/*******************************************************
* SECTION 2: Main						*
********************************************************/


DECLARE @StartDate date = DATEADD(DD,-1,DATEADD(MM,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE())))) 
DECLARE @EndDate date = (DATEADD(DD,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE()))))

/*RUN THE CODE IN AZURE CODE NUMBERED 02.Investor_Rep_Utd_monyy_IPD - created from the previous month's by changing the relevant dates*/
--select top 1000 * from workcolldb.dbo.monthly_file_mend_desonly 
--select * from workcolldb.dbo.monthly_file_mend_desonly 
/*FILE COMING FROM AZURE - SAS STUDIO*/

drop table workcolldb.dbo.monthlypayments_des
/* Payments */
select a.accountnumber,
	   a.monthendposition,
	   a.begmonth,
	   a.reportdate,
sum(CASE WHEN b.LogicModule IN (30,31) 
      and b.transactiontype01 in ('C','3') then b.transactionamount 
	 WHEN  b.LogicModule IN (30,31) 
          and b.transactiontype01 = 'D' then -1*b.transactionamount 
	ELSE 0 end) as Net_Payment
into workcolldb.dbo.monthlypayments_des
from workcolldb.dbo.monthly_file_mend_desonly as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
    and a.begmonth <= b.filedate
	and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (30,31)
AND	b.TransactionCode IN (130,131,132,133,160,161,162,163,164,165,176,177,216,217,218,219,222,223,436,1350,1351,2502,2503,2504,2505,2506,2507,2508,2509,2510,2511,2512,2514,2515,2516,
2517,2520,2521,2522,2523,2524,2525,2526,2527,2538,2540,2541,2542,2558,2559,2562,2563,2580,2581,2584,2585,2588,2589,2594,2595,2596,2597,2694,2695,4114,4132,4133,4196,
2560,2064,4994,2534,2065,2100,2532,2530,2518,2528,2065)
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate


drop table workcolldb.dbo.monthlypayments2_desonly
select a.accountnumber,
	   a.monthendposition,
	   a.begmonth,
	   a.reportdate,
sum(CASE WHEN b.LogicModule IN (30,31) 
      and b.transactiontype01 in ('C','3') then b.transactionamount 
	 WHEN  b.LogicModule IN (30,31) 
          and b.transactiontype01 = 'D' then -1*b.transactionamount 
	ELSE 0 end) as Other_Payment_dilutions
into workcolldb.dbo.monthlypayments2_desonly
from workcolldb.dbo.monthly_file_mend_desonly as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
        and a.begmonth <= b.filedate
	    and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (30,31)
AND	b.TransactionCode IN 
(2100,2534,4994,2532,2530,2518,2065,2560)
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate

/*SPEND ONLY*/
drop table workcolldb.dbo.monthlyspend_desonly
select a.accountnumber,
		  a.monthendposition,
		  a.begmonth,
	      a.reportdate,
sum(CASE WHEN b.LogicModule IN (1,2) 
		  and b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.LogicModule IN (1,2) 
		 and b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Net_Spend
into workcolldb.dbo.monthlyspend_desonly
from workcolldb.dbo.monthly_file_mend_desonly as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.begmonth <= b.filedate
    and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (1,2)
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,97,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2532,2534,2560,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684)
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate 

/*FEES AND CHARGES*/
drop table workcolldb.dbo.monthly_fees_chgs_desonly
select a.accountnumber,
		  a.monthendposition,
		    a.begmonth,
	      a.reportdate,
sum(
CASE WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)    
        and b.transactiontype01 = 'C' then -1*b.transactionamount 
	 WHEN b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,417,418,481,480)  
	and transactiontype01 = 'D' then b.transactionamount
	ELSE 0 end) as net_Fees_Charges,
sum(
CASE WHEN B.TRANSACTIONCODE in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and b.transactiontype01 = 'C' then -1*b.transactionamount 
	when b.transactioncode in (0005,0006,0401,0419,0420,0427,2534,2617,2618,2560)
	and transactiontype01 = 'D' then b.transactionamount
	else 0 end) as net_interest_charges
into workcolldb.dbo.monthly_fees_chgs_desonly
from workcolldb.dbo.monthly_file_mend_desonly as a
left join Firstvision.dbo.vw_I2gtgeneratedtransactions as b
	on a.accountnumber = b.accountnumber
    and a.begmonth <= b.filedate
	and a.reportdate >= b.filedate
where 
b.filedate >= '20201201'
AND 
b.transactioncode in (0008,0009,0010,0011,0012,0013,0014,0015,0016,0021,
                        0048,0049,0103,0104,0144,0147,0049,0148,0407,0409,
                        0411,0413,0428,0439,0941,0942,0953,0954,0955,0956,
                        0957,0958,1343,1421,1422,2528,2530,2532,2536,1423,
                        1424,2690,0005,0006,0401,0419,0420,0427,2534,2617,2618,2560,417,418,481,480)   
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate


/*SPEND RELATED DILUTIONS*/
 drop table workcolldb.dbo.dilutions_fraud_check_desonly
 select
 a.accountnumber,a.monthendposition,
  sum(b.transactionamount) as spend_Fraud_dilutions
  into workcolldb.dbo.dilutions_fraud_check_desonly
  from workcolldb.dbo.monthly_file_mend_desonly as a
  left join firstvision.dbo.vw_i2ptpostedtransactions as b
  on a.accountnumber =  b.accountnumber 
  where  b.filedate >= a.begmonth
  and  b.filedate <= a.reportdate
  and ((b.logicmodule = 2 and  b.transactioncode in (208,4146,206,212,4110)) or (b.logicmodule = 4 and  b.transactioncode = 2608) or (b.logicmodule = 97 and b.transactioncode = 97))
  group by a.accountnumber,a.monthendposition


drop table workcolldb.dbo.monthly_file_mend2_desonly;
select a.*,
	   b.Net_Payment,
	   c.Other_Payment_dilutions,
	   d.Net_Spend,
	   e.net_Fees_Charges,
	   e.net_interest_charges,
	   f.spend_Fraud_dilutions
into workcolldb.dbo.monthly_file_mend2_desonly
from workcolldb.dbo.monthly_file_mend_desonly as a
left join workcolldb.dbo.monthlypayments_des as b
	on a.accountnumber = b.accountnumber 
	and a.MonthEndPosition = b.MonthEndPosition
left join workcolldb.dbo.monthlypayments2_desonly as c
	on a.accountnumber = c.accountnumber 
	and a.MonthEndPosition = c.MonthEndPosition
left join workcolldb.dbo.monthlyspend_desonly as d
    on a.accountnumber = d.accountnumber 
	and a.MonthEndPosition = d.MonthEndPosition
left join workcolldb.dbo.monthly_fees_chgs_desonly as e
    on a.accountnumber = e.accountnumber 
	and a.MonthEndPosition = e.MonthEndPosition
left join workcolldb.dbo.dilutions_fraud_check_desonly as f
    on a.accountnumber = f.accountnumber 
	and a.MonthEndPosition = f.MonthEndPosition

	--select * from workcolldb.dbo.monthly_file_mend2
	--select top 1000 * from workcolldb.dbo.Month_end_full1_ot_ch2	
/*SPEND RETAIL ONLY*/
drop table workcolldb.dbo.monthlyspend_interchange_desonly
select a.accountnumber,
		  a.monthendposition,
		  a.begmonth,
	      a.reportdate,
sum(CASE WHEN b.LogicModule IN (1,2) 
		  and b.transactiontype01 = 'D' then b.transactionamount 
    WHEN b.LogicModule IN (1,2) 
		 and b.transactiontype01 in ('C','3')
    then -1*b.transactionamount 
	else 0 end) as Net_Retail_spend
into workcolldb.dbo.monthlyspend_interchange_desonly
from workcolldb.dbo.monthly_file_mend_desonly as a
left join Firstvision.dbo.vw_i2ptpostedtransactions as b
	on a.accountnumber = b.accountnumber
	and a.begmonth <= b.filedate
    and a.reportdate >= b.filedate
where 
b.filedate >= '20200901'
AND b.LogicModule IN (1,2)
AND b.TransactionCode IN (
1,5,9,11,13,15,21,25,27,30,31,49,103,135,137,143,147,149,171,173,175,181,182,201,203,205,207,211,237,
401,407,409,411,413,419,427,439,481,941,1421,1423,2103,2177,2179,2181,2183,2185,2617,3853,4109,4141,
2,6,8,4,10,12,14,16,26,44,48,97,104,136,138,144,148,150,166,167,168,170,172,174,
180,202,204,238,353,420,428,480,942,1422,1424,2104,2178,2180,2182,2184,
2186,2528,2530,2532,2534,2560,2616,2618,2692,3906,4028,4142,4143,4144,4145,2683,2684)
and b.creditplannumber = 10002
group by a.accountnumber,a.monthendposition,a.begmonth,a.reportdate 

drop table workcolldb.dbo.monthly_interchange2_desonly
select 
*,round(Net_Retail_spend*0.003,2) as interchange
into workcolldb.dbo.monthly_interchange2_desonly
from workcolldb.dbo.monthlyspend_interchange_desonly



--select top 1000 * from workcolldb.dbo.monthlyspend_interchange2
--drop table workcolldb.dbo.monthly_update_designated
 

/*******************************************************
* SECTION 3: Payment Behaviour						   *
********************************************************/

/*FOR PAYMENT BEHAVIOUR OF THE ONLY FLAGGED DESIGNATED ACCOUNTS*/

--drop table workcolldb.dbo.pmt_behaviour_monthly
--drop table workcolldb.dbo.monthly_stat_balances
--drop table workcolldb.dbo.pmt_behaviour_monthly_des

drop table workcolldb.dbo.monthly_stat_balances
select a.*,b.currentbalance as ask_statement_balance,b.paymentcurrentdue as mpd_asked 
into workcolldb.dbo.monthly_stat_balances
from workcolldb.dbo.pmt_behaviour_monthly_des as a 
left join firstvision.dbo.vw_i2bsdaily as b
on a.accountnumber = b.accountnumber 
and a.StatementDate = b.snapshotdate
where b.snapshotdate > '20201201'

drop table workcolldb.dbo.monthly_paymentbehaviourpull_des
/* Payments */
select a.accountnumber,
	   a.monthendposition,
	   a.ask_statement_balance,
	   a.mpd_asked,
	   a.statementdate,a.paymentduedate,a.currentbalance,
      sum(CASE WHEN b.LogicModule IN (30,31) 
      and b.transactiontype01 in ('C','3') then b.transactionamount 
	  WHEN  b.LogicModule IN (30,31) 
          and b.transactiontype01 = 'D' then -1*b.transactionamount 
	  ELSE 0 end) as Net_Payment
into workcolldb.dbo.monthly_paymentbehaviourpull_des
from workcolldb.dbo.monthly_stat_balances as a
left join Firstvision.dbo.vw_I2PTPostedTransactions as b
	on a.accountnumber = b.accountnumber
    and a.StatementDate <= b.filedate
	and a.paymentduedate >= b.filedate
where 
b.filedate >= '20201201'
AND b.LogicModule IN (30,31)
AND	b.TransactionCode IN (130,131,132,133,160,161,162,163,164,165,176,177,216,217,218,219,222,223,436,1350,1351,2502,2503,2504,2505,2506,2507,2508,2509,2510,2511,2512,2514,2515,2516,
2517,2520,2521,2522,2523,2524,2525,2526,2527,2538,2540,2541,2542,2558,2559,2562,2563,2580,2581,2584,2585,2588,2589,2594,2595,2596,2597,2694,2695,4114,4132,4133,4196,
2560,2064,4994,2534,2065,2100,2532,2530,2518,2528,2065)
group by a.accountnumber,a.monthendposition,a.statementdate,a.paymentduedate,a.ask_statement_balance,a.mpd_asked,a.currentbalance
/********************************************************************/

/*******************************************************
* SECTION 4: Payment Freeze Tracking				   *
********************************************************/

DECLARE @StartDate date = DATEADD(DD,-1,DATEADD(MM,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE())))) 
DECLARE @EndDate date = (DATEADD(DD,-1,CONVERT(DATE, DATEADD(DAY, 1-DATEPART(DAY, GETDATE()), GETDATE()))))

drop table workcolldb.dbo.pfreeezecheck
SELECT a.accountnumber,c.currentbalance,b.outcome
into workcolldb.dbo.pfreeezecheck
       FROM workcolldb.dbo.designated_end as a
	   left join WorkCollDB.dbo.vw_EmergencyPaymentFreeze_Daily as b
on a.accountnumber = b.accountnumber
and convert(date,b.ReportDate) = @EndDate
 left join Firstvision.dbo.vw_i2bsbasesegmentmonthend as c
on a.accountnumber = c.accountnumber
and c.monthendposition =  LEFT(CONVERT(varchar, @EndDate,112),6)


select count(*) as volume,
		sum(currentbalance) 
from workcolldb.dbo.pfreeezecheck
where outcome = 0

select count(*) as volume,
		sum(c.currentbalance) 
from WorkCollDB.dbo.vw_EmergencyPaymentFreeze_Daily b
 left join Firstvision.dbo.vw_i2bsbasesegmentmonthend as c
on b.accountnumber = c.accountnumber
and c.monthendposition = LEFT(CONVERT(varchar, @EndDate,112),6)
where outcome = 0
AND convert(date,b.ReportDate) = @EndDate

 

/*******************************************************
* SECTION 5: Recon Activity In The End				   *
********************************************************/


  /*FOR RECON ACTIVITY IN THE END*/

 select
  sum(b.transactionamount) as spend_Fraud_dilutions
  --into workcolldb.dbo.dilutions_fraud_check
  from  firstvision.dbo.vw_i2ptpostedtransactions as b
  where  b.filedate >= '20210301'
  and  b.filedate < '20210401'
  and ((b.logicmodule = 2 and  b.transactioncode in (208,4146,206,212,4110)) or (b.logicmodule = 4 and  b.transactioncode = 2608) or (b.logicmodule = 97 and b.transactioncode = 97))
