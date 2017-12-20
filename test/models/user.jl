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

@test SQL.repr[SELECT DISTINCT (u.name, u.age) FROM u] == "SELECT DISTINCT name, age FROM users"

@test SQL.repr[SELECT * FROM u WHERE u.age > 20] == "SELECT * FROM users WHERE age > 20"
@test SQL.repr[SELECT u.name FROM u WHERE u.age > 20] == "SELECT name FROM users WHERE age > 20"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE u.age > 20] == "SELECT name, age FROM users WHERE age > 20"

@test SQL.repr[SELECT * FROM u WHERE u.age >= 20] == "SELECT * FROM users WHERE age >= 20"
@test SQL.repr[SELECT u.name FROM u WHERE u.age >= 20] == "SELECT name FROM users WHERE age >= 20"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE u.age >= 20] == "SELECT name, age FROM users WHERE age >= 20"

@test SQL.repr[SELECT * FROM u WHERE u.age <= 20] == "SELECT * FROM users WHERE age <= 20"
@test SQL.repr[SELECT u.name FROM u WHERE u.age <= 20] == "SELECT name FROM users WHERE age <= 20"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE u.age <= 20] == "SELECT name, age FROM users WHERE age <= 20"

@test SQL.repr[SELECT * FROM u WHERE 20 < u.age] == "SELECT * FROM users WHERE 20 < age"
@test SQL.repr[SELECT u.name FROM u WHERE 20 <= u.age] == "SELECT name FROM users WHERE 20 <= age"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE 20 >= u.age] == "SELECT name, age FROM users WHERE 20 >= age"

@test SQL.repr[SELECT * FROM u WHERE u.age <= 20] == "SELECT * FROM users WHERE age <= 20"
@test SQL.repr[SELECT u.name FROM u WHERE u.age <= 20] == "SELECT name FROM users WHERE age <= 20"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE u.age <= 20] == "SELECT name, age FROM users WHERE age <= 20"

@test SQL.repr[SELECT * FROM u WHERE u.age < 20] == "SELECT * FROM users WHERE age < 20"
@test SQL.repr[SELECT u.name FROM u WHERE u.age < 20] == "SELECT name FROM users WHERE age < 20"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE u.age < 20] == "SELECT name, age FROM users WHERE age < 20"

@test SQL.repr[SELECT * FROM u WHERE u.age == 20] == "SELECT * FROM users WHERE age = 20"
@test SQL.repr[SELECT * FROM u WHERE (u.name == "John") & (u.age > 20)] == "SELECT * FROM users WHERE name = 'John' AND age > 20"
@test SQL.repr[SELECT u.name FROM u WHERE (u.name == "John") & (u.age > 20)] == "SELECT name FROM users WHERE name = 'John' AND age > 20"
@test SQL.repr[SELECT u.name FROM u WHERE (u.name == "John") & !(u.age > 20)] == "SELECT name FROM users WHERE name = 'John' AND NOT age > 20"
@test SQL.repr[SELECT u.name FROM u WHERE (u.name == "John") | (u.age > 20)] == "SELECT name FROM users WHERE name = 'John' OR age > 20"
@test SQL.repr[SELECT u.name FROM u WHERE (u.name == "John") | !(u.age > 20)] == "SELECT name FROM users WHERE name = 'John' OR NOT age > 20"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE (u.name == "John") & (u.age > 20)] == "SELECT name, age FROM users WHERE name = 'John' AND age > 20"

@test SQL.repr[SELECT DISTINCT * FROM u WHERE u.age == 20] == "SELECT DISTINCT * FROM users WHERE age = 20"

@test SQL.repr[SELECT * FROM u WHERE u.age > 20 LIMIT 5] == "SELECT * FROM users WHERE age > 20 LIMIT 5"
@test SQL.repr[SELECT u.name FROM u WHERE u.age > 20 LIMIT 5] == "SELECT name FROM users WHERE age > 20 LIMIT 5"
@test SQL.repr[SELECT (u.name, u.age) FROM u WHERE u.age > 20 LIMIT 5] == "SELECT name, age FROM users WHERE age > 20 LIMIT 5"

@test SQL.repr[SELECT (u.name, u.score) FROM u WHERE u.score > 3.5 LIMIT 5] == "SELECT name, score FROM users WHERE score > 3.5 LIMIT 5"
