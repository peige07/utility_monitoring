{{config(materialized = 'view')}}

SELECT
*
FROM {{source('dbt_source','utility_bills')}}