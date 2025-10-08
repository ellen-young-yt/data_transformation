with channel_basic as (
    select *
    from {{ ref("int_channel_basic") }}
),

video as (
    select *
    from {{ ref("int_video") }}
),

channel_basic__video as (
    select
        cb.channel_basic_id,
        cb.channel_id,
        cb.video_id,
        v.video_title,
        v.published_at_pt as video_published_at_pt,
        v.category_name as video_category,
        cb.calendar_date,
        cb.live_or_on_demand,
        cb.subscribed_status,
        cb.country_code,
        cb.country_name,
        cb.total_view_count,
        cb.like_count,
        cb.dislike_count,
        cb.subscriber_gain_count,
        cb.subscribers_lost_count,
        cb.total_watch_time_in_minutes,
        cb.avg_view_duration_in_seconds,
        datediff(day, v.published_at_pt, cb.calendar_date) as days_since_published
    from channel_basic as cb
    left join video as v on cb.video_id = v.video_id
)

select *
from channel_basic__video
