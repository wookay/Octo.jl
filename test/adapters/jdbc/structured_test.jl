module adapters_jdbc_structured_test

using Test
using Octo.Adapters.JDBC

struct User
end
Schema.model(User, table_name="users")

@test to_sql([FROM User]) == "FROM users"

u = from(User)
@test to_sql([FROM u]) == "FROM users"

end # module adapters_jdbc_structured_test
