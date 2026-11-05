with source_data as(

    select *
    from {{ source('raw_data', 'customers') }}

    ),

    country_map as (
        select * from {{ ref('country_mapping') }}
    ),

    cleaned_data as (
         
        SELECT
            customer_id::integer as customer_id,
            trim(upper(first_name)) as first_name,
            trim(upper(last_name)) AS last_name,
            trim(lower(email)) AS email,
            coalesce(trim(c.phone), 'N/A') AS phone_number,
            trim(upper(country)) as country_code,
            coalesce(cm.country_code, trim(upper(c.country))) as country_standardized,            
            c.created_at::timestamp_ntz as created_at,
        FROM source_data c
        left join country_map cm
            on trim(upper(c.country)) = upper(cm.country_raw)
        WHERE c.created_at IS NOT NULL
        AND c.email IS NOT NULL
        AND c.email LIKE '%@%'
        qualify ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(c.email)) 
            ORDER BY c.created_at DESC
            ) = 1
    )

select * from cleaned_data
