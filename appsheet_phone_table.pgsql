
-- Gather all phone numbers
with df_1 as (
    select
        sim_number.uuid as uuid_phone,
        agent.uuid as uuid_agent,
        "asaUuid" as uuid_aba,
        "agentName",
        "phoneNumber"
        --
    from sim_number
    join agent on "agentUuid" = agent.uuid
),

-- Add ABA email
df_2 as (
    select 
        uuid_phone,
        CONCAT('A',RIGHT(CONCAT(uuid_agent),5)) as uuid_agent,
        uuid_aba,
        "agentName" as "Agent",
        df_1."phoneNumber" as "Phone number",
        email as "ABA email"
    from df_1
    join success_associate on df_1.uuid_aba = success_associate.uuid
)

select *
from df_2
where "ABA email" is not null

