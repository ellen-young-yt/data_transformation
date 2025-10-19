with audience_retention as (
    select *
    from {{ ref('int_audience_retention__video') }}
),

daily_video_views as (
    select *
    from {{ ref('int_channel_combined_summarized_by_video_and_day') }}
),

summarized_by_video_and_timestamp as (
    select
        -- Video dimensions
        ar.video_title,
        ar.video_published_at_pt,
        ar.video_published_at_pt::date as video_upload_date,
        ar.video_category,
        ar.video_thumbnail_url,
        ar.video_duration_in_seconds,

        -- Timestamp dimensions
        ar.percent_of_video_elapsed,
        ar.video_timestamp_in_seconds,

        -- Metrics
        sum(dvv.total_views) as total_video_views,
        sum(dvv.total_views * ar.percent_watch_ratio) as views_of_this_time_segment,
        views_of_this_time_segment / total_video_views as retention_performance

    from audience_retention as ar
    left join daily_video_views as dvv
        on ar.video_id = dvv.video_id
        and ar.calendar_date = dvv.calendar_date
    group by all
)

select *
from summarized_by_video_and_timestamp
order by video_upload_date desc, percent_of_video_elapsed asc
