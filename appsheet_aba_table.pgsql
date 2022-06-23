select
    uuid as uuid_aba,
    name,
    email as "aba_email"
from success_associate
where email is not null
