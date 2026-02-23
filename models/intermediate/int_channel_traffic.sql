with channel_traffic as (
    select
        ct.channel_traffic_id,
        ct.channel_id,
        ct.video_id,
        ct.calendar_date,
        ct.live_or_on_demand,
        ct.subscribed_status,
        ct.traffic_source_id,
        {# documentation on traffic sources: https://developers.google.com/youtube/reporting/v1/reports/dimensions#Traffic_Source_Dimensions #}
        ts.traffic_source_name,
        ct.traffic_source_detail_raw,
        ct.country_code,
        cc.country_name,
        ct.view_count,
        ct.watch_time_in_minutes,
        ct.average_view_duration_in_seconds,
        ct.red_view_count,
        ct.red_watch_time_in_minutes
    from {{ ref("stg_youtube_analytics__channel_traffic") }} as ct
    left join {{ ref("country_codes_lookup") }} as cc on ct.country_code = cc.country_code
    left join
        {{ ref("traffic_source_lookup") }} as ts
        on ct.traffic_source_id = ts.traffic_source_id
)

select *
from channel_traffic
