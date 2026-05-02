 -- Quick test to verify source connection works
 SELECT
     unique_key,
     created_date,
     complaint_type,
     borough
 FROM {{ source('raw', 'source_311_service_requests_table') }}
 LIMIT 10