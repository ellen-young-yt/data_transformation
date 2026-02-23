with source as (
    select * from {{ source('google_ads__sources', 'campaign_hourly_stats') }}
),

renamed as (
    select
        {{ adapter.quote("BASE_CAMPAIGN") }},
        {{ adapter.quote("CLICK_TYPE") }},
        {{ adapter.quote("CONVERSIONS") }},
        {{ adapter.quote("MONTH") }},
        {{ adapter.quote("INTERACTIONS") }},
        {{ adapter.quote("AVERAGE_CPM") }},
        {{ adapter.quote("YEAR") }},
        {{ adapter.quote("INTERACTION_EVENT_TYPES") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("DEVICE") }},
        {{ adapter.quote("WEEK") }},
        {{ adapter.quote("ACTIVE_VIEW_IMPRESSIONS") }},
        {{ adapter.quote("CLICKS") }},
        {{ adapter.quote("QUARTER") }},
        {{ adapter.quote("DAY_OF_WEEK") }},
        {{ adapter.quote("ACTIVE_VIEW_MEASURABLE_IMPRESSIONS") }},
        {{ adapter.quote("COST_PER_CONVERSION") }},
        {{ adapter.quote("AVERAGE_CPC") }},
        {{ adapter.quote("ACTIVE_VIEW_MEASURABILITY") }},
        {{ adapter.quote("CTR") }},
        {{ adapter.quote("CONVERSIONS_VALUE") }},
        {{ adapter.quote("AVERAGE_COST") }},
        {{ adapter.quote("AD_NETWORK_TYPE") }},
        {{ adapter.quote("IMPRESSIONS") }},
        {{ adapter.quote("ACTIVE_VIEW_VIEWABILITY") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("VALUE_PER_CONVERSION") }},
        {{ adapter.quote("HOUR") }},
        {{ adapter.quote("ACTIVE_VIEW_CPM") }},
        {{ adapter.quote("ACTIVE_VIEW_CTR") }},
        {{ adapter.quote("ACTIVE_VIEW_MEASURABLE_COST_MICROS") }},
        {{ adapter.quote("CONVERSIONS_FROM_INTERACTIONS_RATE") }},
        {{ adapter.quote("COST_MICROS") }},
        {{ adapter.quote("DATE") }},
        {{ adapter.quote("_FIVETRAN_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
