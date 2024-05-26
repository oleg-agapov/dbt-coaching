select
    iso_code,
    latitude,
    longitude,
    country_name 
from {{ ref('countries') }}
