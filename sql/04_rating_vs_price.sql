
SELECT
    CASE
        WHEN review_score IS NULL
            THEN '0 - No reviews'
        WHEN review_score < 4.5
            THEN '1 - Below 4.5'
        WHEN review_score < 4.8
            THEN '2 - 4.5 to 4.79'
        ELSE '3 - 4.8 and above'
    END AS rating_band,
    COUNT(*) AS listings,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_thb)
    ) AS median_price_thb
FROM listings_analysis
WHERE room_type = 'Entire home/apt'
GROUP BY 1
ORDER BY 1;
  