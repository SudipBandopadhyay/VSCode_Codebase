
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  

    
    

with all_values as (

    select
        vendorid as value_field,
        count(*) as n_records

    from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`
    group by vendorid

)

select *
from all_values
where value_field not in (
    'Creative Mobile Technologies, LLC','Curb Mobility, LLC','Myle Technologies Inc','Helix'
)



  
  
      
    ) dbt_internal_test