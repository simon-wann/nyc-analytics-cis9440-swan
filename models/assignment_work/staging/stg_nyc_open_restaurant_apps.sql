-- Clean and standardize Open Restaurant application data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all other columns except the ones we are transforming below
        * EXCEPT (
            objectid,
            globalid,
            seating_interest_sidewalk,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            building_number,
            street,
            borough,
            zip,
            business_address,
            food_service_establishment,
            food_service_establishment_permit,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width,
            sidewalk_dimensions_area,
            roadway_dimensions_length,
            roadway_dimensions_width,
            roadway_dimensions_area,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating,
            qualify_alcohol,
            sla_serial_number,
            sla_license_type,
            landmark_district_or_building,
            landmarkdistrict_terms,
            healthcompliance_terms,
            time_of_submission,
            latitude,
            longitude,
            community_board,
            council_district,
            census_tract,
            bin,
            bbl,
            nta
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS application_id,
        CAST(globalid AS STRING) AS global_id,

        -- Application details
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest,
        TRIM(CAST(restaurant_name AS STRING)) AS restaurant_name,
        TRIM(CAST(legal_business_name AS STRING)) AS legal_business_name,
        TRIM(CAST(doing_business_as_dba AS STRING)) AS doing_business_as_name,

        -- Address
        CAST(building_number AS STRING) AS building_number,
        TRIM(CAST(street AS STRING)) AS street,
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}$') THEN CAST(zip AS STRING)
            WHEN REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}$') THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        TRIM(CAST(business_address AS STRING)) AS business_address,
        CAST(food_service_establishment AS STRING) AS food_service_establishment_permit,

        -- Seating dimensions
        CAST(sidewalk_dimensions_length AS NUMERIC) AS sidewalk_length,
        CAST(sidewalk_dimensions_width AS NUMERIC) AS sidewalk_width,
        CAST(sidewalk_dimensions_area AS NUMERIC) AS sidewalk_area,
        CAST(roadway_dimensions_length AS NUMERIC) AS roadway_length,
        CAST(roadway_dimensions_width AS NUMERIC) AS roadway_width,
        CAST(roadway_dimensions_area AS NUMERIC) AS roadway_area,

        -- Approvals / business info
        UPPER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) AS approved_for_sidewalk_seating,
        UPPER(TRIM(CAST(approved_for_roadway_seating AS STRING))) AS approved_for_roadway_seating,
        UPPER(TRIM(CAST(qualify_alcohol AS STRING))) AS qualify_alcohol,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,
        TRIM(CAST(sla_license_type AS STRING)) AS sla_license_type,

        -- Compliance / classification
        TRIM(CAST(landmark_district_or_building AS STRING)) AS landmark_district_or_building,
        TRIM(CAST(landmarkdistrict_terms AS STRING)) AS landmarkdistrict_terms,
        TRIM(CAST(healthcompliance_terms AS STRING)) AS healthcompliance_terms,

        -- Time
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- Geography
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(bin AS STRING) AS bin,
        CAST(bbl AS STRING) AS bbl,
        CAST(nta AS STRING) AS nta,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE objectid IS NOT NULL
      AND borough IS NOT NULL

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned