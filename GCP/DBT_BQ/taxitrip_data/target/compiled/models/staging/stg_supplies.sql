with

source as (

    -- 
    select * from `dataengineering-466011`.`dbt_raw`.`raw_supplies`

),

renamed as (

    select

        ----------  ids
        to_hex(md5(cast(coalesce(cast(id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sku as string), '_dbt_utils_surrogate_key_null_') as string))) as supply_uuid,
        id as supply_id,
        sku as product_id,

        ---------- text
        name as supply_name,

        ---------- numerics
        
    round(cast((cost / 100) as numeric), 2)
 as supply_cost,

        ---------- booleans
        perishable as is_perishable_supply

    from source

)

select * from renamed