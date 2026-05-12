-- Start vehicle_type dimension: vehicle_type_code1 (from stg data) and vehicle_type_category (added based on data)

-- First get all the vehicle types from the staging data in a cte
WITH vehicle_types AS (
    SELECT DISTINCT
        vehicle_type_code1
    FROM {{ ref('fact_group13_mvc_crash') }}
    WHERE vehicle_type_code1 IS NOT NULL
),

-- Then add an enriched CTE -- adding the categorical vehicle_type_category column
enriched AS (
    SELECT
        *,

        CASE
            WHEN LOWER(vehicle_type_code1) LIKE '%sedan%' THEN 'Passenger Vehicle'
            WHEN LOWER(vehicle_type_code1) LIKE '%station wagon%' THEN 'Passenger Vehicle'
            WHEN LOWER(vehicle_type_code1) LIKE '%taxi%' THEN 'Passenger Vehicle'
            WHEN LOWER(vehicle_type_code1) LIKE '%suv%' THEN 'Passenger Vehicle'
            WHEN LOWER(vehicle_type_code1) LIKE '%box truck%' THEN 'Truck'
            WHEN LOWER(vehicle_type_code1) LIKE '%tractor truck%' THEN 'Truck'
            WHEN LOWER(vehicle_type_code1) LIKE '%bus%' THEN 'Bus'
            WHEN LOWER(vehicle_type_code1) LIKE '%bike%' THEN 'Bike'
            WHEN LOWER(vehicle_type_code1) LIKE '%motorcycle%' THEN 'Motorcycle'
            WHEN LOWER(vehicle_type_code1) LIKE '%ambulance%' THEN 'Emergency Vehicle'
            WHEN LOWER(vehicle_type_code1) LIKE '%fire truck%' THEN 'Emergency Vehicle'
            WHEN LOWER(vehicle_type_code1) LIKE '%police%' THEN 'Emergency Vehicle'
            ELSE 'Other'
        END AS vehicle_type_category

    FROM vehicle_types
),

-- Ask ourselves: anything else needed? 
-- Start vehicle_type dimension

-- Create vehicle_type_dimension CTE, best practice for clarity
vehicle_type_dimension AS (
    -- Use Jinja syntax to create surrogate key, using what minimally makes a row in the vehicle_type dimension unique in the generator
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'vehicle_type_code1'
        ]) }} AS vehicle_type_key,
        -- Then select all the other things -- either from the CTE with everything, or joining if necessary
        vehicle_type_code1,
        vehicle_type_category

    FROM enriched
)

SELECT * FROM vehicle_type_dimension