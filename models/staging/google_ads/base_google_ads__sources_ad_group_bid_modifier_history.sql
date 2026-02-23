with source as (
    select *
    from {{ source('google_ads__sources', 'ad_group_bid_modifier_history') }}
),

renamed as (
    select
        {{ adapter.quote("AD_GROUP_ID") }},
        {{ adapter.quote("CRITERION_ID") }},
        {{ adapter.quote("UPDATED_AT") }},
        {{ adapter.quote("BASE_AD_GROUP") }},
        {{ adapter.quote("BID_MODIFIER") }},
        {{ adapter.quote("BID_MODIFIER_SOURCE") }},
        {{ adapter.quote("DEVICE_TYPE") }},
        {{ adapter.quote("HOTEL_ADVANCE_BOOKING_WINDOW_MAX_DAYS") }},
        {{ adapter.quote("HOTEL_ADVANCE_BOOKING_WINDOW_MIN_DAYS") }},
        {{ adapter.quote("HOTEL_CHECK_IN_DATE_RANGE_END_DATE") }},
        {{ adapter.quote("HOTEL_CHECK_IN_DATE_RANGE_START_DATE") }},
        {{ adapter.quote("HOTEL_CHECK_IN_DAY_DAY_OF_WEEK") }},
        {{ adapter.quote("HOTEL_DATE_SELECTION_TYPE") }},
        {{ adapter.quote("HOTEL_LENGTH_OF_STAY_MAX_NIGHTS") }},
        {{ adapter.quote("HOTEL_LENGTH_OF_STAY_MIN_NIGHTS") }},
        {{ adapter.quote("_FIVETRAN_SYNCED") }},
        {{ adapter.quote("_FIVETRAN_START") }},
        {{ adapter.quote("_FIVETRAN_END") }},
        {{ adapter.quote("_FIVETRAN_ACTIVE") }}

    from source
)

select * from renamed
