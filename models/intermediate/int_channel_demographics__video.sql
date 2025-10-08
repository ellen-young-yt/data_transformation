with channel_demographics as (
    select *
    from {{ ref("int_channel_demographics") }}
),

channel_basic as (
    select *
    from {{ ref("int_channel_basic") }}
),

views_by_video_day as (
    select
        video_id,
        calendar_date,
        sum(total_view_count) as total_view_count
    from channel_basic
    group by all
),

all_data as (
    select
        cd.channel_demographics_id,
        cd.channel_id,
        cd.video_id,
        cd.calendar_date,
        cd.live_or_on_demand,
        cd.subscribed_status,
        cd.country_code,
        cd.country_name,
        cd.gender,
        cd.age_group,
        cd.share_of_views_this_video_day,
        vvd.total_view_count as total_view_count_this_video_day,

        -- This field attempts to translate view share into a count by multiplying by the total number of views for that video that day
        -- It should be taken as an estimate because the data doesn't tie perfectly across tables
        (cd.share_of_views_this_video_day * total_view_count_this_video_day)::dec(18, 2)
            as view_count_estimated
    from channel_demographics as cd
    left join views_by_video_day
        as vvd on cd.video_id = vvd.video_id
    and cd.calendar_date = vvd.calendar_date
)

select *
from all_data
