with channel_traffic_sources as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_traffic_source_a_2') }}
),

outputs as (
    select
        channel_id,
        date as calendar_date,
        traffic_source_type as traffic_source_id,
        country_code,
        views as view_count,
        watch_time_minutes::dec(18, 2) as watch_time_in_minutes,
        average_view_duration_seconds::dec(18, 2)
            as average_view_duration_in_seconds,
        (average_view_duration_percentage / 100)::dec(18, 2)
            as average_view_duration_percentage,
        red_views as red_view_count,
        red_watch_time_minutes::dec(18, 2) as red_watch_time_in_minutes,
        _fivetran_synced,
        nullif(video_id, '') as video_id,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status,
        nullif(traffic_source_detail, '') as traffic_source_detail_raw

    from channel_traffic_sources
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'traffic_source_id',
        'traffic_source_detail_raw'
    ]) }} as channel_traffic_id,
    *
from outputs
