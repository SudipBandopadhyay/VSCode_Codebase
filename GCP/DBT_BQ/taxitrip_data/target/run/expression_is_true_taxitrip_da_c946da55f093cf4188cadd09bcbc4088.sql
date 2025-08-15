
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`

where not(fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge = total_amount)


  
  
      
    ) dbt_internal_test