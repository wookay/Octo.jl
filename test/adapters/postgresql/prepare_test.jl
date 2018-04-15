module adapters_postgresql_prepare_test

using Test # @test
using Octo.Adapters.PostgreSQL # Schema PREPARE EXECUTE

struct User
end
Schema.model(User, table_name="users")

struct Log
end
Schema.model(Log, table_name="logs")

u = from(User, :u)
l = from(Log, :l)
H = Octo.PlaceHolder

q = [PREPARE Raw("usrrptplan (int)") AS SELECT * FROM (u, l) WHERE u.usrid == H AND u.usrid == l.usrid AND l.date == H]
@test to_sql(q) == "PREPARE usrrptplan (int) AS SELECT * FROM users u, logs l WHERE u.usrid = \$1 AND u.usrid = l.usrid AND l.date = \$2"

@sql_functions usrrptplan
q = [EXECUTE usrrptplan(1, :current_date)]
@test to_sql(q) == "EXECUTE usrrptplan(1, current_date)"

end # module adapters_postgresql_prepare_test
