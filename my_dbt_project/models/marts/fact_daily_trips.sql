select
    date_trunc('day', started_at) as trip_date,
    rideable_type,
    member_casual,
    count(ride_id) as trips
from {{ ref('stg_bike_trips') }}
group by all
