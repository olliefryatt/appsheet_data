/*
Note the order of col very importnat. Edits here can have big impact on final app

Objective: Have a table with all info on ABAs for feild app

*/

with df1 as (
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
df2 as (
select
	-- uuids
	uuid_agent, -- A
	uuid_aba, -- B
	-- Names, add from agent table
	agentName, -- C
	name as aba_name, -- D
	-- About the agent
	classification, -- E
	has_active_loan, -- F
	delinquencies, -- G
	transactions, -- H
	activity, -- I
	days_on_app, -- J
	"nationalId", -- K
	location_pin, -- L
	"appVersion", -- M
	email as "ABA email",  -- N, ABA email
	'NA' as "Overdue payments" -- O, Overdue payments
from df1
left join success_associate on success_associate.uuid = uuid_aba
)

select *
from df2
where "ABA email" is not null
and uuid_agent != 'fad43ce1-e967-4871-ba1b-a2da1378bd80' -- Agent has odd data so omited, they are inactice

