
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select vendorid
from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`
where vendorid is null



  
  
      
    ) dbt_internal_test