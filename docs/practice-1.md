# Practice 1

## Plan

1. 🦆 Install dbt with duck-db adapter
1. 🐣 Bootstrap a new dbt project
1. ➡️ Upload raw data
1. 🔗 Connect to the database
1. 🌱 Define sources and seeds
1. 📃 Create and run a few models
1. 💾 Commit changes to the repo

## Install dbt with duck-db adapter

> First, make sure that you forked the repo and working in your own environment (see main [README.MD](../README.md)).

Create virtual environment:

```bash
python -m venv venv
```

Activate the environment and install requirements:

```bash
source venv/bin/activate
pip install -r requirements.txt
```

Check if dbt was installed:

```bash
dbt --version
```

Starter repository.


## Bootstrap a new dbt project

To create a new dbt project run:

```bash
dbt init
```

You need to provide some information:
- name of the project
- adapter you want to use (duckdb)

After that you should see a new folder with the bootstrapped project.

## Upload raw data

Run Python script to create a database:

```bash
python upload_raw_data.py
```

This will create DuckDB file called `data.duckdb`.

On the next step we will connect it to the dbt project.

## Connect to the database

Open database configuration file:

```bash
code ~/.dbt/profiles.yml
```

Change path value to the path of the newly created database file:

```
path: /workspaces/dbt-coaching/data.duckdb
```

(See example of Snowflake connection in a sample config at data/profiles.yml)

Check that dbt can “talk” to the DB:

```bash
cd my_dbt_project
dbt debug
```

## Define sources and seeds

Create models/sources.yml file and describe bike_trips table.

Now let’s preview the source with inline query:

```bash
dbt show --inline “...”
```

Copy data/countries.csv file to /seeds folder of the dbt project.

Create `/seeds/seeds.yml` file with seeds configs:

Now you can materialize seed in the DB:

```bash
dbt seed
```

## Create and run a few models

Now let's create a few models for our project. All files should be created in `/models` folder.

Create `all_trips.sql` model that will represent our raw data table:

```sql
select
    ride_id,
    rideable_type,
    started_at,
    ended_at,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual
from {{ source('raw', 'bike_trips') }}
```

Next, in our dataset there is info about bike stations. Let's create another model that describes all stations (`bike_stations.sql`):

```sql
select distinct
    start_station_id as station_id,
    start_station_name as station_name,
from {{ ref('all_trips') }}

union

select distinct
    end_station_id as station_id,
    end_station_name as station_name,
from {{ ref('all_trips') }}
```

Now let's make a table that calculates daily trips by bike and member types (`daily_trips.sql`):

```sql
select
    date_trunc('day', started_at) as trip_date,
    rideable_type,
    member_casual,
    count(ride_id) as trips
from {{ ref('all_trips') }}
group by all
```

Finally, let's create a model that represents our countries seed (`all_counties.sql`):

```sql
select
    iso_code,
    latitude,
    longitude,
    country_name 
from {{ ref('countries') }}
```

To materialize all models in the database you can run:

```sql
dbt run
```

You can now preview tables using dbt show command, like this:

```bash
dbt show -s bike_stations
```

## Commit changes to the repo

To commit your changes back to Github you need to so 3 steps.

**Step 1**. add all files to git staging area:
```bash
git add .  
```

**Step 2**. commit changes with the message descibing the changes:
```bash
git commit -m "..." 
```

**Step 3**. push changes to Github repo:
```bash
git push
```
