

-- expected amount paid
	select
		Loan_id,
		round(max(owed)) as total_expected_to_be_paid,
		max(date(date_gs)) as todays_date,
		max((date(date_gs) - date(start_date))/7) as latest_payment_due_number
	from metrics.loan_repayment_schedule
	where date_gs <= CURRENT_DATE
    and "loan_id" = '3a9a3330-8e2c-4c1e-ba77-696e8dccc6ad'
	group by 1

select 
    ROW_NUMBER() OVER (ORDER BY "loan_id" DESC) AS ID,
    date_gs,
    owed,
    *
from metrics.loan_repayment_schedule
where "loan_id" = '3a9a3330-8e2c-4c1e-ba77-696e8dccc6ad'
