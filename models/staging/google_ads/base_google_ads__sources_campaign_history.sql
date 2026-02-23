with source as (
    select * from {{ source('google_ads__sources', 'campaign_history') }}
),

renamed as (
    select
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("BASE_CAMPAIGN_ID") }},
        {{ adapter.quote("AD_SERVING_OPTIMIZATION_STATUS") }},
        {{ adapter.quote("ADVERTISING_CHANNEL_SUBTYPE") }},
        {{ adapter.quote("ADVERTISING_CHANNEL_TYPE") }},
        {{ adapter.quote("EXPERIMENT_TYPE") }},
        {{ adapter.quote("END_DATE") }},
        {{ adapter.quote("FINAL_URL_SUFFIX") }},
        {{ adapter.quote("FREQUENCY_CAPS") }},
        {{ adapter.quote("NAME") }},
        {{ adapter.quote("OPTIMIZATION_SCORE") }},
        {{ adapter.quote("PAYMENT_MODE") }},
        {{ adapter.quote("SERVING_STATUS") }},
        {{ adapter.quote("START_DATE") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("TRACKING_URL_TEMPLATE") }},
        {{ adapter.quote("VANITY_PHARMA_DISPLAY_URL_MODE") }},
        {{ adapter.quote("VANITY_PHARMA_TEXT") }},
        {{ adapter.quote("VIDEO_BRAND_SAFETY_SUITABILITY") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
