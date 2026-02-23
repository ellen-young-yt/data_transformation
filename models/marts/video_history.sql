with videos as (
    select *
    from {{ ref('int_video') }}
),

views_and_watch_time as (
    select *
    from {{ ref('int_channel_combined_summarized_by_video_and_day' ) }}
),

channel_basic as (
    select *
    from {{ ref('int_channel_basic__video') }}
),

channel_traffic as (
    select *
    from {{ ref('int_channel_traffic__video') }}
),

audience_retention as (
    select *
    from {{ ref('int_audience_retention__video') }}
),

comments as (
    select *
    from {{ ref('stg_youtube_analytics__comment') }}
),

subscribers_likes_and_dislikes as (
    select
        video_id,
        calendar_date,

        /* SUBSCRIBERS GAINED */

        sum(subscriber_gain_count) as total_subscribers_gained,
        -- by country
        sum(iff(country_name = 'United States of America', subscriber_gain_count, 0))
            as united_states_subscribers_gained,
        sum(iff(country_name = 'Korea, Republic of', subscriber_gain_count, 0))
            as korea_subscribers_gained,
        sum(
            iff(
                country_name not in ('United States of America', 'Korea, Republic of'),
                subscriber_gain_count,
                0
            )
        ) as other_country_subscribers_gained,

        /* SUBSCRIBERS LOST */

        sum(subscribers_lost_count) as total_subscribers_lost,
        -- by country
        sum(iff(country_name = 'United States of America', subscribers_lost_count, 0))
            as united_states_subscribers_lost,
        sum(iff(country_name = 'Korea, Republic of', subscribers_lost_count, 0))
            as korea_subscribers_lost,
        sum(
            iff(
                country_name not in ('United States of America', 'Korea, Republic of'),
                subscribers_lost_count,
                0
            )
        ) as other_country_subscribers_lost,

        /* NET SUBSCRIBERS */

        total_subscribers_gained - total_subscribers_lost as total_net_subscribers,
        -- by country
        united_states_subscribers_gained
        - united_states_subscribers_lost as united_states_net_subscribers,
        korea_subscribers_gained - korea_subscribers_lost as korea_net_subscribers,
        other_country_subscribers_gained
        - other_country_subscribers_lost as other_country_net_subscribers,

        /* LIKES */

        sum(like_count) as total_likes,
        -- by subscriber status
        sum(iff(subscribed_status = 'Subscribed', like_count, 0)) as subscriber_likes,
        sum(iff(subscribed_status = 'Not Subscribed', like_count, 0)) as non_subscriber_likes,
        -- by country
        sum(iff(country_name = 'United States of America', like_count, 0)) as united_states_likes,
        sum(iff(country_name = 'Korea, Republic of', like_count, 0)) as korea_likes,
        sum(
            iff(
                country_name not in ('United States of America', 'Korea, Republic of'),
                like_count,
                0
            )
        ) as other_country_likes,

        /* DISLIKES */

        sum(dislike_count) as total_dislikes,
        -- by subscriber status
        sum(iff(subscribed_status = 'Subscribed', dislike_count, 0)) as subscriber_dislikes,
        sum(iff(subscribed_status = 'Not Subscribed', dislike_count, 0)) as non_subscriber_dislikes,
        -- by country
        sum(iff(country_name = 'United States of America', dislike_count, 0))
            as united_states_dislikes,
        sum(iff(country_name = 'Korea, Republic of', dislike_count, 0)) as korea_dislikes,
        sum(
            iff(
                country_name not in ('United States of America', 'Korea, Republic of'),
                dislike_count,
                0
            )
        ) as other_country_dislikes

    from channel_basic
    group by all
),

channel_traffic_categorized as (
    -- todo: move this logic upstream to intermediate
    select
        *,
        case
            when traffic_source_name in ('YouTube advertising') then 'Promotion'
            when
                traffic_source_name in (
                    'YouTube search',
                    'Browse features',
                    'Notifications',
                    'Other YouTube features',
                    'Suggested videos'
                )
                then 'Youtube Browse'
            when traffic_source_name = 'External' then 'External'
            when traffic_source_name = 'Shorts' then 'Shorts'
            when
                traffic_source_name in (
                    'Interactive video endscreen', 'Video cards and annotations'
                )
                then 'Ecosystem'
            when
                traffic_source_name in (
                    'YouTube Other',
                    'Direct or unknown',
                    'Playlist pages',
                    'Playlists',
                    'Related video'
                )
                then 'Other or Unknown'
            when
                traffic_source_name = 'YouTube channels' and traffic_source_detail = 'Ellen Young'
                then 'Ecosystem'
            when
                traffic_source_name = 'YouTube channels' and traffic_source_detail = 'Other Channel'
                then 'Youtube Browse'   -- should not reach here
        end as traffic_source_category
    from channel_traffic
),

channel_traffic_summarized as (
    -- calculate view counts and total watch time by traffic source
    select
        video_id,
        calendar_date,

        -- view counts
        sum(iff(traffic_source_category = 'Promotion', view_count, 0)) as promoted_views,
        sum(iff(traffic_source_category <> 'Promotion', view_count, 0)) as organic_views,

        sum(iff(traffic_source_category = 'Ecosystem', view_count, 0)) as ecosystem_views,
        sum(iff(traffic_source_category = 'Youtube Browse', view_count, 0)) as youtube_browse_views,
        sum(iff(traffic_source_category = 'Shorts', view_count, 0)) as shorts_views,
        sum(iff(traffic_source_category = 'External', view_count, 0)) as external_views,
        sum(iff(traffic_source_category = 'Other or Unknown', view_count, 0))
            as other_channel_views,

        -- watch time
        sum(iff(traffic_source_category = 'Promotion', watch_time_in_minutes, 0))
            as promoted_watch_time_in_mins,
        sum(iff(traffic_source_category <> 'Promotion', watch_time_in_minutes, 0))
            as organic_watch_time_in_mins,

        sum(iff(traffic_source_category = 'Ecosystem', watch_time_in_minutes, 0))
            as ecosystem_watch_time_in_mins,
        sum(iff(traffic_source_category = 'Youtube Browse', watch_time_in_minutes, 0))
            as youtube_browse_watch_time_in_mins,
        sum(iff(traffic_source_category = 'Shorts', watch_time_in_minutes, 0))
            as shorts_watch_time_in_mins,
        sum(iff(traffic_source_category = 'External', watch_time_in_minutes, 0))
            as external_watch_time_in_mins,
        sum(iff(traffic_source_category = 'Other or Unknown', watch_time_in_minutes, 0))
            as other_channel_watch_time_in_mins

    from channel_traffic_categorized
    group by all
),

audience_retention_w_flags as (
    select
        *,
        rank() over (partition by video_id order by abs(video_timestamp_in_seconds - 10))
        = 1 as flag_10s,
        rank() over (partition by video_id order by abs(video_timestamp_in_seconds - 30))
        = 1 as flag_30s
    from audience_retention
),

audience_retention_summarized as (
    select
        ar.video_id,
        ar.calendar_date,
        sum(iff(ar.flag_10s, wt.total_views, 0)) as total_views_10s,
        sum(iff(ar.flag_10s, wt.total_views * ar.percent_watch_ratio, 0)) as viewers_still_watching_10s,
        sum(iff(ar.flag_30s, wt.total_views, 0)) as total_views_30s,
        sum(iff(ar.flag_30s, wt.total_views * ar.percent_watch_ratio, 0)) as viewers_still_watching_30s
    from audience_retention_w_flags as ar
    left join views_and_watch_time as wt
        on
            ar.video_id = wt.video_id
            and ar.calendar_date = wt.calendar_date
    group by all
),

comments_data as (
    select
        video_id,
        date_trunc(day, comment_published_at_pt)::date as calendar_date,
        count(*) as total_comments
    from comments
    where commenter_display_name not in ('@ellenypak', '@ellen_young')
    group by all
),

dates as (
    -- generate a series of dates starting in nov 2024
    select date_day as calendar_date
    from (
        {{ dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2024-11-01' as date)",
            end_date="current_date()"
        ) }}
    )
),

base_table as (
    -- create a table with a record for each video + day that all data will subsequently be joined to
    select
        -- video information
        v.video_id,
        v.video_title,
        v.published_at_pt as video_uploaded_at_pt,
        v.category_name,
        v.video_duration_in_seconds,
        -- calendar_date
        d.calendar_date,
        datediff(day, v.published_at_pt, d.calendar_date) as days_since_upload
    from videos as v
    inner join dates as d on d.calendar_date between v.published_at_pt::date and current_date - 1   -- don't show current date; there is a lag in youtube reporting api so there is no current day data
),

all_data as (
    select
        b.*,

        -- VIEW COUNTS (CURRENT DAY)
        coalesce(vwt.total_views, 0) as total_views_this_day,

        -- by traffic source
        coalesce(cts.promoted_views, 0) as promoted_views_this_day,
        coalesce(cts.organic_views, 0) as organic_views_this_day,
        coalesce(cts.ecosystem_views, 0) as ecosystem_views_this_day,
        coalesce(cts.youtube_browse_views, 0) as youtube_browse_views_this_day,
        coalesce(cts.shorts_views, 0) as shorts_views_this_day,
        coalesce(cts.external_views, 0) as external_views_this_day,
        coalesce(cts.other_channel_views, 0) as other_channel_views_this_day,

        -- by subscriber status
        coalesce(vwt.subscriber_views, 0) as subscriber_views_this_day,
        coalesce(vwt.non_subscriber_views, 0) as non_subscriber_views_this_day,

        -- by country
        coalesce(vwt.united_states_views, 0) as united_states_views_this_day,
        coalesce(vwt.korea_views, 0) as korea_views_this_day,
        coalesce(vwt.other_country_views, 0) as other_country_views_this_day,

        -- by device type
        coalesce(vwt.mobile_phone_device_views, 0) as mobile_phone_device_views_this_day,
        coalesce(vwt.television_device_views, 0) as television_device_views_this_day,
        coalesce(vwt.other_device_views, 0) as other_device_views_this_day,


        -- VIEW COUNTS (TO DATE)
        sum(total_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_views_to_date,

        -- by traffic source
        sum(promoted_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as promoted_views_to_date,
        sum(organic_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as organic_views_to_date,
        sum(ecosystem_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as ecosystem_views_to_date,
        sum(youtube_browse_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as youtube_browse_views_to_date,
        sum(shorts_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as shorts_views_to_date,
        sum(external_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as external_views_to_date,
        sum(other_channel_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_channel_views_to_date,

        -- by subscriber status
        sum(subscriber_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as subscriber_views_to_date,
        sum(non_subscriber_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as non_subscriber_views_to_date,

        -- by country
        sum(united_states_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_views_to_date,
        sum(korea_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_views_to_date,
        sum(other_country_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_views_to_date,

        -- by device type
        sum(mobile_phone_device_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as mobile_phone_device_views_to_date,
        sum(television_device_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as television_device_views_to_date,
        sum(other_device_views_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_device_views_to_date,


        -- TOTAL WATCH TIME (CURRENT DAY)
        coalesce(vwt.total_watch_time_in_mins, 0) as total_watch_time_in_mins_this_day,

        -- by traffic source
        coalesce(cts.promoted_watch_time_in_mins, 0) as promoted_watch_time_in_mins_this_day,
        coalesce(cts.organic_watch_time_in_mins, 0) as organic_watch_time_in_mins_this_day,
        coalesce(cts.ecosystem_watch_time_in_mins, 0) as ecosystem_watch_time_in_mins_this_day,
        coalesce(cts.youtube_browse_watch_time_in_mins, 0)
            as youtube_browse_watch_time_in_mins_this_day,
        coalesce(cts.shorts_watch_time_in_mins, 0) as shorts_watch_time_in_mins_this_day,
        coalesce(cts.external_watch_time_in_mins, 0) as external_watch_time_in_mins_this_day,
        coalesce(cts.other_channel_watch_time_in_mins, 0)
            as other_channel_watch_time_in_mins_this_day,

        -- by subscriber status
        coalesce(vwt.subscriber_watch_time_in_mins, 0) as subscriber_watch_time_in_mins_this_day,
        coalesce(vwt.non_subscriber_watch_time_in_mins, 0)
            as non_subscriber_watch_time_in_mins_this_day,

        -- by country
        coalesce(vwt.united_states_watch_time_in_mins, 0)
            as united_states_watch_time_in_mins_this_day,
        coalesce(vwt.korea_watch_time_in_mins, 0) as korea_watch_time_in_mins_this_day,
        coalesce(vwt.other_country_watch_time_in_mins, 0)
            as other_country_watch_time_in_mins_this_day,

        -- by device type
        coalesce(vwt.mobile_phone_device_watch_time_in_mins, 0)
            as mobile_phone_device_watch_time_in_mins_this_day,
        coalesce(vwt.television_device_watch_time_in_mins, 0)
            as television_device_watch_time_in_mins_this_day,
        coalesce(vwt.other_device_watch_time_in_mins, 0)
            as other_device_watch_time_in_mins_this_day,


        -- TOTAL WATCH TIME (TO DATE)
        sum(total_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_watch_time_in_mins_to_date,

        -- by traffic source
        sum(promoted_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as promoted_watch_time_in_mins_to_date,
        sum(organic_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as organic_watch_time_in_mins_to_date,
        sum(ecosystem_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as ecosystem_watch_time_in_mins_to_date,
        sum(youtube_browse_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as youtube_browse_watch_time_in_mins_to_date,
        sum(shorts_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as shorts_watch_time_in_mins_to_date,
        sum(external_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as external_watch_time_in_mins_to_date,
        sum(other_channel_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_channel_watch_time_in_mins_to_date,

        -- by subscriber status
        sum(subscriber_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as subscriber_watch_time_in_mins_to_date,
        sum(non_subscriber_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as non_subscriber_watch_time_in_mins_to_date,

        -- by country
        sum(united_states_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_watch_time_in_mins_to_date,
        sum(korea_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_watch_time_in_mins_to_date,
        sum(other_country_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_watch_time_in_mins_to_date,

        -- by device type
        sum(mobile_phone_device_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as mobile_phone_device_watch_time_in_mins_to_date,
        sum(television_device_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as television_device_watch_time_in_mins_to_date,
        sum(other_device_watch_time_in_mins_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_device_watch_time_in_mins_to_date,



        -- RETENTION (THIS DAY)
        coalesce(ar.total_views_10s, 0) as retention_denominator_this_day, -- todo: rename me... or delete if matches total_views
        coalesce(ar.viewers_still_watching_10s, 0) as viewers_retained_10s_this_day,
        coalesce(ar.viewers_still_watching_30s, 0) as viewers_retained_30s_this_day,


        -- RETENTION (TO DATE)
        sum(retention_denominator_this_day) over (partition by b.video_id order by b.calendar_date rows between unbounded preceding and current row) as retention_denominator_to_date,  -- todo: rename me... or delete if matches total_views
        sum(viewers_retained_10s_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as viewers_retained_10s_to_date,
        sum(viewers_retained_30s_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as viewers_retained_30s_to_date,


        -- SUBSCRIBERS (CURRENT DAY)
        coalesce(sld.total_net_subscribers, 0) as total_net_subscribers_this_day,
        coalesce(sld.total_subscribers_gained, 0) as total_subscribers_gained_this_day,
        coalesce(sld.total_subscribers_lost, 0) as total_subscribers_lost_this_day,

        -- by country (usa, korea, other)
        coalesce(sld.united_states_net_subscribers, 0) as united_states_net_subscribers_this_day,
        coalesce(sld.united_states_subscribers_gained, 0)
            as united_states_subscribers_gained_this_day,
        coalesce(sld.united_states_subscribers_lost, 0) as united_states_subscribers_lost_this_day,

        coalesce(sld.korea_net_subscribers, 0) as korea_net_subscribers_this_day,
        coalesce(sld.korea_subscribers_gained, 0) as korea_subscribers_gained_this_day,
        coalesce(sld.korea_subscribers_lost, 0) as korea_subscribers_lost_this_day,

        coalesce(sld.other_country_net_subscribers, 0) as other_country_net_subscribers_this_day,
        coalesce(sld.other_country_subscribers_gained, 0)
            as other_country_subscribers_gained_this_day,
        coalesce(sld.other_country_subscribers_lost, 0) as other_country_subscribers_lost_this_day,


        -- SUBSCRIBERS (TO DATE)
        sum(total_net_subscribers_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_net_subscribers_to_date,
        sum(total_subscribers_gained_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_subscribers_gained_to_date,
        sum(total_subscribers_lost_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_subscribers_lost_to_date,

        -- by country (usa, korea, other)
        sum(united_states_net_subscribers_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_net_subscribers_to_date,
        sum(united_states_subscribers_gained_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_subscribers_gained_to_date,
        sum(united_states_subscribers_lost_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_subscribers_lost_to_date,

        sum(korea_net_subscribers_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_net_subscribers_to_date,
        sum(korea_subscribers_gained_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_subscribers_gained_to_date,
        sum(korea_subscribers_lost_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_subscribers_lost_to_date,

        sum(other_country_net_subscribers_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_net_subscribers_to_date,
        sum(other_country_subscribers_gained_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_subscribers_gained_to_date,
        sum(other_country_subscribers_lost_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_subscribers_lost_to_date,


        -- TOTAL LIKES (CURRENT DAY)
        coalesce(sld.total_likes, 0) as total_likes_this_day,

        -- by subscriber status
        coalesce(sld.subscriber_likes, 0) as subscriber_likes_this_day,
        coalesce(sld.non_subscriber_likes, 0) as non_subscriber_likes_this_day,

        -- by country
        coalesce(sld.united_states_likes, 0) as united_states_likes_this_day,
        coalesce(sld.korea_likes, 0) as korea_likes_this_day,
        coalesce(sld.other_country_likes, 0) as other_country_likes_this_day,


        -- TOTAL LIKES (TO DATE)
        sum(total_likes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_likes_to_date,

        -- by subscriber status
        sum(subscriber_likes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as subscriber_likes_to_date,
        sum(non_subscriber_likes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as non_subscriber_likes_to_date,

        -- by country
        sum(united_states_likes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_likes_to_date,
        sum(korea_likes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_likes_to_date,
        sum(other_country_likes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_likes_to_date,


        -- TOTAL DISLIKES (CURRENT DAY)
        coalesce(sld.total_dislikes, 0) as total_dislikes_this_day,

        -- by subscriber status
        coalesce(sld.subscriber_dislikes, 0) as subscriber_dislikes_this_day,
        coalesce(sld.non_subscriber_dislikes, 0) as non_subscriber_dislikes_this_day,

        -- by country
        coalesce(sld.united_states_dislikes, 0) as united_states_dislikes_this_day,
        coalesce(sld.korea_dislikes, 0) as korea_dislikes_this_day,
        coalesce(sld.other_country_dislikes, 0) as other_country_dislikes_this_day,


        -- TOTAL DISLIKES (TO DATE)
        sum(total_dislikes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_dislikes_to_date,

        -- by subscriber status
        sum(subscriber_dislikes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as subscriber_dislikes_to_date,
        sum(non_subscriber_dislikes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as non_subscriber_dislikes_to_date,

        -- by country
        sum(united_states_dislikes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as united_states_dislikes_to_date,
        sum(korea_dislikes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as korea_dislikes_to_date,
        sum(other_country_dislikes_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as other_country_dislikes_to_date,


        -- COMMENTS (CURRENT DAY & TO DATE)
        coalesce(c.total_comments, 0) as total_comments_this_day,
        sum(total_comments_this_day)
            over (
                partition by b.video_id
                order by b.calendar_date rows between unbounded preceding and current row
            )
            as total_comments_to_date


    from base_table as b
    left join views_and_watch_time as vwt
        on
            b.video_id = vwt.video_id
            and b.calendar_date = vwt.calendar_date
    left join channel_traffic_summarized as cts
        on
            b.video_id = cts.video_id
            and b.calendar_date = cts.calendar_date
    left join audience_retention_summarized as ar
        on
            b.video_id = ar.video_id
            and b.calendar_date = ar.calendar_date
    left join subscribers_likes_and_dislikes as sld
        on
            b.video_id = sld.video_id
            and b.calendar_date = sld.calendar_date
    left join comments_data
        as c on b.video_id = c.video_id
    and b.calendar_date = c.calendar_date
)

select *
from all_data
order by video_uploaded_at_pt, days_since_upload
