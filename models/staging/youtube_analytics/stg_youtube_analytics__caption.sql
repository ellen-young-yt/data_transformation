with caption as (
    select *
    from {{ source('youtube_analytics__sources', 'caption') }}
),

outputs as (
    select
        video_id,
        languages,
        text as caption_text,
        _fivetran_synced,
        round("START", 3) as start_time_seconds,
        round(duration, 3) as duration_seconds

    from caption
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'start_time_seconds'
    ]) }} as caption_id,
    *
from outputs
