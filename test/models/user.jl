using Octo
using Test

struct User <: Octo.Model
end

User.table_name = "users"

u = User()

@test SQL.repr[u] == "users"
@test SQL.repr[FROM u] == "FROM users"
@test SQL.repr[SELECT * FROM u] == "SELECT * FROM users"
@test SQL.repr[SELECT u.name FROM u] == "SELECT name FROM users"
@test SQL.repr[SELECT u.age FROM u] == "SELECT age FROM users"
@test SQL.repr[SELECT (u.name, u.age) FROM u] == "SELECT name, age FROM users"
