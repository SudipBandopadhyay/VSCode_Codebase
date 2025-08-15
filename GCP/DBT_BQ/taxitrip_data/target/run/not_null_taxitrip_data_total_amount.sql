
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_amount
from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`
where total_amount is null



  
  
      
    ) dbt_internal_test