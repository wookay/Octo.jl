# Octo.jl

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://wookay.github.io/docs/Octo.jl/)

Octo.jl 🐙 is an SQL Query DSL in Julia (https://julialang.org).

It's influenced by Ecto (https://github.com/elixir-ecto/ecto).


```julia
julia> using Octo.Adapters.SQL

julia> struct User
       end

julia> Schema.model(User, table_name="users")
"users"

julia> u = from(User)
Octo.FromClause(User, nothing)

julia> [SELECT * FROM u]
SELECT * FROM users

julia> [SELECT * FROM u WHERE u.id == 2]
SELECT * FROM users WHERE id = 2

julia> to_sql([SELECT * FROM u WHERE u.id == 2])
"SELECT * FROM users WHERE id = 2"
````
