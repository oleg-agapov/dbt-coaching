# Practice 1

## Plan

We gonna create a dbt project from scratch, using local database called DuckDB. There will be a couple of models to start with, so that we can test all the functionality from the session.

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

We have sample dataset of bike trips in `/data` folder. Let's create a DuckDB database with that data.

Run Python script to create a database:

```bash
python upload_raw_data.py
```

This will create DuckDB file called `data.duckdb`.

On the next step we will connect it to the dbt project.

> If you want to re-create the database file from scratch, just delete `data.duckdb` and run the script once again.

## Connect to the database

Open database configuration file:

```bash
code ~/.dbt/profiles.yml
```

Change path value to the path of the newly created database file:

```yaml
path: /workspaces/dbt-coaching/data.duckdb
```

Here is example of how to connect to a Snowflake:

```yaml
my_dbt_project:
  outputs:
    dev:
      type: snowflake
      account: [account_id]
      user: [username]
      password: [password]
      role: [user role]
      database: [database name]
      warehouse: [warehouse name]
      schema: [dbt schema]

  target: dev
```

Check that dbt can “talk” to the DB:

```bash
cd my_dbt_project
dbt debug
```

You should see something similar:
```
03:14:12  Running with dbt=1.8.0
03:14:12  dbt version: 1.8.0
03:14:12  python version: 3.10.13
03:14:12  python path: /workspaces/dbt-coaching/venv/bin/python
03:14:12  os info: Linux-6.5.0-1019-azure-x86_64-with-glibc2.31
03:14:12  Using profiles dir at /home/codespace/.dbt
03:14:12  Using profiles.yml file at /home/codespace/.dbt/profiles.yml
03:14:12  Using dbt_project.yml file at /workspaces/dbt-coaching/my_dbt_project/dbt_project.yml
03:14:12  adapter type: duckdb
03:14:12  adapter version: 1.8.0
03:14:13  Configuration:
03:14:13    profiles.yml file [OK found and valid]
03:14:13    dbt_project.yml file [OK found and valid]
03:14:13  Required dependencies:
03:14:13   - git [OK found]

03:14:13  Connection:
03:14:13    database: data
03:14:13    schema: main
03:14:13    path: /workspaces/dbt-coaching/data.duckdb
03:14:13    config_options: None
03:14:13    extensions: None
03:14:13    settings: None
03:14:13    external_root: .
03:14:13    use_credential_provider: None
03:14:13    attach: None
03:14:13    filesystems: None
03:14:13    remote: None
03:14:13    plugins: None
03:14:13    disable_transactions: False
03:14:13  Registered adapter: duckdb=1.8.0
03:14:13    Connection test: [OK connection ok]

03:14:13  All checks passed!
```

> Important: all the commands from now on you should run from `/my_dbt_project` folder, otherwise you get an error.

## Define sources and seeds

First, you can remove `/example` subfolder from `/models`.

Create `models/sources.yml` file and describe `bike_trips` table:

```yaml
sources:
  - name: raw_data
    database: data
    schema: main
    tables:
      - name: bike_trips
```

Now let’s preview the source with inline query:

```bash
dbt show --inline "select * from {{ source('raw_data', 'bike_trips') }}"
```

Copy `/data/countries.csv` file to `/seeds` folder of the dbt project.

Create `/seeds/seeds.yml` file with seeds configs:

```yaml
seeds:
  - name: countries
    config:
      column_types:
        iso_code: varchar
        latitude: double
        longitude: double
        country_name: varchar
```

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
from {{ source('raw_data', 'bike_trips') }}
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

To run a specific model, try node selection syntax:

```
dbt run -s daily_trips

# or with parents
dbt run -s +daily_trips
```

You can now preview tables using dbt show command, like this:

```bash
dbt show -s bike_stations
```

You can change the materialization type from view (default) to table in dbt_project.yml:

```yaml
...

models:
  my_dbt_project:
    +materialized: table
```

Try to redefine `daily_trips` model back to view using `{{ config() }}` block in the model itself.

## Commit changes to the repo

To commit your changes back to Github you need to so 3 steps.

**Step 1**. add all files to git staging area:
```bash
git add .  
```

**Step 2**. commit changes with the message descibing the changes:
```bash
git commit -m "add dbt project files" 
```

**Step 3**. push changes to Github repo:
```bash
git push
```
