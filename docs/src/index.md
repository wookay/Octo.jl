# Octo.jl

Octo.jl 🐙 is an SQL Query DSL in [Julia](https://julialang.org).
It also comes with a very useful tool called [Repo](https://github.com/wookay/Octo.jl#repo).
You could `Repo.get`, `Repo.insert!` `Repo.update!` `Repo.delete!` for many database drivers without hand-written SQL.

It's influenced by [Ecto](https://github.com/elixir-ecto/ecto).

## SQL Query DSL

```julia
julia> using Octo.Adapters.SQL

julia> struct User
       end

julia> Schema.model(User, table_name="users")
User => Dict(:primary_key=>"id",:table_name=>"users")

julia> u = from(User)
FromItem users

julia> [SELECT * FROM u]
SELECT * FROM users

julia> [SELECT (u.name, u.salary) FROM u]
SELECT name, salary FROM users

julia> [SELECT * FROM u WHERE u.id == 2]
SELECT * FROM users WHERE id = 2

julia> to_sql([SELECT * FROM u WHERE u.id == 2])
"SELECT * FROM users WHERE id = 2"
```

![structured.svg](https://wookay.github.io/docs/Octo.jl/assets/octo/structured.svg)


## Repo

Current supported database drivers:
  - PostgreSQL(via [LibPQ.jl](https://github.com/invenia/LibPQ.jl))
  - MySQL(via [MySQL.jl](https://github.com/JuliaDatabases/MySQL.jl))
  - SQLite(via [SQLite.jl](https://github.com/JuliaDatabases/SQLite.jl)
  - ODBC(via [ODBC.jl](https://github.com/JuliaDatabases/ODBC.jl))
  - JDBC(via [JDBC.jl](https://github.com/JuliaDatabases/JDBC.jl))

```julia
julia> using Octo.Adapters.PostgreSQL

julia> Repo.debug_sql()
LogLevelDebugSQL::RepoLogLevel = -1

julia> Repo.connect(
           adapter = Octo.Adapters.PostgreSQL,
           dbname = "postgresqltest",
           user = "postgres",
       )
PostgreSQL connection (CONNECTION_OK) with parameters:
  user = postgres
  passfile = /Users/wookyoung/.pgpass
  dbname = postgresqltest
  port = 5432
  client_encoding = UTF8
  application_name = LibPQ.jl
  sslmode = prefer
  sslcompression = 1
  krbsrvname = postgres
  target_session_attrs = any

julia> struct Employee
       end

julia> Schema.model(Employee, table_name="Employee", primary_key="ID")
Employee => Dict(:primary_key=>"ID",:table_name=>"Employee")

julia> Repo.execute([DROP TABLE IF EXISTS Employee])
[ Info: DROP TABLE IF EXISTS Employee

julia> Repo.execute(Raw("""
           CREATE TABLE Employee (
               ID SERIAL,
               Name VARCHAR(255),
               Salary FLOAT(8),
               PRIMARY KEY (ID)
           )"""))
┌ Info: CREATE TABLE Employee (
│     ID SERIAL,
│     Name VARCHAR(255),
│     Salary FLOAT(8),
│     PRIMARY KEY (ID)
└ )

julia> Repo.insert!(Employee, [
           (Name="Jeremy",  Salary=10000.50),
           (Name="Cloris",  Salary=20000.50),
           (Name="John",    Salary=30000.50),
           (Name="Hyunden", Salary=40000.50),
           (Name="Justin",  Salary=50000.50),
           (Name="Tom",     Salary=60000.50),
       ])
[ Info: INSERT INTO Employee (Name, Salary) VALUES ($1, $2)   (Name = "Jeremy", Salary = 10000.5), (Name = "Cloris", Salary = 20000.5), (Name = "John", Salary = 30000.5), (Name = "Hyunden", Salary = 40000.5), (Name = "Justin", Salary = 50000.5), (Name = "Tom", Salary = 60000.5)

julia> Repo.get(Employee, 2)
[ Info: SELECT * FROM Employee WHERE ID = 2
|   id | name     |    salary |
| ---- | -------- | --------- |
|    2 | Cloris   |   20000.5 |
1 row.

julia> Repo.get(Employee, 2:5)
[ Info: SELECT * FROM Employee WHERE ID BETWEEN 2 AND 5
|   id | name      |    salary |
| ---- | --------- | --------- |
|    2 | Cloris    |   20000.5 |
|    3 | John      |   30000.5 |
|    4 | Hyunden   |   40000.5 |
|    5 | Justin    |   50000.5 |
4 rows.

julia> Repo.get(Employee, (Name="Jeremy",))
[ Info: SELECT * FROM Employee WHERE Name = 'Jeremy'
|   id | name     |    salary |
| ---- | -------- | --------- |
|    1 | Jeremy   |   10000.5 |
1 row.

julia> Repo.query(Employee)
[ Info: SELECT * FROM Employee
|   id | name      |    salary |
| ---- | --------- | --------- |
|    1 | Jeremy    |   10000.5 |
|    2 | Cloris    |   20000.5 |
|    3 | John      |   30000.5 |
|    4 | Hyunden   |   40000.5 |
|    5 | Justin    |   50000.5 |
|    6 | Tom       |   60000.5 |
6 rows.

julia> Repo.insert!(Employee, (Name="Jessica", Salary=70000.50))
[ Info: INSERT INTO Employee (Name, Salary) VALUES ($1, $2)   (Name = "Jessica", Salary = 70000.5)

julia> Repo.update!(Employee, (ID=2, Salary=85000))
[ Info: UPDATE Employee SET Salary = $1 WHERE ID = 2   85000

julia> Repo.delete!(Employee, (ID=3,))
[ Info: DELETE FROM Employee WHERE ID = 3

julia> Repo.delete!(Employee, 3:5)
[ Info: DELETE FROM Employee WHERE ID BETWEEN 3 AND 5

julia> em = from(Employee)
FromItem Employee

julia> Repo.query(em)
[ Info: SELECT * FROM Employee
|   id | name      |    salary |
| ---- | --------- | --------- |
|    1 | Jeremy    |   10000.5 |
|    6 | Tom       |   60000.5 |
|    7 | Jessica   |   70000.5 |
|    2 | Cloris    |   85000.0 |
4 rows.

julia> Repo.query([SELECT * FROM em WHERE em.Name == "Cloris"])
[ Info: SELECT * FROM Employee WHERE Name = 'Cloris'
|   id | name     |    salary |
| ---- | -------- | --------- |
|    2 | Cloris   |   85000.0 |
1 row.

julia> Repo.query(em, (Name="Cloris",))
[ Info: SELECT * FROM Employee WHERE Name = 'Cloris'
|   id | name     |    salary |
| ---- | -------- | --------- |
|    2 | Cloris   |   85000.0 |
1 row.

julia> ❓ = Octo.PlaceHolder
PlaceHolder

julia> Repo.query([SELECT * FROM em WHERE em.Name == ❓], ["Cloris"])
[ Info: SELECT * FROM Employee WHERE Name = $1   "Cloris"
|   id | name     |    salary |
| ---- | -------- | --------- |
|    2 | Cloris   |   85000.0 |
1 row.
```

### Subqueries

```julia
julia> sub = from([SELECT * FROM em WHERE em.Salary > 30000], :sub)
SubQuery (SELECT * FROM Employee WHERE Salary > 30000) AS sub

julia> Repo.query(sub)
[ Info: SELECT * FROM Employee WHERE Salary > 30000
|   id | name      |    salary |
| ---- | --------- | --------- |
|    6 | Tom       |   60000.5 |
|    7 | Jessica   |   70000.5 |
|    2 | Cloris    |   85000.0 |
3 rows.

julia> Repo.query([SELECT sub.Name FROM sub])
[ Info: SELECT sub.Name FROM (SELECT * FROM Employee WHERE Salary > 30000) AS sub
| name      |
| --------- |
| Tom       |
| Jessica   |
| Cloris    |
3 rows.
```


## Colored SQL statements

![colored_sql_statements.png](https://raw.github.com/wookay/Octo.jl/master/docs/images/colored_sql_statements.png)

 * See the CI logs  [https://travis-ci.org/wookay/Octo.jl/jobs/388090148#L691](https://travis-ci.org/wookay/Octo.jl/jobs/388090148#L691).


## Requirements

You need [Julia 1.0](https://julialang.org/downloads/).

`julia>` type `]` key

```julia
(v1.0) pkg> add Octo
```

```julia
(v1.0) pkg> add LibPQ   # for PostgreSQL (depends on LibPQ.jl v0.9.1)
(v1.0) pkg> add SQLite  # for SQLite (depends on SQLite.jl v0.8.1)
(v1.0) pkg> add MySQL   # for MySQL (depends on MySQL.jl v0.7.0)
(v1.0) pkg> add ODBC    # for ODBC (depends on ODBC.jl v0.8.1)
(v1.0) pkg> add JDBC    # for JDBC (depends on JDBC.jl v0.4.0)
```
