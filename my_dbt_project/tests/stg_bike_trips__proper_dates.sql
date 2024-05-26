select *
from {{ ref('stg_bike_trips') }}
where started_at > ended_at
