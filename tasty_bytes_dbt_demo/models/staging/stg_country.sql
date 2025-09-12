{{ config(
    materialized='incremental',
    schema='stg',
    unique_key=["Country_City_Key"],
    incremental_strategy='merge',
    pre_hook=[ "{{ init_highwatermark('stg_country') }}" ],
    post_hook=[ "{{ update_highwatermark('lcf.highwatermark','stg_country', 'raw.country', 'lastupdateddate') }}" ]
) }}

WITH highwatermark AS (
    SELECT *
    FROM tasty_bytes_dbt_db.lcf.highwatermark
    WHERE table_name = '{{ this.identifier }}'
),

ranked_country_city AS (
    SELECT
        CONCAT(b.country_id,'-',b.city_id) AS Country_City_Key,
        b.country,
        b.iso_currency,
        b.iso_country,
        b.city,
        b.city_population,
        ROW_NUMBER() OVER (
            PARTITION BY b.country_id,b.city_id
            ORDER BY b.lastupdateddate DESC
        ) AS rn
    FROM {{ ref('raw_pos_country') }} b
    JOIN highwatermark h
      ON b.lastupdateddate >= h.start_date
),

deduped AS (
    SELECT *
    FROM ranked_country_city
    WHERE rn = 1
)

SELECT
    d.Country_City_Key,
    d.country,
    d.iso_currency,
    d.iso_country,
    d.city,
    d.city_population,

    {% if is_incremental() %}
    CASE
        WHEN existing.Country_City_Key IS NULL THEN CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ
        ELSE existing.InsertDate
    END AS InsertDate,

    CASE
        WHEN existing.Country_City_Key IS NULL
             OR d.country <> existing.country
             OR d.iso_currency <> existing.iso_currency
             OR d.iso_country <> existing.iso_country
             OR d.city <> existing.city
             OR d.city_population <> existing.city_population
        THEN CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ
        ELSE existing.ActionDate
    END AS ActionDate,

    CASE
        WHEN existing.Country_City_Key IS NULL THEN 'I'
        WHEN d.country <> existing.country
             OR d.iso_currency <> existing.iso_currency
             OR d.iso_country <> existing.iso_country
             OR d.city <> existing.city
             OR d.city_population <> existing.city_population THEN 'U'
        ELSE 'I'
    END AS ActionType

    {% else %}

    CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS InsertDate,
    CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS ActionDate,
    'I' AS ActionType

    {% endif %}

FROM deduped d

{% if is_incremental() %}
LEFT JOIN {{ this }} existing
    ON d.Country_City_Key = existing.Country_City_Key
{% else %}
-- On first run no existing data to join, so no join here
{% endif %}
