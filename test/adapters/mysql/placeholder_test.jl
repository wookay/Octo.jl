module adapters_mysql_placeholder_test

using Test # @test_throws
using Octo.Adapters.MySQL # from to_sql Schema.model PlaceHolder SELECT FROM WHERE
using Octo.Backends: UnsupportedError

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.MySQL,
    Options.for_mysql...
)

struct User
end
Schema.model(User, table_name="users")

Repo.execute([DROP TABLE IF EXISTS User])
Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS users (
                     ID INT NOT NULL AUTO_INCREMENT,
                     name VARCHAR(255),
                     salary FLOAT(8),
                     PRIMARY KEY (ID) 
                 )"""))

❔ = Octo.PlaceHolder
u = from(User)

userName = """ ' OR '1'='1 """
Repo.query([SELECT * FROM u WHERE u.name == ❔ AND u.salary > ❔], [userName, 2000])

Repo.disconnect()

end # module adapters_mysql_placeholder_test
