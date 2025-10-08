with channel_basic as (
    select
        cb.channel_basic_id,
        cb.channel_id,
        cb.video_id,
        cb.calendar_date,
        cb.live_or_on_demand,
        cb.subscribed_status,
        cb.country_code,
        cc.country_name,
        cb.total_view_count,
        cb.like_count,
        cb.dislike_count,
        cb.subscriber_gain_count,
        cb.subscribers_lost_count,
        cb.total_watch_time_in_minutes,
        cb.avg_view_duration_in_seconds,
        cb.card_impressions,
        cb.card_clicks,
        cb.card_teaser_impressions,
        cb.card_teaser_clicks,
        cb.comment_count,
        cb.share_count,
        cb.videos_added_to_playlists,
        cb.videos_removed_from_playlists,
        cb.red_view_count
    from {{ ref("stg_youtube_analytics__channel_basic") }} as cb
    left join {{ ref("country_codes_lookup") }} as cc on cb.country_code = cc.country_code
)

select *
from channel_basic
