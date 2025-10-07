with channel as (
    select *
    from {{ source('youtube_analytics__sources', 'channel') }}
),

outputs as (
    select
        id as channel_id,
        snippet_title as title,
        snippet_custom_url as custom_url,
        snippet_description as description,
        statistics_view_count as number_of_views,
        statistics_subscriber_count as number_of_subscribers,
        statistics_video_count as number_of_videos,
        _fivetran_synced,
        parse_json(snippet_thumbnails) as thumbnails_json,
        parse_json(topic_details):topicIds as topic_ids
    from channel
)

select *
from outputs
