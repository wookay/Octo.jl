module adapters_mysql_test

using Test # @test
using Octo.Adapters.MySQL # Schema from SELECT DISTINCT FROM WHERE GROUP BY HAVING ORDER DESC COUNT

struct User
end

u = from(User)
@test_throws Schema.TableNameError to_sql([FROM u])

Schema.model(User,
    table_name="users"
)

@test to_sql([FROM u]) == "FROM users"
@test to_sql([SELECT * FROM u]) == "SELECT * FROM users"
@test to_sql([SELECT u.id FROM u]) == "SELECT id FROM users"
@test to_sql([SELECT (u.id, u.name) FROM u]) == "SELECT id, name FROM users"
@test to_sql([WHERE u.id == 2]) == "WHERE id = 2"
@test to_sql([WHERE u.id == 2 AND u.name == "John"]) == "WHERE id = 2 AND name = 'John'"

@test to_sql([SELECT COUNT(*) FROM u]) == "SELECT COUNT(*) FROM users"
@test to_sql([SELECT COUNT(u.name) FROM u]) == "SELECT COUNT(name) FROM users"

@test to_sql([SELECT DISTINCT u.name FROM u]) == "SELECT DISTINCT name FROM users"

u = from(User, :u)
@test to_sql([SELECT COUNT(u.name) FROM u          GROUP BY u.name HAVING COUNT(u.name) > 5 ORDER BY COUNT(u.name) DESC]) == 
             "SELECT COUNT(u.name) FROM users AS u GROUP BY u.name HAVING COUNT(u.name) > 5 ORDER BY COUNT(u.name) DESC"

end # module adapters_mysql_test
