-- Start complaint_type dimension: complaint_type (from stg data), descriptor (from stg data), and complaint_category (added based on data)

-- First get all the complaint types from the staging data in a cte
WITH complaint_types AS (
    SELECT DISTINCT
        complaint_type,
        descriptor
    FROM {{ ref('staging_group13_nyc311') }}
    WHERE complaint_type IS NOT NULL
),

-- Then add an enriched CTE -- adding the categorical complaint_category column
enriched AS (
    SELECT
        *,

        CASE
            WHEN LOWER(complaint_type) LIKE '%street condition%' THEN 'Street Condition'
            WHEN LOWER(complaint_type) LIKE '%street light%' THEN 'Street Lighting'
            WHEN LOWER(complaint_type) LIKE '%traffic signal%' THEN 'Traffic Signal / Control'
            WHEN LOWER(complaint_type) LIKE '%traffic%' THEN 'Traffic / Roadway Issue'
            WHEN LOWER(complaint_type) LIKE '%highway condition%' THEN 'Highway Condition'
            WHEN LOWER(complaint_type) LIKE '%parking%' THEN 'Parking / Visibility Issue'
            ELSE 'Other'
        END AS complaint_category

    FROM complaint_types
),

-- Ask ourselves: anything else needed? 
-- Start complaint dimension

-- Create complaint_dimension CTE, best practice for clarity
complaint_dimension AS (
    -- Use Jinja syntax to create surrogate key, using what minimally makes a row in the complaint_type dimension unique in the generator
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'complaint_type',
            'descriptor'
        ]) }} AS complaint_type_key,
        -- Then select all the other things -- either from the CTE with everything, or joining if necessary
        complaint_type,
        descriptor,
        complaint_category

    FROM enriched
)

SELECT * FROM complaint_dimension