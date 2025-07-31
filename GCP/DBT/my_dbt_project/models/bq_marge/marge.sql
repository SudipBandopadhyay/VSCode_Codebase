{{ config(
    alias='titanic_data',
    schema='dbt_bq',
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='PassengerId',
    merge_update_columns = ['Pclass', 'Sex', 'Age', 'Survived']
) }}

with titanic_data as
(
select '204' as PassengerId, 1 as Pclass, 'female' as Sex, '23' as Age, 0 as Survived 
union all
select '823' as PassengerId, 1 as Pclass, 'male' as Sex, '38' as Age, 0 as Survived 
union all
select '123' as PassengerId, 1 as Pclass, 'male' as Sex, '38' as Age, 1 as Survived 
)
select * from titanic_data