import duckdb

with duckdb.connect('data.duckdb') as conn:
    df = conn.read_csv("data/JC-202401-citibike-tripdata.csv")
    conn.execute("CREATE TABLE bike_trips AS SELECT * FROM df")
