with source as (
    select * from {{ source('google_ads__sources', 'local_services_lead') }}
),

renamed as (
    select
        {{ adapter.quote("NOTE_EDIT_DATE_TIME") }},
        {{ adapter.quote("CATEGORY_ID") }},
        {{ adapter.quote("CREDIT_DETAILS_CREDIT_STATE") }},
        {{ adapter.quote("CREATION_DATE_TIME") }},
        {{ adapter.quote("SERVICE_ID") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("LEAD_CHARGED") }},
        {{ adapter.quote("LEAD_STATUS") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("CREDIT_DETAILS_CREDIT_STATE_LAST_UPDATE_DATE_TIME") }},
        {{ adapter.quote("CONTACT_DETAILS") }},
        {{ adapter.quote("LOCALE") }},
        {{ adapter.quote("NOTE_DESCRIPTION") }},
        {{ adapter.quote("LEAD_TYPE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
