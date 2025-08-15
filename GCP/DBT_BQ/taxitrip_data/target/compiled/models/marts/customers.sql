with
cleaned_data AS(
SELECT 
* 
FROM `dataengineering-466011.taxitrip_data.taxitrip_data_raw` 
WHERE VendorID IS NOT NULL
AND store_and_fwd_flag IS NOT NULL
AND passenger_count IS NOT NULL
AND RatecodeID  IS NOT NULL
)
select * from cleaned_data