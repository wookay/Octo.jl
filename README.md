# Octo

```julia
julia> using Octo

julia> struct User <: Octo.Model
       end

julia> User.schema(table_name="users")
"users"

julia> using Octo.Adapters.SQL

julia> u = from(User)
Octo.FromClause(User, nothing)

julia> [SELECT * FROM u]
SELECT * FROM users

julia> to_sql([SELECT * FROM u])
"SELECT * FROM users"

julia> to_sql([WHERE u.id == 2])
"WHERE id = 2"
````
