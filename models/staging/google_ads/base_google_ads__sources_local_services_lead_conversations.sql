with source as (
    select *
    from
        {{ source('google_ads__sources', 'local_services_lead_conversations') }}
),

renamed as (
    select
        {{ adapter.quote("MESSAGE_DETAILS_ATTACHMENT_URLS") }},
        {{ adapter.quote("CONVERSATION_CHANNEL") }},
        {{ adapter.quote("CUSTOMER_ID") }},
        {{ adapter.quote("PHONE_CALL_DETAILS_CALL_DURATION_MILLIS") }},
        {{ adapter.quote("PARTICIPANT_TYPE") }},
        {{ adapter.quote("PHONE_CALL_DETAILS_CALL_RECORDING_URL") }},
        {{ adapter.quote("EVENT_DATE_TIME") }},
        {{ adapter.quote("ID") }},
        {{ adapter.quote("MESSAGE_DETAILS_TEXT") }},
        {{ adapter.quote("LOCAL_SERVICES_LEAD_ID") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
