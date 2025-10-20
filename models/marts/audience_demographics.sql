with channel_demographics as (
    select *
    from {{ ref("int_channel_demographics__video") }}
),

daily_video_views as (
    select *
    from {{ ref('int_channel_combined_summarized_by_video_and_day') }}
),

all_data as (
    select
        -- Video attributes
        cd.channel_id,
        cd.video_id,
        cd.video_title,
        cd.video_uploaded_at_pt,
        cd.video_uploaded_at_pt::date as video_upload_date,
        cd.category_name,
        cd.video_duration_in_seconds,
        cd.video_duration_in_minutes,
        cd.video_thumbnail_url,
        cd.video_number_asc,
        cd.video_number_desc,

        -- Demographic attributes of viewers by day
        cd.calendar_date,
        cd.live_or_on_demand,
        cd.subscribed_status,
        cd.country_code,
        cd.country_grouped,
        cd.country_name,
        cd.gender,
        cd.age_group,
        cd.share_of_views_this_video_day,
        dvv.total_views as total_view_count_this_day,

        -- This field attempts to translate view share into a count by multiplying by the total number of views for that video that day
        -- It should be taken as an estimate because the data doesn't tie perfectly across tables
        (cd.share_of_views_this_video_day * total_view_count_this_day)::dec(18, 2)
            as segment_view_count_this_day
    from channel_demographics as cd
    left join daily_video_views
        as dvv on cd.video_id = dvv.video_id
    and cd.calendar_date = dvv.calendar_date
)

select *
from all_data
