
SELECT
    is_superhost,
    COUNT(*) AS listings,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_thb)
    ) AS median_price_thb,
    COUNT(review_score) AS rated_listings,
    ROUND((
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY review_score)
    )::numeric, 2) AS median_rating,
    ROUND(AVG(number_of_reviews), 1) AS avg_reviews
FROM listings_analysis
WHERE room_type = 'Entire home/apt'
GROUP BY is_superhost
ORDER BY is_superhost;
  