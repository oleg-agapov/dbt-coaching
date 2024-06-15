# Practice 3

## Plan

Let's work with advanced dbt features to make the project even better!

1. ✏️ Create own macro
1. 📦 Install a package and use it
1. 💣 Make a dynamic query with variables
1. 🛠️ Set default materializations

## Create own macro

Let's make a helper macro that simplifies working with dates. Specifically, it will truncate the provided timestamp to a day granularity. It can be done with SQL like this:

```sql
date_trunc('day', timestamp_column)
```

To make a macro you first create a file `/macro/truncate_to_day.sql`:

```sql
{% macro truncate_to_day(col) -%}
    
date_trunc('day', {{ col }})

{%- endmacro %}
```

Now this macro can be used in models. Let's apply it to `fact_daily_trips` model. Right now it looks like this:

```sql
select
    date_trunc('day', started_at) as trip_date,
    rideable_type,
    member_casual,
    count(ride_id) as trips
from {{ ref('stg_bike_trips') }}
group by all
```

We can substitute date conversion with our newly created macro like this:

```sql
select
    {{ truncate_to_day('started_at') }} as trip_date,
    rideable_type,
    member_casual,
    count(ride_id) as trips
from {{ ref('stg_bike_trips') }}
group by all
```

To preview how macro will look in the final model, let's compile that SQL:

```bash
dbt compile -s fact_daily_trips
```

You should see the same code as we had before the refactoring, but now it is using macro instead of a hardcoded `date_trunc()` function.

## Install a package and use it

Now let's install a dbt package. There are many available options from [dbt Hub](https://hub.getdbt.com/). We can start with `dbt-utils` package that provides a lot of useful macros and tests for our project.

Create a new file called `packages.yml` in the root folder of our dbt project. Put there configuration for the packages to install:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.2.0
```

If you want to install more packages just put their config below `dbt_utils` package.

To install the package to our project just run:

```bash
dbt deps
```

Now you are ready to use the package. Let's use a generic test called [not_null_proportion](https://github.com/dbt-labs/dbt-utils/tree/1.2.0/?tab=readme-ov-file#not_null_proportion-source) that tests the column for NULL values, but only returns an error if the percentage of NULLs is below the threshold.

Suppose our `stg_bike_trips` model can contain NULLs, e.g. for cases where the ride wasn't properly started/ended and we didn't generate a unique ID for it. It means that some rows may have empty `ride_id`.

To apply this test let's modify `/models/staging/schema.yml` file to use the test from the package:

```yaml
models:
  - name: stg_bike_trips
    ...
    columns:
      - name: ride_id
        ...
        tests:
          - dbt_utils.not_null_proportion:
              at_least: 0.90
          - unique
```

Here we set a 90% threshold for NULL values. You can test this model as usual:

```bash
dbt test -s stg_bike_trips
```

You should see in the output that the test was applied alongside with build-in tests:

```bash
18:50:10  Found 4 models, 7 data tests, 1 seed, 1 source, 523 macros
18:50:10  
18:50:10  Concurrency: 1 threads (target='dev')
18:50:10  
18:50:10  1 of 5 START test accepted_values_stg_bike_trips_member_casual__member__casual . [RUN]
18:50:10  1 of 5 PASS accepted_values_stg_bike_trips_member_casual__member__casual ....... [PASS in 0.05s]
18:50:10  2 of 5 START test accepted_values_stg_bike_trips_rideable_type__electric_bike__classic_bike  [RUN]
18:50:10  2 of 5 PASS accepted_values_stg_bike_trips_rideable_type__electric_bike__classic_bike  [PASS in 0.03s]
18:50:10  3 of 5 START test dbt_utils_not_null_proportion_stg_bike_trips_0_9__ride_id .... [RUN]
18:50:11  3 of 5 PASS dbt_utils_not_null_proportion_stg_bike_trips_0_9__ride_id .......... [PASS in 0.04s]
18:50:11  4 of 5 START test stg_bike_trips__proper_dates ................................. [RUN]
18:50:11  4 of 5 PASS stg_bike_trips__proper_dates ....................................... [PASS in 0.02s]
18:50:11  5 of 5 START test unique_stg_bike_trips_ride_id ................................ [RUN]
18:50:11  5 of 5 PASS unique_stg_bike_trips_ride_id ...................................... [PASS in 0.04s]
18:50:11  
18:50:11  Finished running 5 data tests in 0 hours 0 minutes and 0.31 seconds (0.31s).
18:50:11  
18:50:11  Completed successfully
18:50:11  
18:50:11  Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5
```

You can check a list of all macros and tests available for this package [here](https://github.com/dbt-labs/dbt-utils/tree/1.2.0/?tab=readme-ov-file#installation-instructions).

Feel free to install and try out any other package of your choice.

## Make a dynamic query with variables

You can make your models even more dynamic with the help of dbt variables functionality.

Let's take our `fact_bike_trips` model. It aggregates daily stats for all bike rides from our dataset. Suppose you want to materialize this dataset only for specific range of dates. You can do that either by providing a hardcoded date range in WHERE clause or by replacing the range with variables, so that you can dynamically pass the values in the runtime (e.g. from command line or from Airflow variables).

First we can start with hardcoded clause like this:

```sql
-- fact_daily_trips.sql
...
from {{ ref('stg_bike_trips') }}
where started_at between '2024-01-01' and '2024-01-10'
...
```

Now we can replace fixed dates with variables from dbt:

```sql
-- fact_daily_trips.sql
...
from {{ ref('stg_bike_trips') }}
where started_at between '{{ var("date_from", "2024-01-01") }}' and '{{ var("date_to", "2024-01-31") }}'
...
```

First we call `var()` macro that can read dbt variables. Next, we specify the name of the variable (`date_from` and `date_to`). Lastly, we can specify default values for variables in case they weren't provided during the run.

Now you can provide variables in the runtimr like so:

```bash
dbt run -s fact_daily_trips --vars '{"date_from": "2024-01-01", "date_to": "2024-01-10"}'
```

If you run the model without any variables provided, default values will be applied.

## Set default materializations

It is considered a best practice to setup a default materializations for your project. We can do that in `dbt_project.yml` file.

Let's set default materializations for our layers (staging, ints, marts) according to what we think is the best for our project. At the bottom of `dbt_project.yml` find a section which called models and put the following config:

```yaml
models:
    my_dbt_project:
        staging:
            +materialized: view
        int:
            +materialized: view
        marts:
            +materialized: table
```

You could also have nested configs for subfolders, like so:

```yaml
models:
    my_dbt_project:
        marts:
            +materialized: table
            core:
                +materialized: view
            finance:
                +materialized: view            
```

The latter config reads as follow:
- default configuration for `/marts` folder is `table`
- but two subfolders called `/core` and `/finance` should have `view` materializations
