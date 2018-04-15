# Octo.jl

|  **Documentation**                        |  **Build Status**                                                                                 |
|:-----------------------------------------:|:-------------------------------------------------------------------------------------------------:|
|  [![][docs-latest-img]][docs-latest-url]  |  [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url]  |


Octo.jl 🐙 is an SQL Query DSL in Julia (https://julialang.org).

It's influenced by Ecto (https://github.com/elixir-ecto/ecto).


## SQL Query DSL

```julia-repl
julia> using Octo.Adapters.SQL

julia> struct User
       end

julia> Schema.model(User, table_name="users")
User => Dict(:primary_key=>"id",:table_name=>"users")

julia> u = from(User)
FromItem users

julia> [SELECT * FROM u]
SELECT * FROM users

julia> [SELECT * FROM u WHERE u.id == 2]
SELECT * FROM users WHERE id = 2

julia> to_sql([SELECT * FROM u WHERE u.id == 2])
"SELECT * FROM users WHERE id = 2"
````


## Repo

Current supported databases: PostgreSQL(via [LibPQ.jl](https://github.com/invenia/LibPQ.jl)), MySQL(via [MySQL.jl](https://github.com/JuliaDatabases/MySQL.jl)), SQLite(via [SQLite.jl](https://github.com/JuliaDatabases/SQLite.jl))

```julia-repl
julia> using Octo.Adapters.PostgreSQL

julia> Repo.debug_sql()
LogLevelDebugSQL::Octo.Repo.RepoLogLevel = -1

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

julia> Repo.execute([DROP TABLE IF EXISTS :Employee])
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

julia> struct Employee
       end

julia> Schema.model(Employee, table_name="Employee", primary_key="ID")
Employee => Dict(:primary_key=>"ID",:table_name=>"Employee")

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
```julia-repl
julia> sub = from([SELECT * FROM em WHERE em.Salary > 30000], :sub)
(SELECT * FROM Employee WHERE Salary > 30000) AS sub

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
 * See the CI logs  [https://travis-ci.org/wookay/Octo.jl/builds/359976228#L602](https://travis-ci.org/wookay/Octo.jl/builds/359976228#L602).


## Requirements

You need latest [Julia 0.7 DEV](https://julialang.org/downloads/nightlies.html).

```julia
using Pkg
Pkg.clone("https://github.com/wookay/Octo.jl.git")
```



[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://wookay.github.io/docs/Octo.jl/

[travis-img]: https://api.travis-ci.org/wookay/Octo.jl.svg?branch=master
[travis-url]: https://travis-ci.org/wookay/Octo.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/fkup126yxtfb62f1/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/wookay/octo-jl/branch/master

[codecov-img]: https://codecov.io/gh/wookay/Octo.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/wookay/Octo.jl
