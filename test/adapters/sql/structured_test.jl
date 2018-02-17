module adapters_sql_structured_test

using Test # @test
using Octo.Adapters.SQL # Schema from SELECT FROM WHERE COUNT SUM AVG

struct User
end

u = from(User)
@test_throws Schema.TableNameError to_sql([FROM u])

Schema.model(User, table_name="users")

@test to_sql([FROM u]) == "FROM users"
@test to_sql([SELECT * FROM u]) == "SELECT * FROM users"
@test to_sql([SELECT u.id FROM u]) == "SELECT id FROM users"
@test to_sql([SELECT (u.id, u.name) FROM u]) == "SELECT id, name FROM users"
@test to_sql([WHERE u.id == 2]) == "WHERE id = 2"

u = from(User, :u)
@test to_sql([FROM u]) == "FROM users AS u"
@test to_sql([SELECT (u.id, u.name) FROM u]) == "SELECT u.id, u.name FROM users AS u"
@test to_sql([WHERE u.id == 2]) == "WHERE u.id = 2"
@test to_sql([SELECT (u.id, u.name) FROM u WHERE u.id == 2]) == "SELECT u.id, u.name FROM users AS u WHERE u.id = 2"

@test to_sql([COUNT(*)]) == "COUNT(*)"
@test to_sql([SUM(u.age)]) == "SUM(u.age)"
@test to_sql([AVG(u.age)]) == "AVG(u.age)"

Repo.config(adapter=Octo.Adapters.SQL)
buf = IOBuffer()
show(IOContext(buf, :color=>true), MIME"text/plain"(), [FROM u])
@test String(take!(buf)) == "\e[36mFROM\e[39m \e[0musers \e[36mAS\e[39m \e[0mu"

end # module adapters_sql_structured_test
