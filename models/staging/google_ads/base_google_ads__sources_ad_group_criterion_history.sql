with source as (
    select *
    from {{ source('google_ads__sources', 'ad_group_criterion_history') }}
),

renamed as (
    select
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("USER_INTEREST_ID") }},
        {{ adapter.quote("USER_LIST_ID") }},
        {{ adapter.quote("AGE_RANGE_TYPE") }},
        {{ adapter.quote("APP_PAYMENT_MODEL_TYPE") }},
        {{ adapter.quote("APPROVAL_STATUS") }},
        {{ adapter.quote("BID_MODIFIER") }},
        {{ adapter.quote("CPC_BID_MICROS") }},
        {{ adapter.quote("CPM_BID_MICROS") }},
        {{ adapter.quote("CPV_BID_MICROS") }},
        {{ adapter.quote("CUSTOM_AFFINITY_ID") }},
        {{ adapter.quote("CUSTOM_AUDIENCE_ID") }},
        {{ adapter.quote("CUSTOM_INTENT_ID") }},
        {{ adapter.quote("DISAPPROVAL_REASONS") }},
        {{ adapter.quote("DISPLAY_NAME") }},
        {{ adapter.quote("FINAL_MOBILE_URLS") }},
        {{ adapter.quote("FINAL_URLS") }},
        {{ adapter.quote("FINAL_URL_SUFFIX") }},
        {{ adapter.quote("FIRST_PAGE_CPC_MICROS") }},
        {{ adapter.quote("FIRST_POSITION_CPC_MICROS") }},
        {{ adapter.quote("GENDER_TYPE") }},
        {{ adapter.quote("INCOME_RANGE_TYPE") }},
        {{ adapter.quote("KEYWORD_MATCH_TYPE") }},
        {{ adapter.quote("KEYWORD_TEXT") }},
        {{ adapter.quote("MOBILE_APP_CATEGORY_CONSTANT_ID") }},
        {{ adapter.quote("MOBILE_APP_CATEGORY_CONSTANT_NAME") }},
        {{ adapter.quote("MOBILE_APPLICATION_APP_ID") }},
        {{ adapter.quote("MOBILE_APPLICATION_NAME") }},
        {{ adapter.quote("NEGATIVE") }},
        {{ adapter.quote("PARENT_AD_GROUP_CRITERION_ID") }},
        {{ adapter.quote("PARENTAL_STATUS_TYPE") }},
        {{ adapter.quote("PLACEMENT_URL") }},
        {{ adapter.quote("QUALITY_INFO_SCORE") }},
        {{ adapter.quote("QUALITY_INFO_CREATIVE_SCORE") }},
        {{ adapter.quote("QUALITY_INFO_POST_CLICK_SCORE") }},
        {{ adapter.quote("QUALITY_INFO_SEARCH_PREDICTED_CTR") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("SYSTEM_SERVING_STATUS") }},
        {{ adapter.quote("TOP_OF_PAGE_CPC_MICROS") }},
        {{ adapter.quote("TOPIC_CONSTANT_ID") }},
        {{ adapter.quote("TRACKING_URL_TEMPLATE") }},
        {{ adapter.quote("TYPE") }},
        {{ adapter.quote("WEBPAGE_CONDITIONS") }},
        {{ adapter.quote("YOUTUBE_CHANNEL_ID") }},
        {{ adapter.quote("YOUTUBE_VIDEO_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
