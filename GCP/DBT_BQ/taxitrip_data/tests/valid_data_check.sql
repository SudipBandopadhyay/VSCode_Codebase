SELECT 
    payment_type,
    trip_type,
    vendorid
FROM {{ ref('taxitrip_data') }} 
WHERE payment_type = 'Invalid'
OR trip_type = 'Invalid'
OR vendorid = 'Invalid'