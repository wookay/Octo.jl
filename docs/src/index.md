# Octo.jl Documentation

Octo.jl 🐙  is an SQL Query DSL in [Julia](https://julialang.org).

It's influenced by [Ecto](https://github.com/elixir-ecto/ecto).


### SQL Query DSL

```julia-repl
julia> using Octo.Adapters.SQL

julia> struct User
       end

julia> Schema.model(User, table_name="users")
User => Dict(:primary_key=>"id",:table_name=>"users")

julia> u = from(User)
Octo.FromClause(User, nothing)

julia> [SELECT * FROM u]
SELECT * FROM users

julia> [SELECT * FROM u WHERE u.id == 2]
SELECT * FROM users WHERE id = 2

julia> to_sql([SELECT * FROM u WHERE u.id == 2])
"SELECT * FROM users WHERE id = 2"
```


### Repo

Current supported databases: PostgreSQL(via [LibPQ.jl](https://github.com/invenia/LibPQ.jl)), MySQL(via [MySQL.jl](https://github.com/JuliaDatabases/MySQL.jl)), SQLite(via [SQLite.jl](https://github.com/JuliaDatabases/SQLite.jl))

```julia
using Octo.Adapters.PostgreSQL

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    dbname = "postgresqltest",
    user = "postgres",
)

Repo.all(Employee)
Repo.get(Employee, 2)
Repo.get(Employee, 2:5)
Repo.get(Employee, (Name="Tim",))
Repo.insert!(Employee, (Name="Tim", Salary=15000.50))
Repo.update!(Employee, (ID=2, Name="Chloe",))
Repo.delete!(Employee, (ID=2,))
Repo.delete!(Employee, 2:5)

em = from(Employee)
Repo.query([SELECT * FROM em WHERE em.Name == "Tim"])

❓ = Octo.PlaceHolder
Repo.query([SELECT * FROM em WHERE em.Name == ❓], ["Tim"])
```
