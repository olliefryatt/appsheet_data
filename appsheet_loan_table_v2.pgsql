-- Loan infomation for Feild App

/*

Objective 
- is to have a loan table that we can push to ABAs via the feild app
- Every row needs to asingle loan

Key infomation to have per loan (row)

TO-DO

BLOCKED
- Yes/No is loan finished
- Cumulative paid expected,  by today
- Amount due on loan (if any)

DONE
- uuid : ABA manging loan
- Cumulative paid actual, by today
- weekly amount due
- uuid : agent who owns loan
- uuid : of loan
- loan amount
- Loan start date
- Loan end date
- Loan duration in months
- Monthly interest

Data tables used in this analysis

(A) loan_payment
• Payments row by row to loan (one loan can have many rows/payments assigned to it)

(B) staging.loan_repayment_schedule
• Expected payments on loan
• Each row is day by evolution of the loan (e..g one loan can take up 90 rows)
• Look at cumulative col to see expected amount due on loan at given date 

(C) loan
• Basic loan details
• Each row is 1 loan, has key info on that loan

*/

-- 1. Start with all loans & show the ABA managing loan
with df_1 as (
	select 
		loan.uuid as uuid_loan,
		*
	from loan
	left join public.agent on loan."agentUuid" = public.agent."uuid" -- 
	where loan."uuid" in (
		'b9f9450f-317b-49a7-b4f4-34bb6f3e1b32',
		'3a7e715a-575b-4de2-9018-0dcafd9b3ddb') 
	or "loanId" in (
		'0184',
		'0469')
),

-- 2. Take all payments made to these loans
df_2 as (
	select
		"loanUuid",
		round(sum(amount)) as total_paid
	from loan_payment
	where "loanUuid" in (
		'b9f9450f-317b-49a7-b4f4-34bb6f3e1b32',
		'3a7e715a-575b-4de2-9018-0dcafd9b3ddb')
	group by "loanUuid"
),

-- 3. Calculate expected payment amounts BLOCKED
-- BLOCKED here as not sure if the 'loan_repayment_schedule' table is being updated.
df_3 as (
	select
		Loan_id,
		round(max(owed)) as total_expected_to_be_paid,
		max(date(date_gs)) as todays_date, -- REVIEW
		max((date(date_gs) - date(start_date))/7) as latest_payment_due_number -- REVIEW
	from staging.loan_repayment_schedule
	where Loan_id in (
		'b9f9450f-317b-49a7-b4f4-34bb6f3e1b32',
		'3a7e715a-575b-4de2-9018-0dcafd9b3ddb')
	and date_gs <= CURRENT_DATE
	-- THINK ABOUT add join with df_1 & additional filter on taking dates less loan
	group by 1
),

-- Final Data frame
df_final as (
	select
		-- Identifiers
		df_1.uuid_loan,
		df_1."asaUuid" as uuid_aba,
		df_1."agentUuid" as uuid_agent,
		-- Loan details
		df_1."loanId",
		df_1."loanAmount" as principal_borrowed,
		df_1."durationInMonths",
		df_1."monthlyInterest",
		df_1."startDate",
		df_1."endDate",
		df_2.total_paid as total_paid_to_date
	from df_1
	left JOIN df_2 on df_2."loanUuid" = df_1.uuid_loan
)

select *
from df_final



















-- 1. All loans & total payments to those loans
with loan_payments as ( 
	  select  
        "loanUuid" as loan_id, 
	  	date(max(date)) as last_payment_day,
        --sum(case when type = 'repayment' then amount else 0 end) as total_repayments, 
 	    --sum(case when type = 'penalty'  then amount else 0 end) as total_penalty,
		round(sum(amount)) as total_paid
 	  from loan_payment 
 	  where type = 'repayment'
 	  group by 1
 ), 

 -- 2. loans
latest_payment_due as (
 	select 
        lps.loan_id, 
 		max(date(date_gs)) as latest_payment_due, 
        max((date(date_gs) - date(start_date))/7) as latest_payment_due_number, 
        max(owed) as cum_expected
 	from staging.loan_repayment_schedule lps 
 	left join loan l on l.uuid = lps.loan_id
 	where (date(date_gs) - date(start_date)) % 7 = 0
 	and date_gs <= CURRENT_DATE
 	and date_gs <= "endDate"
 	group by 1
), 
 
latest_payment_missed as (
 	select 
	 	lrs.loan_id,	
 		min(date(date_gs)) as latest_payment_missed, 
        min((date(date_gs) - date(start_date))/7) as latest_payment_missed_number
 	from staging.loan_repayment_schedule lrs 
 	left join loan_payments lpd on lpd.loan_id = lrs.loan_id
 	left join loan l on l.uuid = lrs.loan_id
 	where (date(date_gs) - date(start_date)) % 7 = 0 
 	and date_gs <= CURRENT_DATE
 	and coalesce(total_paid,0) < owed
 	and date_gs <= "endDate"
 	group by 1
) 

,

all_loans as (
select
	-- Uuid Refrences
	lp."loan_id" as uuid_loan,
	l."agentUuid" as uuid_agent,
	aba.uuid as uuid_aba,
	-- Agent & ABA name
	a."agentName", 
	aba.name as aba_name, 
	-- Loan ($)
	l."loanId",
	l."loanAmount",
	round("loanAmount"*(1+ (0.05*"durationInMonths"))) as amount_due, 
	round(coalesce(total_paid,0)) as cum_paid, 
	round(coalesce(lpd.cum_expected,0)) as cum_expected,
	-- Dates
	l."startDate" as loan_start_date,
	l."endDate" as loan_end_date,
	l."durationInMonths",
	l."monthlyInterest" / 100 as monthlyInterest,
	-- t.*,  
	lpd.latest_payment_due,
	lpd.latest_payment_due_number, 
	lpm.latest_payment_missed,
	lpm.latest_payment_missed_number, 
	case when l.uuid is not null then row_number() over (partition by l."agentUuid" order by l."startDate") end as loan_cycle
	--lp.* 
from loan l 
left join agent a on a.uuid = l."agentUuid"
left join loan_payments lp on lp.loan_id = l.uuid
-- left join agent_sims as sim on sim.agent_id = l."agentUuid"
-- left join transactions as t on t.agent_id_t = a.uuid
left JOIN success_associate aba ON a."asaUuid" = aba.uuid
left join latest_payment_due lpd on lpd.loan_id = l.uuid
left join latest_payment_missed lpm on lpm.loan_id = l.uuid
),


-- Will filter to only have loans associated with agents actively managed by ABAs
-- Source are ABA's associated with clients outlines on the "user_metrics_today" table
all_agents as (
select
	DISTINCT(unique_id) as uuid_agent_distinct -- Note they shoudl alreayd all be distinct in this table
from metrics.user_metrics_today
--left join agent on metrics.user_metrics_today.unique_id = agent.uuid
)

select *
from all_loans
where uuid_agent in (select * from all_agents)
