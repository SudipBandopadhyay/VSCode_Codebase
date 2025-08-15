

    
    

with all_values as (

    select
        payment_type as value_field,
        count(*) as n_records

    from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`
    group by payment_type

)

select *
from all_values
where value_field not in (
    'Flex Fare trip','Credit card','Cash','No charge','Dispute','Unknown','Voided trip'
)


