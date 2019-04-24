module adapters_postgresql_structured_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo.connect Schema from SELECT FROM WHERE INNER JOIN ON GROUP BY

struct Weather
end

struct City
end

Schema.model(Weather, table_name="weather")
Schema.model(City, table_name="cities")

w = from(Weather)
c = from(City)

@test to_sql([SELECT * FROM (w, c) WHERE w.city == c.name]) == "SELECT * FROM weather, cities WHERE city = name"
@test to_sql([SELECT * FROM w INNER JOIN c ON w.city == c.name]) == "SELECT * FROM weather INNER JOIN cities ON city = name"

##

struct Distributor
end

struct Film
end

Schema.model(Distributor, table_name="distributors")
Schema.model(Film, table_name="films")

d = from(Distributor, :d)
f = from(Film, :f)

@test to_sql([SELECT (f.title,) FROM (d, f)]) ==
             "SELECT f.title FROM distributors d, films f"

@test to_sql([SELECT (f.title, f.did, d.name, f.date_prod, f.kind) FROM (d, f) WHERE f.did == d.did]) ==
             "SELECT f.title, f.did, d.name, f.date_prod, f.kind FROM distributors d, films f WHERE f.did = d.did"

d = from(Distributor)
f = from(Film)
total = as(SUM(f.len), :total)
@test to_sql([SELECT (f.kind, total) FROM f GROUP BY :kind]) ==
             "SELECT kind, SUM(len) AS total FROM films GROUP BY kind"
@test to_sql([SELECT d.name FROM d WHERE d.name LIKE "W%"]) ==
             "SELECT name FROM distributors WHERE name LIKE 'W%'"
@test to_sql([SELECT * INTO :films_recent FROM f WHERE f.date_prod >= "2002-01-01"]) ==
             "SELECT * INTO films_recent FROM films WHERE date_prod >= '2002-01-01'"

# issue 10
struct Here
end
Schema.model(Here, table_name="heres", primary_key="id")
heres = from(Here, :heres)
@test to_sql([INSERT INTO heres VALUES ("test1", "SR")]) == "INSERT INTO heres VALUES ('test1', 'SR')"

end # module adapters_postgresql_structured_test
