with source as (
    select * from {{ source('google_ads__sources', 'click_stats') }}
),

renamed as (
    select
        {{ adapter.quote("CLICKS") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("GCLID") }},
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("DATE") }},
        {{ adapter.quote("_FIVETRAN_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
