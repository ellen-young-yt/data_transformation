with source as (
    select *
    from {{ source('google_ads__sources', 'video_responsive_ad_history') }}
),

renamed as (
    select
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("AD_ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("BREADCRUMB_1") }},
        {{ adapter.quote("BREADCRUMB_2") }},
        {{ adapter.quote("CALL_TO_ACTIONS") }},
        {{ adapter.quote("DESCRIPTIONS") }},
        {{ adapter.quote("HEADLINES") }},
        {{ adapter.quote("LONG_HEADLINES") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
