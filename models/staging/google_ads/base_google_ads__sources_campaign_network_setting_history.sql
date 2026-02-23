with source as (
    select *
    from {{ source('google_ads__sources', 'campaign_network_setting_history') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("TARGET_CONTENT_NETWORK") }},
        {{ adapter.quote("TARGET_GOOGLE_SEARCH") }},
        {{ adapter.quote("TARGET_PARTNER_SEARCH_NETWORK") }},
        {{ adapter.quote("TARGET_SEARCH_NETWORK") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
