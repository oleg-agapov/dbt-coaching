select distinct
    start_station_id as station_id,
    start_station_name as station_name,
from {{ ref('all_trips') }}

union

select distinct
    end_station_id as station_id,
    end_station_name as station_name,
from {{ ref('all_trips') }}
