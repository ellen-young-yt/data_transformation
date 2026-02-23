with source as (
    select * from {{ source('google_ads__sources', 'campaign_budget_history') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("AMOUNT_MICROS") }},
        {{ adapter.quote("DELIVERY_METHOD") }},
        {{ adapter.quote("EXPLICITLY_SHARED") }},
        {{ adapter.quote("HAS_RECOMMENDED_BUDGET") }},
        {{ adapter.quote("NAME") }},
        {{ adapter.quote("PERIOD") }},
        {{ adapter.quote("RECOMMENDED_BUDGET_AMOUNT_MICROS") }},
        {{ adapter.quote("REFERENCE_COUNT") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("TOTAL_AMOUNT_MICROS") }},
        {{ adapter.quote("TYPE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
