with source as (
    select *
    from
        {{ source('google_ads__sources', 'campaign_geo_target_type_setting_history') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("NEGATIVE_GEO_TARGET_TYPE") }},
        {{ adapter.quote("POSITIVE_GEO_TARGET_TYPE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
