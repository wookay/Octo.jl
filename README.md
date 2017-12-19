# Octo

```julia
using Octo

struct User <: Octo.Model
end

User.table_name = "users"

u = User()

SQL.repr[SELECT * FROM u] == "SELECT * FROM users"
SQL.repr[SELECT u.name FROM u] == "SELECT name FROM users"
```
