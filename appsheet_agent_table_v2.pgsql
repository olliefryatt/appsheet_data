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
	classification_last, -- Should be agent's most recent category
	has_active_loan_last, -- 1 = yes, has active loan
	delinquencies_last, -- Not clear what this is / is useful
	transactions_last, -- think this is transactions in last 28 days?
	activity_last, -- think this is % acticve in last 28 days?
	age as days_on_app,
	"nationalId",
	"appVersion",
	St_AsText("lastLocation") as location_pin
from metrics.user_metrics_today
left join agent on metrics.user_metrics_today.unique_id = agent.uuid
),

-- Add ABA name
df2 as (
select
	-- uuids
	uuid_agent,
	uuid_aba,
	-- Names, add from agent table
	agentName,
	name as aba_name,
	-- About the agent
	classification_last,
	has_active_loan_last,
	delinquencies_last,
	transactions_last,
	activity_last,
	days_on_app,
	"nationalId",
	location_pin,
	"appVersion"
from df1
left join success_associate on success_associate.uuid = uuid_aba
)

select *
from df2
