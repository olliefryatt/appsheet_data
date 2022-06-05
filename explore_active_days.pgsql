
-- This is a script to help understand the structure of the db.

-- 1. User kyc table (Airtable)
with airtable as (
    -- Recreats all kyc info behind one agent. 
    -- Data is 'long'  as rather than all infomation in one row it has one row per agnet phone to_number
    select 
        "agentName",
        "nationalId",   	
        name as asa_name,
        sim_number."phoneNumber" as phoneNumber_airtable,
        "agent"."createdAt" as createdAt_airtable,
        -- uuid refrences
        "agent".uuid as uuid_agent_airtable,         -- Unique refrence for the agent (from airtable)   
        "asaUuid" as uuid_asa_airtable,              -- Unique refrence for the ASA (from airtable)
        sim_number."uuid" as uuid_sim_airtable  -- Unique refrence for phone number listed to a agent (from airtable)
    from "agent"
    left join success_associate on success_associate.uuid = "agent"."asaUuid"
    left join sim_number on sim_number."agentUuid" = "agent".uuid
    order by "agentName"
),

-- 2. Combine user data with user table
--      This query combines the airtable data with the "user" table on the db
--      Airtable refrences that have no joins to the user table indicate the agent was logged on the airtable but never used the app with registered phone numbers 
df_1 as (
    select
        "agentName",
        "nationalId",   	
        asa_name,
        phoneNumber_airtable,
        public.user."phoneNumber" as phoneNumber_db,
        -- Date refrences
        createdAt_airtable,
        "createdAt" as createdAt_userTable,
        "updatedAt" as updatedAt_userTable,
        -- uuid refrences
        uuid_agent_airtable, 
        uuid_asa_airtable,
        uuid_sim_airtable,
        uuid as uuid_sim_userDb
    from airtable
    left join public.user on public.user."phoneNumber" = airtable.phoneNumber_airtable
    order by uuid_agent_airtable
),

--3. Combine with transactions table
df_2 as (   
    select 
        -- From previous tables
        "agentName",
        "nationalId",   	
        asa_name,
        phoneNumber_airtable,
        phoneNumber_db,
        createdAt_airtable,
        createdAt_userTable, -- If NULL then this number hasn't used the app
        --updatedAt_userTable,
        -- uuid refrences
        uuid_agent_airtable, 
        uuid_asa_airtable,
        uuid_sim_airtable,
        uuid_sim_userDb,
        public.transaction.uuid as uuid_tran_tranDb, -- Unique refrence for each transaciton done
        -- From transaction table
        mobile as mobile_tranDb,
        status as status_tranDb,
        category as category_tranDb,
        telco as telco_tranDb,
        location as location_tranDb,
        "clientName" as clientName_tranDb,
        to_timestamp("requestTimestamp" / 1000)::date AS requestTimestamp_tranDb
    from df_1
    left join public.transaction on public.transaction."userUuid" = df_1.uuid_sim_userDb
    order by to_timestamp("requestTimestamp" / 1000)::date
)

select *
from df_2
where uuid_agent_airtable = '1cceea39-2d85-4d56-8698-08e650c5fe56'
and date_trunc('month',requestTimestamp_tranDb) = date_trunc('month','2009-03-03')