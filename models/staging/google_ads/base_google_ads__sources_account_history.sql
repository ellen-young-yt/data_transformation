with source as (
    select * from {{ source('google_ads__sources', 'account_history') }}
),

renamed as (
    select
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("MANAGER_CUSTOMER_ID") }},
        {{ adapter.quote("AUTO_TAGGING_ENABLED") }},
        {{ adapter.quote("CURRENCY_CODE") }},
        {{ adapter.quote("DESCRIPTIVE_NAME") }},
        {{ adapter.quote("FINAL_URL_SUFFIX") }},
        {{ adapter.quote("HIDDEN") }},
        {{ adapter.quote("MANAGER") }},
        {{ adapter.quote("OPTIMIZATION_SCORE") }},
        {{ adapter.quote("PAY_PER_CONVERSION_ELIGIBILITY_FAILURE_REASONS") }},
        {{ adapter.quote("TEST_ACCOUNT") }},
        {{ adapter.quote("TIME_ZONE") }},
        {{ adapter.quote("TRACKING_URL_TEMPLATE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
