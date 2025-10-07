with channel_sharing_service as (
    select *
    from
        {{ source('youtube_analytics__sources', 'channel_sharing_service_a_1') }}
),

outputs as (
    select
        channel_id,
        video_id,
        date as calendar_date,
        sharing_service as sharing_service_id,
        country_code,
        shares as share_count,
        _fivetran_synced,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status

    from channel_sharing_service
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'sharing_service_id'
    ]) }} as channel_sharing_service_id,
    *
from outputs
