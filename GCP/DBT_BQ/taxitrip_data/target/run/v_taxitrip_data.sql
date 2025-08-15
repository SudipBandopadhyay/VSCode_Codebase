

  create or replace view `dataengineering-466011`.`taxitrip_data`.`v_taxitrip_data`
  OPTIONS()
  as WITH
source AS (
    select 
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
    FROM `dataengineering-466011`.`taxitrip_data`.`taxitrip_data` 
)
SELECT * FROM source;

