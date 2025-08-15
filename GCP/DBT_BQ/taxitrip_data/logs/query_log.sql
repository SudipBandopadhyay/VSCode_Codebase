-- created_at: 2025-08-14T14:41:15.749483300+00:00
-- dialect: bigquery
-- node_id: not available
-- desc: Ensure schema exists
CREATE SCHEMA IF NOT EXISTS `dataengineering-466011.taxitrip_data`;
-- created_at: 2025-08-14T14:41:15.757310500+00:00
-- dialect: bigquery
-- node_id: not available
-- desc: Ensure schema exists
CREATE SCHEMA IF NOT EXISTS `dataengineering-466011.taxitrip_data_final`;
-- created_at: 2025-08-14T14:41:17.792377500+00:00
-- dialect: bigquery
-- node_id: not available
-- desc: Get table schema
SELECT column_name, data_type, is_nullable FROM `dataengineering-466011`.taxitrip_data.INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'taxitrip_data_raw' UNION ALL SELECT * FROM (SELECT '', '', '' FROM `dataengineering-466011`.taxitrip_data.taxitrip_data_raw LIMIT 0);
-- created_at: 2025-08-14T14:41:21.244882+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.taxitrip_data
-- desc: get_relation adapter call
SELECT table_catalog,
                    table_schema,
                    table_name,
                    table_type
                FROM `dataengineering-466011`.`taxitrip_data`.INFORMATION_SCHEMA.TABLES
                WHERE table_name = 'taxitrip_data';
-- created_at: 2025-08-14T14:41:24.494265+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.taxitrip_data
-- desc: execute adapter call

  
    

    create or replace table `dataengineering-466011`.`taxitrip_data`.`taxitrip_data`
      
    
    

    OPTIONS()
    as (
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
  FROM taxitrip_data.taxitrip_data_raw
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
    );
  ;
-- created_at: 2025-08-14T14:41:31.736299300+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.v_taxitrip_data
-- desc: get_relation adapter call
SELECT table_catalog,
                    table_schema,
                    table_name,
                    table_type
                FROM `dataengineering-466011`.`taxitrip_data`.INFORMATION_SCHEMA.TABLES
                WHERE table_name = 'v_taxitrip_data';
-- created_at: 2025-08-14T14:41:34.673556900+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.v_taxitrip_data
-- desc: execute adapter call


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

;
-- created_at: 2025-08-14T14:41:37.906331800+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.taxitrip_data_street_hail
-- desc: get_relation adapter call
SELECT table_catalog,
                    table_schema,
                    table_name,
                    table_type
                FROM `dataengineering-466011`.`taxitrip_data_final`.INFORMATION_SCHEMA.TABLES
                WHERE table_name = 'taxitrip_data_street_hail';
-- created_at: 2025-08-14T14:41:37.910023100+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.taxitrip_data_dispatch
-- desc: get_relation adapter call
SELECT table_catalog,
                    table_schema,
                    table_name,
                    table_type
                FROM `dataengineering-466011`.`taxitrip_data_final`.INFORMATION_SCHEMA.TABLES
                WHERE table_name = 'taxitrip_data_dispatch';
-- created_at: 2025-08-14T14:41:41.960190700+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.taxitrip_data_dispatch
-- desc: execute adapter call

  
    

    create or replace table `dataengineering-466011`.`taxitrip_data_final`.`taxitrip_data_dispatch`
      
    
    

    OPTIONS()
    as (
      

WITH source AS
(
    SELECT
        trip_id,
        vendorid,
        ratecodeid,
        passenger_count,
        trip_distance,
        ROUND(TIMESTAMP_DIFF(lpep_dropoff_datetime, lpep_pickup_datetime, SECOND)/60,2) AS trip_time_minute,
        total_amount,
        payment_type
    FROM
    `dataengineering-466011`.`taxitrip_data`.`v_taxitrip_data`
    WHERE trip_type = 'Dispatch'
)
SELECT 
    trip_id,
    vendorid,
    ratecodeid,
    passenger_count,
    trip_distance,
    trip_time_minute,
    CASE WHEN trip_time_minute<10 THEN 'Short' ELSE 'Long' END AS trip_length,
    total_amount,
    payment_type
FROM source
    );
  ;
-- created_at: 2025-08-14T14:41:41.960748300+00:00
-- dialect: bigquery
-- node_id: model.taxitrip_data.taxitrip_data_street_hail
-- desc: execute adapter call

  
    

    create or replace table `dataengineering-466011`.`taxitrip_data_final`.`taxitrip_data_street_hail`
      
    
    

    OPTIONS()
    as (
      


WITH source AS
(
    SELECT
        trip_id,
        vendorid,
        ratecodeid,
        passenger_count,
        trip_distance,
        ROUND(TIMESTAMP_DIFF(lpep_dropoff_datetime, lpep_pickup_datetime, SECOND)/60,2) AS trip_time_minute,
        total_amount,
        payment_type
    FROM
    `dataengineering-466011`.`taxitrip_data`.`v_taxitrip_data`
    WHERE trip_type = 'Street-hail'
)
SELECT 
    trip_id,
    vendorid,
    ratecodeid,
    passenger_count,
    trip_distance,
    trip_time_minute,
    CASE WHEN trip_time_minute<10 THEN 'Short' ELSE 'Long' END AS trip_length,
    total_amount,
    payment_type
FROM source
    );
  ;
