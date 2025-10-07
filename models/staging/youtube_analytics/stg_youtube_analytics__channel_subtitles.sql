with channel_subtitles as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_subtitles_a_2') }}
),

outputs as (
    select
        channel_id,
        video_id,
        date as calendar_date,
        country_code,
        views as view_count,
        watch_time_minutes::dec(18, 2) as watch_time_in_minutes,
        average_view_duration_seconds::dec(18, 2)
            as average_view_duration_in_seconds,
        (average_view_duration_percentage / 100)::dec(18, 4)
            as average_view_duration_percentage,
        red_views as red_view_count,
        red_watch_time_minutes::dec(18, 2) as red_watch_time_in_minutes,
        _fivetran_synced,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status,
        nullif(subtitle_language, '') as subtitle_language,
        nullif(subtitle_language_autotranslated, '')
            as subtitle_language_autotranslated

    from channel_subtitles
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'subtitle_language',
        'subtitle_language_autotranslated'
    ]) }} as channel_subtitles_id,
    *
from outputs
