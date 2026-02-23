with source as (
    select *
    from {{ source('google_ads__sources', 'campaign_conversion_goal_history') }}
),

renamed as (
    select
        {{ adapter.quote("CAMPAIGN_ID") }},
        {{ adapter.quote("RESOURCE_NAME") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("BIDDABLE") }},
        {{ adapter.quote("CATEGORY") }},
        {{ adapter.quote("ORIGIN") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
