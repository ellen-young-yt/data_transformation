with channel_province as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_province_a_2') }}
),

outputs as (
    select
        channel_id,
        video_id,
        date as calendar_date,
        country_code,
        province_code,
        views as view_count,
        watch_time_minutes::dec(18, 4) as watch_time_in_minutes,
        average_view_duration_seconds::dec(18, 2)
            as average_view_duration_in_seconds,
        (average_view_duration_percentage / 100)::dec(18, 4)
            as average_view_duration_percentage,
        _fivetran_synced,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status

    from channel_province
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'province_code'
    ]) }} as channel_province_id,
    *
from outputs
