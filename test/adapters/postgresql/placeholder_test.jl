module adapters_postgresql_placeholder_test

using Test # @test
using Octo.Adapters.PostgreSQL # from to_sql Schema.model PlaceHolder SELECT FROM WHERE

Repo.set_log_level(Repo.LogLevelDebugSQL)

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    dbname = "postgresqltest",
    user = "postgres",
)

Repo.execute([DROP TABLE IF EXISTS :users])
Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS users (
                     ID SERIAL,
                     name VARCHAR(255),
                     salary FLOAT(8),
                     PRIMARY KEY (ID) )
                 """))

struct User
end

Schema.model(User, table_name="users")

❔ = Octo.PlaceHolder

# https://en.wikipedia.org/wiki/SQL_injection

u = from(User)
userName = """ ' OR '1'='1 """ # Incorrectly filtered escape characters
df = Repo.query([SELECT * FROM u WHERE u.name == ❔ AND u.salary > ❔], [userName, 2000])
@test size(df) == (0,)

Repo.disconnect()

end # module adapters_postgresql_placeholder_test
