with source as (
    select * from {{ source('google_ads__sources', 'search_keyword_stats') }}
),

renamed as (
    select
        {{ adapter.quote("CONVERSIONS_VALUE") }},
        {{ adapter.quote("RESOURCE_NAME") }},
        {{ adapter.quote("AVERAGE_CPM") }},
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("IMPRESSIONS") }},
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("VIEW_THROUGH_CONVERSIONS") }},
        {{ adapter.quote("ABSOLUTE_TOP_IMPRESSION_PERCENTAGE") }},
        {{ adapter.quote("CLICKS") }},
        {{ adapter.quote("AD_GROUP_CRITERION_CRITERION_ID") }},
        {{ adapter.quote("TOP_IMPRESSION_PERCENTAGE") }},
        {{ adapter.quote("AVERAGE_CPC") }},
        {{ adapter.quote("CTR") }},
        {{ adapter.quote("CONVERSIONS_FROM_INTERACTIONS_RATE") }},
        {{ adapter.quote("COST_MICROS") }},
        {{ adapter.quote("DATE") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("_FIVETRAN_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
