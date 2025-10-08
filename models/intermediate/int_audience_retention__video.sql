with audience_retention as (
    select *
    from {{ ref("stg_youtube_analytics__audience_retention") }}
),

video as (
    select *
    from {{ ref("int_video") }}
),

audience_retention__video as (
    select
        ar.audience_retention_id,
        v.channel_id,
        ar.video_id,
        v.video_title,
        v.published_at_pt as video_published_at_pt,
        v.category_name as video_category,
        v.video_thumbnail_url,
        v.video_duration_in_seconds,
        ar.calendar_date,
        ar.percent_of_video_elapsed,
        ar.percent_watch_ratio,
        ar.relative_retention_performance,
        round(v.video_duration_in_seconds * ar.percent_of_video_elapsed, 2)
            as video_timestamp_in_seconds
    from audience_retention as ar
    left join video as v on ar.video_id = v.video_id
    where ar.video_id is distinct from 'M8JBkd8KMJA'    -- has no match in the videos table and only 2 views so just removing
)

select *
from audience_retention__video
