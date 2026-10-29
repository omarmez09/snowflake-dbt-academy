with 
    source_data as(

    select *
    from {{ source('raw_data', 'customers') }}

    ),
    cleaned_data as (
         
        SELECT
            c.customer_id,
            UPPER(TRIM(c.first_name)) AS first_name,
            UPPER(TRIM(c.last_name)) AS last_name,
            LOWER(TRIM(c.email)) AS email,
            COALESCE(c.phone, 'N/A') AS phone,
            c.created_at,
            CASE
                WHEN c.country IS NULL OR c.country = '' THEN 'UNKNOWN'
                WHEN c.country IN ('US', 'USA', 'United States', 'united states') THEN 'US'
                WHEN c.country IN ('UK', 'GB', 'United Kingdom', 'united kingdom', 'Great Britain') THEN 'UK'
                WHEN c.country IN ('CA', 'Canada', 'canada') THEN 'CA'
                WHEN c.country IN ('DE', 'Germany', 'germany') THEN 'DE'
                WHEN c.country IN ('FR', 'France', 'france') THEN 'FR'
                ELSE UPPER(c.country)
            END AS country_standardized
        FROM source_data c
        WHERE c.created_at IS NOT NULL
        AND c.email IS NOT NULL
        AND c.email LIKE '%@%'
        qualify ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(c.email)) ORDER BY c.created_at DESC) = 1
    )

select * from cleaned_data
