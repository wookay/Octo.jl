module adapters_postgresql_functions_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema SELECT AVG FROM

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

struct User
end
Schema.model(User, table_name="users")

u = from(User)

Repo.execute([DROP TABLE IF EXISTS User])
Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS users (
                     ID SERIAL,
                     name VARCHAR(255),
                     salary FLOAT(8),
                     PRIMARY KEY (ID) )
                 """))

Repo.insert!(User, [
    (Name="Jeremy",  Salary=10000.50),
    (Name="Cloris",  Salary=20000.50),
    (Name="John",    Salary=30000.50),
    (Name="Hyunden", Salary=40000.50),
    (Name="Justin",  Salary=50000.50),
    (Name="Tom",     Salary=60000.50),
])

df = Repo.query([SELECT (AVG(u.salary), MAX(u.salary), MIN(u.salary)) FROM u])
@test Pretty.table(df) == """
|       avg |       max |       min |
| --------- | --------- | --------- |
|   35000.5 |   60000.5 |   10000.5 |
1 row."""

df = Repo.query([SELECT (u.name, u.salary) FROM u ORDER BY u.salary DESC])
@test Pretty.table(df) == """
| name      |    salary |
| --------- | --------- |
| Tom       |   60000.5 |
| Justin    |   50000.5 |
| Hyunden   |   40000.5 |
| John      |   30000.5 |
| Cloris    |   20000.5 |
| Jeremy    |   10000.5 |
6 rows."""

end # module adapters_postgresql_functions_test
