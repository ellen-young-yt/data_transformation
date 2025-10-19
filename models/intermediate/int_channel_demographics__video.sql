with channel_demographics as (
    select *
    from {{ ref("int_channel_demographics") }}
),

videos as (
    select *
    from {{ ref('int_video') }}
),

all_data as (
    select
        cd.channel_demographics_id,

        -- Video attributes
        cd.channel_id,
        cd.video_id,
        v.video_title,
        v.category_name,
        v.video_duration_in_seconds,
        v.video_duration_in_minutes,
        v.video_thumbnail_url,
        v.video_number_asc,
        v.video_number_desc,

        -- Demographic attributes of viewers by day
        cd.calendar_date,
        cd.live_or_on_demand,
        cd.subscribed_status,
        cd.country_code,
        cd.country_name,
        cd.gender,
        cd.age_group,
        cd.share_of_views_this_video_day

    from channel_demographics as cd
    left join videos as v
        on cd.video_id = v.video_id

    -- Exclude records that don't tie to a video (likely delete and reuploads)
    -- For clarity, this condition was written explicitly instead of inner joining to videos
    where v.video_id is not null
)

select *
from all_data
