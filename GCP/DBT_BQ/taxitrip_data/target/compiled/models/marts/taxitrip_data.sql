WITH
  cleaned_data AS(
SELECT 
  GENERATE_UUID() AS trip_id,
  CASE WHEN vendorid = 1 THEN 'Creative Mobile Technologies, LLC' 
    WHEN vendorid = 2 THEN 'Curb Mobility, LLC'
    WHEN vendorid = 6 THEN 'Myle Technologies Inc'
    WHEN vendorid = 7 THEN 'Helix'
    ELSE 'Invalid'
  END AS vendorid,
  lpep_pickup_datetime,
  lpep_dropoff_datetime,
  store_and_fwd_flag,
  ratecodeid,
  pulocationid,
  dolocationid,
  passenger_count,
  trip_distance,
  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  ehail_fee,
  improvement_surcharge,
  total_amount,
  CASE WHEN payment_type = 0 THEN 'Flex Fare trip'
    WHEN payment_type = 1 THEN 'Credit card'
    WHEN payment_type = 2 THEN 'Cash'
    WHEN payment_type = 3 THEN 'No charge'
    WHEN payment_type = 4 THEN 'Dispute'
    WHEN payment_type = 5 THEN 'Unknown'
    WHEN payment_type = 6 THEN 'Voided trip'
    ELSE 'Invalid'
  END AS payment_type,
  CASE WHEN trip_type = 1 THEN 'Street-hail'
    WHEN trip_type = 2 THEN 'Dispatch'
    ELSE 'Invalid'
  END AS trip_type,
  congestion_surcharge
  FROM taxitrip_data_raw 
  WHERE VendorID IS NOT NULL
  AND store_and_fwd_flag IS NOT NULL
  AND passenger_count IS NOT NULL
  AND RatecodeID  IS NOT NULL
  AND total_amount > 0
  AND fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge = total_amount
)
SELECT 
  trip_id,
  vendorid,
  lpep_pickup_datetime,
  lpep_dropoff_datetime,
  store_and_fwd_flag,
  ratecodeid,
  pulocationid,
  dolocationid,
  passenger_count,
  trip_distance,
  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  improvement_surcharge,
  total_amount,
  payment_type,
  trip_type,
  congestion_surcharge 
FROM cleaned_data