with source as (
    select *
    from
        {{ source('google_ads__sources', 'ad_group_bidding_strategy_history') }}
),

renamed as (
    select
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("CPC_BID_MICROS") }},
        {{ adapter.quote("CPM_BID_MICROS") }},
        {{ adapter.quote("CPV_BID_MICROS") }},
        {{ adapter.quote("EFFECTIVE_TARGET_CPA_MICROS") }},
        {{ adapter.quote("EFFECTIVE_TARGET_CPA_SOURCE") }},
        {{ adapter.quote("EFFECTIVE_TARGET_ROAS") }},
        {{ adapter.quote("EFFECTIVE_TARGET_ROAS_SOURCE") }},
        {{ adapter.quote("PERCENT_CPC_BID_MICROS") }},
        {{ adapter.quote("TARGET_CPA_MICROS") }},
        {{ adapter.quote("TARGET_CPM_MICROS") }},
        {{ adapter.quote("TARGET_ROAS") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
