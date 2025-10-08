with source as (
    select * from {{ source('google_ads__sources', 'ad_group_history') }}
),

renamed as (
    select
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("BASE_AD_GROUP_ID") }},
        {{ adapter.quote("AD_ROTATION_MODE") }},
        {{ adapter.quote("CAMPAIGN_NAME") }},
        {{ adapter.quote("DISPLAY_CUSTOM_BID_DIMENSION") }},
        {{ adapter.quote("EXPLORER_AUTO_OPTIMIZER_SETTING_OPT_IN") }},
        {{ adapter.quote("FINAL_URL_SUFFIX") }},
        {{ adapter.quote("NAME") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("TARGET_RESTRICTIONS") }},
        {{ adapter.quote("TRACKING_URL_TEMPLATE") }},
        {{ adapter.quote("TYPE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
