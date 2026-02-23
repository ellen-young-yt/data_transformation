with channel_demographics as (
    select *
    from {{ ref("stg_youtube_analytics__channel_demographics") }}
),

country_code as (
    select *
    from {{ ref("country_codes_lookup") }}
),

all_data as (
    select -- noqa: ST06
        cd.channel_demographics_id,
        cd.channel_id,
        cd.video_id,
        cd.calendar_date,
        cd.live_or_on_demand,
        cd.subscribed_status,
        cd.country_code,
        cc.country_name,
        case
            when cc.country_name = 'United States of America' then 'United States'
            when cc.country_name = 'Korea, Republic of' then 'South Korea'
            -- TODO: Add regional identifiers to the countries seed and use them in place of "Other"
            else 'Other'
        end as country_grouped,
        cd.gender,
        cd.age_group,
        cd.share_of_views_this_video_day
    from channel_demographics as cd
    left join country_code as cc on cd.country_code = cc.country_code
)

select *
from all_data
