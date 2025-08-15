

    
    

with all_values as (

    select
        trip_type as value_field,
        count(*) as n_records

    from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`
    group by trip_type

)

select *
from all_values
where value_field not in (
    'Street-hail','Dispatch'
)


