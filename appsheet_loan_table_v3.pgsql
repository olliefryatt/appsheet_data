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
		RIGHT(CONCAT(df_1."agentUuid"),5) as uuid_agent,
		df_1."asaUuid" as uuid_aba, -- C
		-- Loan details
		agent."agentName" as "Agent", -- D
		success_associate.name as "ABA", -- E
        status as "Loan status", 
		df_1."loanId" as "Loan ID", -- F 
		round(df_1."loanAmount",0) as "Loan principal", -- G
		COALESCE((df_3.total_expected_to_be_paid - COALESCE(df_2.total_paid,0)),0) as "Overdue", -- H
		COALESCE(df_2.total_paid,0) as "Paid to date", -- I 
		COALESCE(df_3.total_expected_to_be_paid,0) as "Total expected ", -- J , better name >> total_expected_to_be_paid,
		df_1."startDate" as "Loan start date", -- k 
		df_1."endDate" as "Loan end", -- L 
		df_1."durationInMonths" as "Duration in months", -- M
		round(df_1."monthlyInterest" / 100, 2) as "Monthly interest", -- N
		email as "ABA email" -- T
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
and "Loan ID" != '0089'
-- >> If status = ontime then overdue = 0 
-- Nice
-- Should add a new col "total amount expected end of loan"