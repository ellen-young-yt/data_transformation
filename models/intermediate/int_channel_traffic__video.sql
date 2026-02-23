with channel_traffic as (
    select *
    from {{ ref("int_channel_traffic") }}
),

video as (
    select *
    from {{ ref("int_video") }}
),

channel as (
    select *
    from {{ ref("stg_youtube_analytics__channel") }}
),

channel_traffic__video as (
    select
        ct.*,
        v.video_title,
        v.published_at_pt as video_published_at_pt,
        v.category_name as video_category,
        datediff(day, v.published_at_pt, ct.calendar_date) as days_since_published,
        coalesce(
            chan_source.title,
            case
                when
                    ct.traffic_source_name = 'YouTube channels' and chan_source.title is null
                    then 'Other Channel'
            end,
            v_source.video_title,
            case
                when
                    ct.traffic_source_name in (
                        'Suggested videos',
                        'Interactive video endscreen',
                        'Video cards and annotations'
                    )
                    and v_source.video_title is null
                    then 'Other Video'
            end,
            initcap(replace(ct.traffic_source_detail_raw, '_', ' '))
        ) as traffic_source_detail
    from channel_traffic as ct
    left join video as v on ct.video_id = v.video_id
    left join video as v_source on ct.traffic_source_detail_raw = v_source.video_id
    left join channel as chan_source on ct.traffic_source_detail_raw = chan_source.channel_id
),

all_data as (
    select
        channel_traffic_id,
        channel_id,
        video_id,
        video_title,
        video_category,
        video_published_at_pt,
        days_since_published,
        calendar_date,
        live_or_on_demand,
        subscribed_status,
        traffic_source_id,
        traffic_source_name,
        traffic_source_detail,
        country_code,
        country_name,
        view_count,
        watch_time_in_minutes,
        average_view_duration_in_seconds,
        red_view_count,
        red_watch_time_in_minutes
    from channel_traffic__video
)

select *
from all_data
