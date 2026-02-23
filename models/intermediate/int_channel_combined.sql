with channel_combined as (
    select *
    from {{ ref("stg_youtube_analytics__channel_combined") }}
),

playback_location_types as (
    select *
    from {{ ref("playback_location_type") }}
),

country_codes as (
    select *
    from {{ ref("country_codes_lookup") }}
),

traffic_sources as (
    select *
    from {{ ref("traffic_source_lookup") }}
),

device_type as (
    select *
    from {{ ref("device_type") }}
),

operating_system as (
    select *
    from {{ ref("operating_system") }}
),

all_data as (
    select
        chc.channel_combined_id,
        chc.channel_id,
        chc.video_id,
        chc.calendar_date,
        chc.country_code,
        cc.country_name,
        chc.live_or_on_demand,
        chc.subscribed_status,
        chc.playback_location_type_id,
        plt.name as playback_location_type,
        chc.traffic_source_type_id,
        ts.traffic_source_name as traffic_source_type,
        chc.device_type_id,
        dt.name as device_type,
        chc.operating_system_id,
        os.name as operating_system,
        chc.view_count,
        chc.watch_time_in_minutes,
        chc.average_view_duration_in_seconds,
        chc.red_view_count,
        chc.red_view_watch_time_in_minutes
    from channel_combined as chc
    left join playback_location_types as plt on chc.playback_location_type_id = plt.id
    left join country_codes as cc on chc.country_code = cc.country_code
    left join traffic_sources as ts on chc.traffic_source_type_id = ts.traffic_source_id
    left join device_type as dt on chc.device_type_id = dt.id
    left join operating_system as os on chc.operating_system_id = os.id
)

select *
from all_data
