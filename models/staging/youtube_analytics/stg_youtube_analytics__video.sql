with videos as (
    select *
    from {{ source('youtube_analytics__sources', 'video') }}
),

-- Convert video duration from raw string (e.g. PT10M34S); Add timezone to video publish timestamp
videos_with_calcs as (
    select
        *,
        -- Fields to parse video duration from string; only video_duration_in_seconds will be materialized
        snippet_published_at as published_at_utc_no_timezone,
        regexp_replace(content_details_duration, '[PTS]')
            as video_duration_trimmed,
        zeroifnull(try_to_number(split_part(video_duration_trimmed, 'M', 1)))
            as video_duration_mins,
        zeroifnull(try_to_number(split_part(video_duration_trimmed, 'M', 2)))
            as video_duration_secs,

        -- Trick to add a UTC timezone to a timestamp_ntz, which I then convert to central time
        -- published_at_utc_no_timezone and published_at_utc_with_timezone are helper columns that will not be materialized
        -- TODO: Create an append_timezone user-defined function and refactor this away
        video_duration_mins * 60
        + video_duration_secs as video_duration_in_seconds,
        dateadd(
            hour,
            -1
            * datediff(
                hour,
                published_at_utc_no_timezone::timestamp_ntz,
                convert_timezone(
                    'UTC', published_at_utc_no_timezone
                )::timestamp_ntz
            ),
            convert_timezone('UTC', published_at_utc_no_timezone)
        ) as published_at_utc_with_timezone,
        convert_timezone(
            'America/Los_Angeles', published_at_utc_with_timezone
        ) as published_at_pt
    from videos
),

-- Select and rename the columns to materialize
-- TODO: Bring in region restrictions and other "operational" columns
outputs as (
    select
        id as video_id,
        published_at_pt,
        snippet_channel_id as channel_id,
        snippet_title as video_title,
        video_duration_in_seconds,
        content_details_has_custom_thumbnail as has_custom_thumbnail,
        try_to_number(statistics_view_count)::int as view_count,
        try_to_number(statistics_like_count)::int as like_count,
        try_to_number(statistics_dislike_count)::int as dislike_count,
        try_to_number(statistics_comment_count)::int as comment_count,
        try_to_number(statistics_favorite_count)::int as favorite_count,
        _fivetran_synced,
        nullif(snippet_description, '') as video_description,
        try_to_number(snippet_category_id) as category_id,
        parse_json(snippet_thumbnails) as video_thumbnail_json,
        initcap(privacy_status) as privacy_status
    from videos_with_calcs
)

select *
from outputs
