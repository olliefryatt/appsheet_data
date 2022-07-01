select
    uuid as uuid_aba,
    name as "ABA",
    email as "ABA email"
from success_associate
where email is not null
