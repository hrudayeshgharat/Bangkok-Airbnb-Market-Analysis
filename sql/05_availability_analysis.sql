SELECT
    CASE
        WHEN availability_365 = 0 THEN '1 - Never available'
        WHEN availability_365 <= 30 THEN '2 - Rarely available'
        WHEN availability_365 <= 180 THEN '3 - Moderately available'
        WHEN availability_365 < 365 THEN '4 - Highly available'
        ELSE '5 - Always available'
    END AS availability_group,
    COUNT(*) AS listings,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_thb)) AS median_price_thb
FROM listings_analysis
WHERE availability_365 BETWEEN 0 AND 365
GROUP BY 1
ORDER BY 1;