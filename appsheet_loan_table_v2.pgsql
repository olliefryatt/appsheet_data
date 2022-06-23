/*
Objective 
- is to have a loan table that we can push to ABAs via the feild app
- Every row needs to asingle loan
*/

-- 1. Start with all loans & show the Agent to whom that loan has been made
with df_1 as (
	select 
		loan.uuid as uuid_loan,
		*
	from loan
	left join public.agent on loan."agentUuid" = public.agent."uuid"
),

-- 2. Take all payments made to these loans
-- 
df_2 as (
	select
		"loanUuid",
		round(sum(amount)) as total_paid
	from loan_payment
	group by "loanUuid"
),

-- 3. Calculate expected payment amounts per loan
df_3 as (
	select
		Loan_id,
		round(max(owed)) as total_expected_to_be_paid,
		max(date(date_gs)) as todays_date,
		max((date(date_gs) - date(start_date))/7) as latest_payment_due_number
	from metrics.loan_repayment_schedule
	where date_gs <= CURRENT_DATE
	group by 1
),

-- Final Data frame
df_final as (
	select
		-- Identifiers
		df_1.uuid_loan, -- A
		df_1."agentUuid" as uuid_agent, -- B
		df_1."asaUuid" as uuid_aba, -- C
		-- Loan details
		agent."agentName" as agentName, -- D
		success_associate.name as aba_name, -- E 
		df_1."loanId", -- F 
		df_1."loanAmount" as loanAmount, -- G
		COALESCE((df_3.total_expected_to_be_paid - COALESCE(df_2.total_paid,0)),0) as amount_due, -- H
		COALESCE(df_2.total_paid,0) as cum_paid, -- I , better name >> total_paid_to_date
		COALESCE(df_3.total_expected_to_be_paid,0) as cum_expected, -- J , better name >> total_expected_to_be_paid,
		df_1."startDate" as loan_start_date, -- k 
		df_1."endDate" as loan_end_date, -- L 
		df_1."durationInMonths", -- M
		df_1."monthlyInterest" / 100 as monthlyInterest, -- N
		'NA' as latest_payment_due,  -- O -- Should remove this col in future, however, required for appsheet table
		COALESCE(df_3.latest_payment_due_number,0) as latest_payment_due_number, -- P
		'NA' as latest_payment_missed, -- Q
		'NA' as latest_payment_missed_number, -- R
		'NA' as loan_cycle, -- S
		email as "ABA email", -- T
		status as "Loan status"
	from df_1
	left JOIN df_2 on df_2."loanUuid" = df_1.uuid_loan
	left join df_3 on df_3.Loan_id = df_1.uuid_loan
	left join agent on agent.uuid = df_1."agentUuid"
	left join success_associate on success_associate."uuid" = df_1."asaUuid"
)

select *
from df_final
where "ABA email" is not null 
-- Remove odd loans
and "loanId" != '0089'
-- >> If status = ontime then overdue = 0 

-- Nice
-- Should add a new col "total amount expected end of loan"



