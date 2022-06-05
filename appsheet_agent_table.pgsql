with df1 as (
select
	-- uuids
	unique_id as uuid_agent,
	agent."asaUuid" as uuid_aba,
	-- Names, add from agent table
	"agentName" as agentName,
	-- About the agent
	classification_last,
	has_active_loan_last,
	delinquencies_last,
	transactions_last,
	activity_last,
	age as days_on_app,
	"nationalId"
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
	"nationalId"
from df1
left join success_associate on success_associate.uuid = uuid_aba
)

select *
from df2

