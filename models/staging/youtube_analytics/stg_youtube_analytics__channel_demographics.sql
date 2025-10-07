with channel_demographics as (
    select *
    from {{ source('youtube_analytics__sources', 'channel_demographics_a_1') }}
),

outputs as (
    select
        channel_id,
        date as calendar_date,
        country_code,
        (views_percentage / 100)::dec(18, 6) as share_of_views_this_video_day,
        _fivetran_synced,
        nullif(video_id, '') as video_id,
        initcap(replace(live_or_on_demand, '_', ' ')) as live_or_on_demand,
        initcap(replace(subscribed_status, '_', ' ')) as subscribed_status,
        initcap(replace(gender, '_', ' ')) as gender,
        case
            when age_group = 'AGE_13_17' then 'A. 13-17'
            when age_group = 'AGE_18_24' then 'B. 18-24'
            when age_group = 'AGE_25_34' then 'C. 25-34'
            when age_group = 'AGE_35_44' then 'D. 35-44'
            when age_group = 'AGE_45_54' then 'E. 45-54'
            when age_group = 'AGE_55_64' then 'F. 55-64'
            when age_group = 'AGE_65_' then 'G. 65+'
        end as age_group

    from channel_demographics
)

select
    {{ dbt_utils.generate_surrogate_key([
        'video_id',
        'calendar_date',
        'live_or_on_demand',
        'subscribed_status',
        'country_code',
        'gender',
        'age_group'
    ]) }} as channel_demographics_id,
    *
from outputs
