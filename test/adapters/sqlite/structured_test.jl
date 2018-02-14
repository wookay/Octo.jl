module adapters_sqlite_structured_test

using Test # @test
using Octo.Adapters.SQLite # Schema from SELECT FROM WHERE

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
@test to_sql([FROM u]) == "FROM users u" #
@test to_sql([SELECT (u.id, u.name) FROM u]) == "SELECT u.id, u.name FROM users u" #
@test to_sql([WHERE u.id == 2]) == "WHERE u.id = 2"
@test to_sql([SELECT (u.id, u.name) FROM u WHERE u.id == 2]) == "SELECT u.id, u.name FROM users u WHERE u.id = 2" #

# using Octo.Adapters.SQLite # INSERT INTO VALUES UPDATE SET
using Octo.Adapters.SQLite: Enclosed, QuestionMark

struct Temp
end
Schema.model(Temp, table_name="temp")

temp = from(Temp)
paramholders = Enclosed(fill(QuestionMark, 3))
@test to_sql([INSERT INTO temp VALUES paramholders]) == "INSERT INTO temp VALUES (?, ?, ?)"
@test to_sql([UPDATE temp SET (title="Texas",) WHERE temp.AlbumId == 6]) == "UPDATE temp SET title = 'Texas' WHERE AlbumId = 6"

end # module adapters_sqlite_structured_test
