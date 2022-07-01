---AGENTS AND THEIR LOANS 

with loan_payments as ( 
	  select  "loanUuid" as loan_id, 
	  			   date(max(date)) as last_payment_day,
-- 	  			   sum(case when type = 'repayment' then amount else 0 end) as total_repayments, 
-- 	  			   sum(case when type = 'penalty'  then amount else 0 end) as total_penalty,
				   round(sum(amount)) as total_paid

 	  from loan_payment 
 	  where type = 'repayment'
 	  group by 1
 ) 
 , 
 
--  transactions as (
--  	select "agentUuid" as agent_id_t, count(*) as nun_transactions
--  	from transaction t 
--  	left join public.user as u on t."userUuid" = u.uuid  
--  	
--  	where status = 'succeeded'
--  	group by 1 
--  ), 
 
latest_payment_due as (
 	select lps.loan_id, 
 			max(date(date_gs)) as latest_payment_due, 
            max((date(date_gs) - date(start_date))/7) as latest_payment_due_number, 
            max(owed) as cum_expected
            
 	from staging.loan_repayment_schedule lps 
 	left join loan l on l.uuid = lps.loan_id
 	where 
 	(date(date_gs) - date(start_date)) % 7 = 0 
 	and date_gs <= CURRENT_DATE
 	and date_gs <= "endDate"
 	group by 1
) 

, 
 
latest_payment_missed as (
 	
 	select lrs.loan_id,	
 		   min(date(date_gs)) as latest_payment_missed, 
           min((date(date_gs) - date(start_date))/7) as latest_payment_missed_number
           
 	from staging.loan_repayment_schedule lrs 
 	left join loan_payments lpd on lpd.loan_id = lrs.loan_id
 	left join loan l on l.uuid = lrs.loan_id
 	where 
 	(date(date_gs) - date(start_date)) % 7 = 0 
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
