
SELECT
    room_type,
    COUNT(*) AS listings,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_thb)
    ) AS median_price_thb,
    ROUND(AVG(price_thb)) AS avg_price_thb
FROM listings_analysis
GROUP BY room_type
ORDER BY listings DESC;
  