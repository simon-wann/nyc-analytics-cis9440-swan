-- Location dimension shared by both restaurant applications and 311 service reqs

WITH all_locations AS (
   -- Get locations from 311 requests
   SELECT DISTINCT
      borough,
      incident_zip AS zip_code
   FROM {{ ref('staging_group13_nyc311') }}
   WHERE borough IS NOT NULL

   UNION DISTINCT

   -- Get locations from motor vehicle crashes
   SELECT DISTINCT
       borough,
       zip_code
   FROM {{ ref('staging_group13_mvc_crash') }}
   WHERE borough IS NOT NULL
),

location_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS location_key,
       borough,
       zip_code
   FROM all_locations
)

SELECT * FROM location_dimension