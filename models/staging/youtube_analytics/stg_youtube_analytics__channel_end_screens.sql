with channel_end_screens as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_end_screens_a_1') }}
),

all_data as (
    select
        channel_id,
        video_id,
        date as calendar_date,
        country_code,
        end_screen_element_type as end_screen_element_type_id,
        end_screen_element_clicks,
        end_screen_element_impressions,
        (end_screen_element_click_rate / 100)::dec(18, 4)
            as end_screen_element_click_rate,
        _fivetran_synced,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status,
        try_to_number(end_screen_element_id, 38, 0) as end_screen_element_id
    from channel_end_screens
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'end_screen_element_id'
    ]) }} as channel_end_screen_id,
    *
from all_data
