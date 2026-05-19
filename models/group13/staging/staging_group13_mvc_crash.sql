-- Clean and standardize Motor Vehicle Collisions - Crashes data
-- One row per crash event

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nypd_crash_table') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           collision_id,
           crash_date,
           crash_time,
           borough,
           zip_code,
           latitude,
           longitude,
           location,
           on_street_name,
           cross_street_name,
           off_street_name
       ),

       -- Identifiers
       CAST(collision_id AS STRING) AS collision_id,

       -- Date/Time
       CAST(crash_date AS TIMESTAMP) AS crash_date,
       CAST(crash_time AS STRING) AS crash_time,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip_code AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip_code AS STRING)) = 5 THEN CAST(zip_code AS STRING)
           WHEN LENGTH(CAST(zip_code AS STRING)) = 9 THEN CAST(zip_code AS STRING)
           WHEN LENGTH(CAST(zip_code AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip_code AS STRING)
           ELSE NULL
       END AS zip_code,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       -- Location fields
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,
       CAST(location AS STRING) AS location,
       CAST(on_street_name AS STRING) AS on_street_name,
       CAST(cross_street_name AS STRING) AS cross_street_name,
       CAST(off_street_name AS STRING) AS off_street_name,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE collision_id IS NOT NULL
   AND crash_date IS NOT NULL
   AND CAST(crash_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY collision_id ORDER BY crash_date DESC) = 1
)

SELECT * FROM cleaned
-- This model can be saved as: stg_nypd_motor_vehicle_collisions_crashes.sql