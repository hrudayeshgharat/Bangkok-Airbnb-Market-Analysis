# Bangkok Airbnb Market Analysis (SQL)

Cleaning and analysis of 30,922 real Bangkok Airbnb listings using PostgreSQL, built to practice working with messy, real-world data end-to-end: raw import → cleaning → analysis.

## Data source

[Inside Airbnb](http://insideairbnb.com/get-the-data/) — Bangkok, Thailand, detailed listings (scraped 2026-09). Prices are in Thai Baht (THB).

## Why this project

Most public SQL portfolio datasets (Superstore, Chinook) arrive pre-cleaned. This one doesn't: prices are stored as text (`$1,338.49`), names contain HTML tags, key columns are entirely empty, and a small number of listings carry placeholder prices in the millions. The goal was to clean it defensibly — every decision logged, nothing silently dropped — and then answer real business questions with it.

## Tools

PostgreSQL, pgAdmin 4, Python (pandas, for trimming the raw file to a loadable column set).

## Repo structure

```
├── README.md
├── data/
│   ├── listings_slim.csv        # trimmed raw export (28 cols) used for the import
│   └── cleaning_log.csv         # exported cleaning_log table
├── sql/
│   ├── 00_create_raw_and_clean.sql
│   ├── 01_price_by_room_type.sql
│   ├── 02_price_by_neighbourhood.sql
│   ├── 03_superhost_price_rating.sql
│   ├── 04_rating_vs_price.sql
│   ├── 05_host_concentration.sql
│   └── 06_availability_vs_price.sql
└── screenshots/
```

## 1. Loading and cleaning

Raw data was loaded as-is into `listings_raw` (every column `TEXT`, nothing cast or filtered), so the original file is always recoverable. All cleaning happened in a separate `listings_clean` table, built with `CREATE TABLE ... AS SELECT`. Every step is recorded in a `cleaning_log` table rather than described after the fact.

| Step | Action | Rows before | Rows after | Note |
|---|---|---|---|---|
| 1 | Loaded raw Bangkok listings into `listings_raw` | 30,922 | 30,922 | All columns imported as text |
| 2 | Checked duplicate ids | 30,922 | 30,922 | 30,922 unique ids, no duplicates to remove |
| 3 | Dropped empty columns `host_since` and `license` | 30,922 | 30,922 | Missing in every row |
| 4 | Converted price text to numeric (`price_thb`) | 30,922 | 30,922 | 28,663 priced; 2,259 missing kept as NULL |
| 5 | Stripped HTML tags and trimmed listing names | 30,922 | 30,922 | 149 names changed (HTML tags stripped, extra spaces trimmed); 23 names with a literal "<" such as "<200m to MRT" kept as genuine text |
| 6 | Flagged previous-scrape rows | 30,922 | 30,922 | 2,506 flagged; 1,543 of them have no price |
| 7 | Kept missing ratings as NULL | 30,922 | 30,922 | 9,972 unrated rows all have 0 reviews — not an error, just no reviews yet |
| 8 | Flagged price outliers above 50,000 THB/night | 30,922 | 30,922 | 61 listings flagged; rows kept, excluded from price analysis |
| 9 | Created `listings_analysis` view (priced, non-outlier, current-scrape) | 30,922 | 27,646 | `listings_raw` and `listings_clean` left unchanged |

**Notable cleaning decisions**

- **No duplicates found** — checked, not assumed.
- **Two columns (`host_since`, `license`) were empty for every row** and were dropped rather than kept as dead weight.
- **Price was stored as text** (`$1,338.49`) and converted to a numeric `price_thb` column. 2,259 listings (7%) have no price and were kept as `NULL` rather than guessed.
- **Outliers were flagged, not deleted.** 61 listings (0.2%) price above 50,000 THB/night — including two listings whose Chinese-language names translate roughly to "spare room, not for sale," confirming they're placeholder listings, not genuine prices. Flagging rather than deleting kept the raw count intact and made the before/after effect measurable: median price was unchanged (1,601 THB), but the mean dropped from 2,911 to 2,416 THB once outliers were excluded — evidence that a handful of listings were skewing any average-based analysis.
- **"Previous scrape" listings (2,506, 8%) were flagged and excluded from the analysis view**, not deleted. 62% of them have no price, versus 2.5% of current listings, consistent with them being stale/inactive rather than currently bookable.
- **Unrated listings (9,972, 32%) all have zero reviews** — confirmed before assuming the rating was simply missing. They were kept as `NULL`, never filled with an average or a zero.

All of the above flows into `listings_analysis`, a view over the clean table that excludes unpriced, outlier, and previous-scrape rows (27,646 of the original 30,922) — the dataset the business questions below run against.

## 2. Business questions and findings

**1. What does a listing cost, by room type?**
Entire homes make up 66% of listings (18,373) at a median of 1,774 THB/night. Private rooms are 31% (8,464) at a median of 1,345 THB. For every room type, the mean sits well above the median (e.g. entire homes: 2,659 vs. 1,774), confirming the data is right-skewed and medians are the fairer summary.

**2. Which neighbourhoods are most expensive, and which have the most supply?**
Among entire homes with at least 50 listings, **Parthum Wan** (2,951 THB median), **Samphanthawong** (2,900) and **Phra Nakhon** (2,808) are the priciest — roughly 60–66% above the city median. The biggest supply isn't the priciest: **Vadhana** (3,130 listings) and **Khlong Toei** (2,666 listings) sit at mid-range prices (2,351 and 2,050 THB), making them the city's volume markets.

**3. Do superhosts charge more and rate higher?**
Superhosts (7,886 of 18,373 entire-home listings) have a higher median price (1,863 vs. 1,704 THB), a higher median rating (4.91 vs. 4.74), and nearly double the average review count (40.4 vs. 19.4) compared to non-superhosts — evidence that the superhost badge tracks both guest trust and host experience, not just pricing power.

**4. How does price relate to guest rating?**
Price rises with rating band for entire homes: unrated listings sit at 1,706 THB median, rising to 1,858 THB for listings rated 4.8+. The relationship isn't large (about 9% between lowest and highest rated bands with reviews), suggesting rating is a modest, not dominant, price driver in this market.

**5. How concentrated is the market among top hosts?**
The single largest host operates 244 listings, just 0.88% of the market. The top 10 hosts combined still each hold under 1% individually — there's no dominant professional operator; supply is highly fragmented across many small hosts.

**6. How does availability relate to price?**
63% of listings are "highly available" (median 1,596 THB) and 18% are "always available" (median 1,500 THB) — the cheapest, most available segment. The smallest group, "rarely available" (0.73%, mostly booked out), commands the highest median at 2,147 THB, suggesting scarcity (or deliberate low-availability pricing by hosts who don't need the income) correlates with higher prices.

## Caveats

- Prices are listed nightly rates, not amounts guests actually paid (no booking data is included).
- Neighbourhood figures describe listing prices, not transaction volume.
- "Previous scrape" exclusion assumes those listings are stale; this wasn't independently confirmed against Inside Airbnb's own documentation.
- All THB figures should be read as of the September 2026 scrape date.