SELECT 
    payment_type,
    trip_type,
    vendorid
FROM `dataengineering-466011`.`taxitrip_data`.`taxitrip_data` 
WHERE payment_type = 'Invalid'
OR trip_type = 'Invalid'
OR vendorid = 'Invalid'