module adapters_sqlite_test

using Test # @test
using Octo # Octo.Model from

struct User <: Octo.Model
end

using Octo.Adapters.SQLite # SELECT FROM WHERE

u = from(User)
@test_throws Octo.SchemaError to_sql([FROM u])

User.schema(table_name="users")

@test to_sql([FROM u]) == "FROM users"
@test to_sql([SELECT * FROM u]) == "SELECT * FROM users"
@test to_sql([SELECT u.id FROM u]) == "SELECT id FROM users"
@test to_sql([SELECT (u.id, u.name) FROM u]) == "SELECT id, name FROM users"
@test to_sql([WHERE u.id == 2]) == "WHERE id = 2"

u = from(User, :u)
@test to_sql([FROM u]) == "FROM users u" #
@test to_sql([SELECT (u.id, u.name) FROM u]) == "SELECT u.id, u.name FROM users u" #
@test to_sql([WHERE u.id == 2]) == "WHERE u.id = 2"
@test to_sql([SELECT (u.id, u.name) FROM u WHERE u.id == 2]) == "SELECT u.id, u.name FROM users u WHERE u.id = 2" #

end # module adapters_sqlite_test
