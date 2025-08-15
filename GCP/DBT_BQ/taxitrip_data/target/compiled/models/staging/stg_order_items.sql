with

source as (

    -- 
    select * from `dataengineering-466011`.`dbt_raw`.`raw_items`

),

renamed as (

    select

        ----------  ids
        id as order_item_id,
        order_id,
        sku as product_id

    from source

)

select * from renamed