module adapters_postgresql_placeholder_test

using Test # @tets
using Octo.Adapters.PostgreSQL # from to_sql Schema.model PlaceHolder SELECT FROM WHERE
import Octo.Adapters.PostgreSQL: placeholder

Repo.set_log_level(Repo.LogLevelDebugSQL)

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    # sink = DataFrames.DataFrame,
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
u = from(User)

❔ = PlaceHolder

# https://en.wikipedia.org/wiki/SQL_injection

# Incorrectly filtered escape characters
userName = """ ' OR '1'='1 """
Repo.query([SELECT * FROM u WHERE u.name == ❔ AND u.salary > ❔], [userName, 2000])

Repo.disconnect()

end # module adapters_postgresql_placeholder_test
