/*
Note the order of col very importnat. Edits here can have big impact on final app

Objective: Have a table with all info on ABAs for feild app

*/

------------------ Take loan table, as we need overude payment_date
------------------ Copy appshet_loan_table_v3


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
		agent."agentName" as "Agent", -- D
		success_associate.name as "ABA", -- E 
		df_1."loanId" as "Loan ID", -- F 
		round(df_1."loanAmount",0) as "Loan principal", -- G
		COALESCE((df_3.total_expected_to_be_paid - COALESCE(df_2.total_paid,0)),0) as "Overdue", -- H
		COALESCE(df_2.total_paid,0) as "Paid to date", -- I 
		COALESCE(df_3.total_expected_to_be_paid,0) as "Total expected ", -- J , better name >> total_expected_to_be_paid,
		df_1."startDate" as "Loan start date", -- k 
		df_1."endDate" as "Loan end", -- L 
		df_1."durationInMonths" as "Duration in months", -- M
		round(df_1."monthlyInterest" / 100, 2) as "Monthly interest", -- N
		email as "ABA email", -- T
		status as "Loan status"
	from df_1
	left JOIN df_2 on df_2."loanUuid" = df_1.uuid_loan
	left join df_3 on df_3.Loan_id = df_1.uuid_loan
	left join agent on agent.uuid = df_1."agentUuid"
	left join success_associate on success_associate."uuid" = df_1."asaUuid"
),



-- Make this table for agents table
df_final_overdue as (
    select *
    from df_final
    where "ABA email" is not null 
    -- Remove odd loans
    and "Loan ID" != '0089'
),

df_final_overdue_1 as (
    select 
        sum("Overdue") as "Overdue payments",
        uuid_agent,
        uuid_aba
    from df_final_overdue
    group by uuid_agent, uuid_aba
),


------------------ Agent data

df1_agent as (
select
	-- uuids
	unique_id as uuid_agent,
	agent."asaUuid" as uuid_aba,
	-- Names, add from agent table
	"agentName" as agentName,
	-- About the agent
	classification,
	has_active_loan,
	delinquencies,
	transactions,
	activity,
	age as days_on_app,
	"nationalId",
	"appVersion",
	CASE 
		WHEN "lastLocation" IS NULL THEN ''
		ELSE CONCAT(ST_Y("lastLocation"), ',', ST_X("lastLocation"))
		END AS location_pin
from metrics.user_metrics_today
left join agent on metrics.user_metrics_today.unique_id = agent.uuid
),

-- Add ABA name
df2_agent as (
select
	-- uuids
	uuid_agent, -- A
	uuid_aba, -- B
	-- Names, add from agent table
	agentName as "Agent", -- C
	name as "ABA", -- D
	-- About the agent
	classification as "Classification", -- E
	has_active_loan as "Has actice loan", -- F
	delinquencies as "Delinquencies", -- G
	transactions as "Transactions", -- H
	activity as "Activity", -- I
	days_on_app as "Days on app", -- J
	"nationalId" as "National ID", -- K
	location_pin as "Pin", -- L
	"appVersion" as "App version", -- M
	email as "ABA email"  -- N, ABA email
from df1_agent
left join success_associate on success_associate.uuid = uuid_aba
),


df_f as (
    select *
    from df2_agent
    where "ABA email" is not null
    and uuid_agent != 'fad43ce1-e967-4871-ba1b-a2da1378bd80' -- Agent has odd data so omited, they are inactice
)

select
    RIGHT(CONCAT(df_f.uuid_agent),5) as uuid_agent,
    df_f.uuid_aba as "uuid_aba",
    "Agent",
    "ABA",
    "Classification",
    "Overdue payments",
    "Has actice loan",
    "Delinquencies",
    "Transactions",
    "Activity",
    "Days on app",
    "National ID",
    "Pin",
    "App version",
    "ABA email"
from df_f
left join df_final_overdue_1 on df_f.uuid_agent = df_final_overdue_1.uuid_agent
