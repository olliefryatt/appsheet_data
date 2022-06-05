
-- Gather all phone numbers
with df_1 as (
select
    sim_number.uuid as uuid_phone,
    agent.uuid as uuid_agent,
    "agentName",
    "phoneNumber"
from sim_number
join agent on "agentUuid" = agent.uuid
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
from df_1
where uuid_agent in (select * from all_agents)

