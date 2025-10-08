with source as (
    select * from {{ source('google_ads__sources', 'user_interest') }}
),

renamed as (
    select
        {{ adapter.quote("ID") }},
        {{ adapter.quote("PARENT_ID") }},
        {{ adapter.quote("AVAILABILITIES") }},
        {{ adapter.quote("LAUNCHED_TO_ALL") }},
        {{ adapter.quote("NAME") }},
        {{ adapter.quote("TAXONOMY_TYPE") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }}

    from source
)

select * from renamed
