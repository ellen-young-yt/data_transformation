with channel_combined as (
    select *
    from {{ ref("int_channel_combined") }}
),

video as (
    select *
    from {{ ref("int_video") }}
),

all_data as (
    select
        cc.channel_combined_id,
        cc.channel_id,
        cc.video_id,
        v.video_title,
        v.published_at_pt as video_published_at_pt,
        v.category_name as video_category,
        v.video_number_asc,
        v.video_number_desc,
        cc.calendar_date,
        cc.country_code,
        cc.country_name,
        cc.live_or_on_demand,
        cc.subscribed_status,
        cc.playback_location_type_id,
        cc.playback_location_type,
        cc.traffic_source_type_id,
        cc.traffic_source_type,
        cc.device_type_id,
        cc.device_type,
        cc.operating_system_id,
        cc.operating_system,
        cc.view_count,
        cc.watch_time_in_minutes,
        cc.average_view_duration_in_seconds,
        cc.red_view_count,
        cc.red_view_watch_time_in_minutes
    from channel_combined as cc
    left join video as v on cc.video_id = v.video_id
)

select *
from all_data
