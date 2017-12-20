# Octo

```julia
julia> using Octo

julia> struct User <: Octo.Model
       end

julia> User.table_name = "users"
"users"

julia> u = User()
User()

julia> SQL.repr[SELECT * FROM u]
"SELECT * FROM users"

julia> SQL.repr[SELECT u.name FROM u]
"SELECT name FROM users"
```

```julia
julia> using Octo

julia> struct User <: Octo.Model
       end

julia> struct Article <: Octo.Model
       end

julia> User.table_name = "users"
"users"

julia> Article.table_name = "articles"
"articles"

julia> u = User()
User()

julia> a = Article()
Article()

julia> SQL.repr[SELECT (a.title, u.age) FROM a INNER JOIN u ON u.id == a.user_id]
"SELECT articles.title, users.age FROM articles INNER JOIN users ON users.id = articles.user_id"
````
