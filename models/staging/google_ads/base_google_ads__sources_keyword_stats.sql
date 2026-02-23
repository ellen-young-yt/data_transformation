with source as (
    select * from {{ source('google_ads__sources', 'keyword_stats') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_BASE_CAMPAIGN") }},
        {{ adapter.quote("CONVERSIONS_VALUE") }},
        {{ adapter.quote("CONVERSIONS") }},
        {{ adapter.quote("INTERACTIONS") }},
        {{ adapter.quote("AD_NETWORK_TYPE") }},
        {{ adapter.quote("INTERACTION_EVENT_TYPES") }},
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("IMPRESSIONS") }},
        {{ adapter.quote("VIEW_THROUGH_CONVERSIONS") }},
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("DEVICE") }},
        {{ adapter.quote("ACTIVE_VIEW_VIEWABILITY") }},
        {{ adapter.quote("ACTIVE_VIEW_IMPRESSIONS") }},
        {{ adapter.quote("CLICKS") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("AD_GROUP_CRITERION_CRITERION_ID") }},
        {{ adapter.quote("ACTIVE_VIEW_MEASURABLE_IMPRESSIONS") }},
        {{ adapter.quote("ACTIVE_VIEW_MEASURABLE_COST_MICROS") }},
        {{ adapter.quote("ACTIVE_VIEW_MEASURABILITY") }},
        {{ adapter.quote("AD_GROUP_BASE_AD_GROUP") }},
        {{ adapter.quote("COST_MICROS") }},
        {{ adapter.quote("DATE") }},
        {{ adapter.quote("_FIVETRAN_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
