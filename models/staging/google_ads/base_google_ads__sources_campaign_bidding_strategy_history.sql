with source as (
    select *
    from
        {{ source('google_ads__sources', 'campaign_bidding_strategy_history') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("CPC_BID_CEILING_MICROS") }},
        {{ adapter.quote("CPC_BID_FLOOR_MICROS") }},
        {{ adapter.quote("ENHANCED_CPC") }},
        {{ adapter.quote("ENHANCED_CPC_ENABLED") }},
        {{ adapter.quote("MANUAL_CPA") }},
        {{ adapter.quote("MANUAL_CPM") }},
        {{ adapter.quote("MANUAL_CPV") }},
        {{ adapter.quote("LOCATION") }},
        {{ adapter.quote("LOCATION_FRACTION_MICROS") }},
        {{ adapter.quote("NAME") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("TARGET_CPA_MICROS") }},
        {{ adapter.quote("TARGET_CPM") }},
        {{ adapter.quote("TARGET_ROAS") }},
        {{ adapter.quote("TYPE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
