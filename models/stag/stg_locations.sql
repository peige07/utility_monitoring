{{config(matalized = 'view')}}

SELECT
*
FROM {{source('dbt_source', 'locations')}}