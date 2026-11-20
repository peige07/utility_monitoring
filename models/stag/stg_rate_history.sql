{{config(materialized = 'view')}}

SELECT
*
FROM {{source('dbt_source', 'rate_history')}}