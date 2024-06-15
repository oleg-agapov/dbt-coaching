select
    {{ truncate_to_day('started_at') }} as trip_date,
    rideable_type,
    member_casual,
    count(ride_id) as trips
from {{ ref('stg_bike_trips') }}
where started_at between '{{ var("date_from", "2024-01-01") }}' and '{{ var("date_to", "2024-01-31") }}'
group by all
