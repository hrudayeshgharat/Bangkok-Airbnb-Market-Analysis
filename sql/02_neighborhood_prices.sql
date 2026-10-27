
WITH neighborhood_stats AS (
    SELECT
        neighbourhood,
        COUNT(*) AS listings,
        ROUND(
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price_thb)
        ) AS median_price_thb
    FROM listings_analysis
    WHERE room_type = 'Entire home/apt'
    GROUP BY neighbourhood
    HAVING COUNT(*) >= 50
)
SELECT
    neighbourhood,
    listings,
    median_price_thb,
    RANK() OVER (
        ORDER BY median_price_thb DESC
    ) AS price_rank
FROM neighborhood_stats
ORDER BY price_rank, neighbourhood
LIMIT 10;
  