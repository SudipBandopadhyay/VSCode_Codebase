



select
    1
from `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`

where not(fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge = total_amount)

