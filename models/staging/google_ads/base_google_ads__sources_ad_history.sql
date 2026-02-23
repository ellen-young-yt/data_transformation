with source as (
    select * from {{ source('google_ads__sources', 'ad_history') }}
),

renamed as (
    select
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("ACTION_ITEMS") }},
        {{ adapter.quote("AD_STRENGTH") }},
        {{ adapter.quote("ADDED_BY_GOOGLE_ADS") }},
        {{ adapter.quote("DEVICE_PREFERENCE") }},
        {{ adapter.quote("DISPLAY_URL") }},
        {{ adapter.quote("FINAL_URL_SUFFIX") }},
        {{ adapter.quote("FINAL_APP_URLS") }},
        {{ adapter.quote("FINAL_MOBILE_URLS") }},
        {{ adapter.quote("FINAL_URLS") }},
        {{ adapter.quote("NAME") }},
        {{ adapter.quote("POLICY_SUMMARY_APPROVAL_STATUS") }},
        {{ adapter.quote("POLICY_SUMMARY_REVIEW_STATUS") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("SYSTEM_MANAGED_RESOURCE_SOURCE") }},
        {{ adapter.quote("TRACKING_URL_TEMPLATE") }},
        {{ adapter.quote("TYPE") }},
        {{ adapter.quote("URL_COLLECTIONS") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
