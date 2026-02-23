with channel_device as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_device_os_a_2') }}
),

outputs as (
    select
        channel_id,
        video_id,
        date as calendar_date,
        country_code,
        device_type as device_type_id,
        operating_system as operating_system_id,
        views as view_count,
        watch_time_minutes as watch_time_in_minutes,
        average_view_duration_seconds,
        (average_view_duration_percentage / 100)::dec(18, 4)
            as average_view_duration_percentage,
        red_views as red_view_count,
        red_watch_time_minutes as red_watch_time_in_minutes,
        _fivetran_synced,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status

    from channel_device
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'device_type_id',
        'operating_system_id'
    ]) }} as channel_device_id,
    *
from outputs
