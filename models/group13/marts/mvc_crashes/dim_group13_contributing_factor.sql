-- Start contributing_factor dimension: contributing_factor_vehicle_1 (from stg data) and contributing_factor_category (added based on data)

-- First get all the contributing factors from the staging data in a cte
WITH contributing_factors AS (
    SELECT DISTINCT
        contributing_factor_vehicle_1
    FROM {{ ref('fact_group13_mvc_crash') }}
    WHERE contributing_factor_vehicle_1 IS NOT NULL
),

-- Then add an enriched CTE -- adding the categorical contributing_factor_category column
enriched AS (
    SELECT
        *,

        CASE
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%pavement slippery%' THEN 'Road Surface Condition'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%pavement defective%' THEN 'Road Surface Condition'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%obstruction%' THEN 'Road Obstruction'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%debris%' THEN 'Road Obstruction'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%traffic control%' THEN 'Traffic Control Issue'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%lane marking%' THEN 'Road Design / Marking Issue'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%view obstructed%' THEN 'Visibility / Obstruction Issue'
            WHEN LOWER(contributing_factor_vehicle_1) LIKE '%glare%' THEN 'Visibility / Obstruction Issue'
            ELSE 'Not Road Condition Related'
        END AS contributing_factor_category

    FROM contributing_factors
),

-- Ask ourselves: anything else needed? 
-- Start contributing_factor dimension

-- Create contributing_factor_dimension CTE, best practice for clarity
contributing_factor_dimension AS (
    -- Use Jinja syntax to create surrogate key, using what minimally makes a row in the contributing_factor dimension unique in the generator
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'contributing_factor_vehicle_1'
        ]) }} AS contributing_factor_key,
        -- Then select all the other things -- either from the CTE with everything, or joining if necessary
        contributing_factor_vehicle_1,
        contributing_factor_category

    FROM enriched
)

SELECT * FROM contributing_factor_dimension