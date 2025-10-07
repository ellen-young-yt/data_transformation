with channel_cards as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_cards_a_1') }}
),

outputs as (
    select
        channel_id,
        card_id,
        card_type,
        date as calendar_date,
        country_code,
        card_impressions,
        card_clicks,
        card_teaser_impressions,
        card_teaser_clicks,
        _fivetran_synced,
        nullif(video_id, '') as video_id,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status

    from channel_cards
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'card_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code'
    ]) }} as channel_cards_id,
    *
from outputs
