{{ config(
    schema='taxitrip_data_final',
) }}


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
    {{ ref('v_taxitrip_data') }}
    WHERE trip_type = 'Street-hail'
)
SELECT 
    trip_id,
    vendorid,
    ratecodeid,
    passenger_count,
    trip_distance,
    trip_time_minute,
    {{ trip_length('trip_time_minute') }} AS trip_length,
    total_amount,
    payment_type
FROM source