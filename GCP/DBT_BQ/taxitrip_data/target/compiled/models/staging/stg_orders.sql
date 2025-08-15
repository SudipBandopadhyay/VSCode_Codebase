with

source as (

    -- 
    select * from `dataengineering-466011`.`dbt_raw`.`raw_orders`

),

renamed as (

    select

        ----------  ids
        id as order_id,
        store_id as location_id,
        customer as customer_id,

        ---------- numerics
        subtotal as subtotal_cents,
        tax_paid as tax_paid_cents,
        order_total as order_total_cents,
        
    round(cast((subtotal / 100) as numeric), 2)
 as subtotal,
        
    round(cast((tax_paid / 100) as numeric), 2)
 as tax_paid,
        
    round(cast((order_total / 100) as numeric), 2)
 as order_total,

        ---------- timestamps
        cast(ordered_at as date) as order_date

    from source

)

select * from renamed