with

source as (

    -- 
    select * from `dataengineering-466011`.`dbt_raw`.`raw_stores`

),

renamed as (

    select

        ----------  ids
        id as location_id,

        ---------- text
        name as location_name,

        ---------- numerics
        tax_rate,

        ---------- timestamps
        cast(opened_at as date) as opened_date

    from source

)

select * from renamed