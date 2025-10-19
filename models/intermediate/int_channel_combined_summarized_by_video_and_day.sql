with channel_combined as (
    select *
    from {{ ref('int_channel_combined__video' ) }}
),

summarized_by_video_and_day as (
    select
        video_id,
        video_title,
        video_published_at_pt,
        video_published_at_pt::date as video_upload_date,
        calendar_date,

        /* VIEW COUNTS */

        sum(view_count) as total_views,
        -- by subscriber status
        sum(iff(subscribed_status = 'Subscribed', view_count, 0)) as subscriber_views,
        sum(iff(subscribed_status = 'Not Subscribed', view_count, 0)) as non_subscriber_views,
        -- by country
        sum(iff(country_name = 'United States of America', view_count, 0)) as united_states_views,
        sum(iff(country_name = 'Korea, Republic of', view_count, 0)) as korea_views,
        sum(
            iff(
                country_name not in ('United States of America', 'Korea, Republic of'),
                view_count,
                0
            )
        ) as other_country_views,
        -- by device type
        sum(iff(device_type = 'Mobile phone', view_count, 0)) as mobile_phone_device_views,
        sum(iff(device_type = 'TV', view_count, 0)) as television_device_views,
        sum(iff(device_type not in ('Mobile phone', 'TV'), view_count, 0)) as other_device_views,

        /* WATCH TIME */

        sum(watch_time_in_minutes) as total_watch_time_in_mins,
        -- by subscriber status
        sum(iff(subscribed_status = 'Subscribed', watch_time_in_minutes, 0))
            as subscriber_watch_time_in_mins,
        sum(iff(subscribed_status = 'Not Subscribed', watch_time_in_minutes, 0))
            as non_subscriber_watch_time_in_mins,
        -- by country
        sum(iff(country_name = 'United States of America', watch_time_in_minutes, 0))
            as united_states_watch_time_in_mins,
        sum(iff(country_name = 'Korea, Republic of', watch_time_in_minutes, 0))
            as korea_watch_time_in_mins,
        sum(
            iff(
                country_name not in ('United States of America', 'Korea, Republic of'),
                watch_time_in_minutes,
                0
            )
        ) as other_country_watch_time_in_mins,
        -- by device type
        sum(iff(device_type = 'Mobile phone', watch_time_in_minutes, 0))
            as mobile_phone_device_watch_time_in_mins,
        sum(iff(device_type = 'TV', watch_time_in_minutes, 0))
            as television_device_watch_time_in_mins,
        sum(iff(device_type not in ('Mobile phone', 'TV'), watch_time_in_minutes, 0))
            as other_device_watch_time_in_mins

    from channel_combined
    where video_title is not null
    group by all
)

select *
from summarized_by_video_and_day
