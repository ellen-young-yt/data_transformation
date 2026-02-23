with source as (
    select *
    from {{ source('google_ads__sources', 'search_term_keyword_stats') }}
),

renamed as (
    select
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("DATE") }},
        {{ adapter.quote("_FIVETRAN_ID") }},
        {{ adapter.quote("RESOURCE_NAME") }},
        {{ adapter.quote("SEARCH_TERM") }},
        {{ adapter.quote("CONVERSIONS_VALUE") }},
        {{ adapter.quote("CONVERSIONS") }},
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("SEARCH_TERM_MATCH_TYPE") }},
        {{ adapter.quote("IMPRESSIONS") }},
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("VIEW_THROUGH_CONVERSIONS") }},
        {{ adapter.quote("ABSOLUTE_TOP_IMPRESSION_PERCENTAGE") }},
        {{ adapter.quote("CLICKS") }},
        {{ adapter.quote("KEYWORD_AD_GROUP_CRITERION") }},
        {{ adapter.quote("TOP_IMPRESSION_PERCENTAGE") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("INFO_TEXT") }},
        {{ adapter.quote("CONVERSIONS_FROM_INTERACTIONS_VALUE_PER_INTERACTION") }},
        {{ adapter.quote("AVERAGE_CPC") }},
        {{ adapter.quote("CTR") }},
        {{ adapter.quote("CONVERSIONS_FROM_INTERACTIONS_RATE") }},
        {{ adapter.quote("COST_MICROS") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
