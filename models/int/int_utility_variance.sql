WITH cte1 AS(SELECT
account_id,
LAG(reporting_month) OVER(PARTITION BY account_id ORDER BY reporting_month) lagmonth,
reporting_month,
DATEDIFF('MONTH',LAG(reporting_month) OVER(PARTITION BY account_id ORDER BY reporting_month),
reporting_month) monthdiff,
SUM(CASE WHEN TRIM(LOWER(bill_type)) IN ('regular','final')
AND TRIM(LOWER(bill_status)) != 'void' THEN usage ELSE NULL END) total_usage,
SUM(CASE WHEN TRIM(LOWER(bill_status)) != 'void' THEN cost ELSE NULL END) total_cost
FROM {{ref('stg_utility_bills')}}
GROUP BY account_id, reporting_month)

, cte2 AS(SELECT
*,
    CASE WHEN monthdiff = 1
    THEN LAG(total_cost) OVER(PARTITION BY account_id ORDER BY reporting_month)
    ELSE NULL
    END prior_cost,
    CASE WHEN monthdiff = 1
    THEN LAG(total_usage) OVER(PARTITION BY account_id ORDER BY reporting_month)
    ELSE NULL
    END prior_usage
FROM cte1)

, cte3 AS(
SELECT
*,
total_cost - prior_cost AS MoMcostchange,
total_usage - prior_usage AS MoMusagechange,
(total_cost - prior_cost) / NULLIF(prior_cost,0) *100 costchangepct,
(total_usage - prior_usage) / NULLIF(prior_usage, 0) *100 usagechangepct
FROM cte2)

SELECT
cur.*,
pre.total_usage previous_usage,
pre.total_cost previous_cost,
cur.total_usage - pre.total_usage usage_change,
cur.total_cost - pre.total_cost cost_change,
(cur.total_usage - pre.total_usage) / NULLIF(pre.total_usage,0) *100 usagepct,
(cur.total_cost - pre.total_cost) / NULLIF(pre.total_cost, 0) *100 costpct
FROM cte3 cur
LEFT JOIN cte3 pre
ON cur.account_id = pre.account_id
AND pre.reporting_month = cur.reporting_month - INTERVAL '1 YEAR'