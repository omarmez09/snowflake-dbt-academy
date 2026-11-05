with source_data as(

    select *
    from {{ source('raw_data', 'customers') }}

    ),
    cleaned_data as (
         
        SELECT
            customer_id::integer as customer_id,
            trim(upper(first_name)) as first_name,
            trim(upper(last_name)) AS last_name,
            trim(lower(email)) AS email,
            coalesce(trim(c.phone), 'N/A') AS phone,
            CASE
                WHEN c.country IS NULL OR c.country = '' THEN 'UNKNOWN'
                WHEN c.country IN ('US', 'USA', 'United States', 'united states') THEN 'US'
                WHEN c.country IN ('UK', 'GB', 'United Kingdom', 'united kingdom', 'Great Britain') THEN 'UK'
                WHEN c.country IN ('CA', 'Canada', 'canada') THEN 'CA'
                WHEN c.country IN ('DE', 'Germany', 'germany') THEN 'DE'
                WHEN c.country IN ('FR', 'France', 'france') THEN 'FR'
                ELSE UPPER(c.country)
            END AS country_standardized,
            c.created_at::timestamp_ntz as created_at,
        FROM source_data c
        WHERE c.created_at IS NOT NULL
        AND c.email IS NOT NULL
        AND c.email LIKE '%@%'
        qualify ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(c.email)) 
            ORDER BY c.created_at DESC
            ) = 1
    )

select * from cleaned_data
