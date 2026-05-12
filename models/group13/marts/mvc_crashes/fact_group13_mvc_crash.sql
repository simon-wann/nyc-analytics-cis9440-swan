-- Grain: one row per request

-- --Pattern for fact table model:
-- --   WITH
-- --     [fact_source] AS (SELECT * FROM staging),
-- --     [dim1] AS (SELECT surrogate_key, join_keys FROM dim1),
-- --     [dim2] AS (SELECT surrogate_key, join_keys FROM dim2),
-- --     ...
-- --     final AS (
-- --       SELECT
-- --         [fact fields from staging data, maybe renamed with AS ___],
-- --         [dim1 surrogate key] as dim1_key_or_whatever_name,
-- --         [dim2 surrogate key] as dim2_key_or_whatever_name, ...
-- --       FROM [fact_source]
-- --       LEFT JOIN [dim1] ON ... (join fields match)
-- --       LEFT JOIN [dim2] ON ... (join fields match)
-- --     )
-- --   SELECT * FROM final
------

-- WRITE THIS 1st - Start: all data from staging for relevant data
  WITH requests AS (
      SELECT * FROM {{ ref('staging_group13_mvc_crash') }}
  ),
-- Continue: named dimension CTEs that you'll need, either the sructure or build them out slowly. 

-- WRITE this - THESE 2nd... get all the dimension stuff you need
-- What context describes each row? Then, ONLY the surrogate key + join fields from each dimension.
-- Can reference back to the dimension tables for that.
  dim_date AS (
      SELECT date_key, full_date FROM {{ ref('dim_group13_date') }}
  ),

  dim_location AS (
      SELECT location_key, borough, zip_code FROM {{ ref('dim_group13_location') }}
  ),

 -- WRITE this - the structure for this 3rd: final AS ( ... ) + see end of file as well
  final AS (
      -- WRITE this 5th -- fill in the select statement, first surrogate key, then each other thing needed in the fact from source
      -- Some of which need to come from the LEFT JOINed tables
      SELECT
          -- Surrogate key, generated from unique id in data.
          -- If there were none such (rare), could generate the surrogate id from a combo of things you are sure are unique in staging data.
          {{ dbt_utils.generate_surrogate_key(['r.collision_id']) }} AS request_key,

          -- Natural key, direct from staging data
          r.collision_id,

          -- Timestamps, direct from staging data
          r.crash_date AS request_created_at,
          r.crash_date AS request_closed_at,

          -- Foreign keys: I usually start writing these as ??? AS created_date_key, etc
          d_created.date_key AS created_date_key,
          d_closed.date_key AS closed_date_key,
          l.location_key,

          -- Request location details
          r.on_street_name,
          r.cross_street_name,
          r.off_street_name,
          r.latitude,
          r.longitude,

          -- Measures: small calculations included in a fact table
          r.number_of_persons_injured,
          r.number_of_persons_killed,
          CASE
              WHEN r.number_of_persons_killed IS NOT NULL
              THEN r.number_of_persons_killed
              ELSE NULL
          END AS days_to_close,

          -- Flags, support easy fact queries (e.g. 'all requests that are closed...')
          CASE WHEN r.number_of_persons_killed > 0 THEN TRUE ELSE FALSE END AS is_closed,

          -- Additional attributes
          r.borough,
          r.vehicle_type_code1,
          r.contributing_factor_vehicle_1
    
      -- **** INSIDE that, WRITE THIS 4th, join by join:
      FROM requests r -- All staging data

      LEFT JOIN dim_date d_created -- Date dimension to get created date
          ON CAST(r.crash_date AS DATE) = d_created.full_date -- Cast as date to match yyyy-mm-dd date format

      LEFT JOIN dim_date d_closed
          ON CAST(r.crash_date AS DATE) = d_closed.full_date -- Cast as date to match yyyy-mm-dd date format

      LEFT JOIN dim_location l
          ON r.borough = l.borough
          AND r.zip_code = l.zip_code
  )
 -- Also WRITE THIS 3rd
  SELECT * FROM final