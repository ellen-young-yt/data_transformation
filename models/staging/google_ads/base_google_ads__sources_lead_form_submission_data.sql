with source as (
    select *
    from {{ source('google_ads__sources', 'lead_form_submission_data') }}
),

renamed as (
    select
        {{ adapter.quote("ID") }},
        {{ adapter.quote("SUBMISSION_DATE_TIME") }},
        {{ adapter.quote("RESOURCE_NAME") }},
        {{ adapter.quote("CUSTOM_LEAD_FORM_SUBMISSION_FIELDS") }},
        {{ adapter.quote("AD_ID") }},
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("LEAD_FORM_SUBMISSION_FIELDS") }},
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("GCLID") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
