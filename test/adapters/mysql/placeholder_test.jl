module adapters_mysql_placeholder_test

using Test # @test_throws
using Octo.Adapters.MySQL # from to_sql Schema.model PlaceHolder SELECT FROM WHERE
import Octo.Backends: UnsupportedError

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.MySQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    username = "root",
    password = "",
    hostname = "localhost",
    port = 3306
)

Repo.execute([USE :mysqltest])

Repo.execute([DROP TABLE IF EXISTS :users])
Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS users (
                     ID INT NOT NULL AUTO_INCREMENT,
                     name VARCHAR(255),
                     salary FLOAT(8),
                     PRIMARY KEY (ID) 
                 )"""))

struct User
end

Schema.model(User, table_name="users")
u = from(User)

❔ = Octo.PlaceHolder

userName = """ ' OR '1'='1 """
@test_throws UnsupportedError Repo.query([SELECT * FROM u WHERE u.name == ❔ AND u.salary > ❔], [userName, 2000])

Repo.disconnect()

end # module adapters_mysql_placeholder_test
