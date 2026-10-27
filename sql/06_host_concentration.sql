
-- Query A: Ten largest hosts
WITH host_counts AS (
    SELECT
        host_id,
        COUNT(*) AS listing_count
    FROM listings_analysis
    WHERE host_id IS NOT NULL
    GROUP BY host_id
),
ranked_hosts AS (
    SELECT
        host_id,
        listing_count,
        ROW_NUMBER() OVER (
            ORDER BY listing_count DESC, host_id
        ) AS host_rank
    FROM host_counts
)
SELECT
    host_rank,
    host_id,
    listing_count,
    ROUND(
        100.0 * listing_count /
        (SELECT SUM(listing_count) FROM host_counts),
        2
    ) AS market_share_pct
FROM ranked_hosts
WHERE host_rank <= 10
ORDER BY host_rank;

-- Query B: Overall concentration
WITH host_counts AS (
    SELECT
        host_id,
        COUNT(*) AS listing_count
    FROM listings_analysis
    WHERE host_id IS NOT NULL
    GROUP BY host_id
),
ranked AS (
    SELECT
        listing_count,
        ROW_NUMBER() OVER (
            ORDER BY listing_count DESC
        ) AS rn
    FROM host_counts
)
SELECT
    COUNT(*) AS total_hosts,
    SUM(listing_count) AS total_listings,
    MAX(listing_count) AS largest_host_listings,
    ROUND(AVG(listing_count), 2)
        AS avg_listings_per_host,
    ROUND(
        100.0 * SUM(listing_count)
        FILTER (WHERE rn <= 10) /
        SUM(listing_count),
        2
    ) AS top_10_host_share_pct
FROM ranked;
  