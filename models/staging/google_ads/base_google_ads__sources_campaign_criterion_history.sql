with source as (
    select *
    from {{ source('google_ads__sources', 'campaign_criterion_history') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("GEO_TARGET_CONSTANT_ID") }},
        {{ adapter.quote("MOBILE_DEVICE_ID") }},
        {{ adapter.quote("OPERATING_SYSTEM_VERSION_ID") }},
        {{ adapter.quote("USER_INTEREST_ID") }},
        {{ adapter.quote("USER_LIST_ID") }},
        {{ adapter.quote("AGE_RANGE_TYPE") }},
        {{ adapter.quote("BID_MODIFIER") }},
        {{ adapter.quote("CARRIER_COUNTRY_CODE") }},
        {{ adapter.quote("CARRIER_NAME") }},
        {{ adapter.quote("CONTENT_LABEL_TYPE") }},
        {{ adapter.quote("DEVICE_TYPE") }},
        {{ adapter.quote("DISPLAY_NAME") }},
        {{ adapter.quote("GENDER_TYPE") }},
        {{ adapter.quote("INCOME_RANGE_TYPE") }},
        {{ adapter.quote("IP_BLOCK_IP_ADDRESS") }},
        {{ adapter.quote("KEYWORD_MATCH_TYPE") }},
        {{ adapter.quote("KEYWORD_TEXT") }},
        {{ adapter.quote("LANGUAGE_CODE") }},
        {{ adapter.quote("LANGUAGE_NAME") }},
        {{ adapter.quote("MOBILE_APP_CATEGORY_CONSTANT_ID") }},
        {{ adapter.quote("MOBILE_APP_CATEGORY_CONSTANT_NAME") }},
        {{ adapter.quote("MOBILE_APPLICATION_APP_ID") }},
        {{ adapter.quote("MOBILE_APPLICATION_NAME") }},
        {{ adapter.quote("NEGATIVE") }},
        {{ adapter.quote("PARENTAL_STATUS_TYPE") }},
        {{ adapter.quote("PLACEMENT_URL") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("TOPIC_CONSTANT_ID") }},
        {{ adapter.quote("TYPE") }},
        {{ adapter.quote("YOUTUBE_CHANNEL_ID") }},
        {{ adapter.quote("YOUTUBE_VIDEO_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
