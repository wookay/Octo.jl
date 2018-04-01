module test_octo_as

using Test
using Octo.Adapters.SQL # from to_sql

@test to_sql([as(AVG(:n), :avg_n)]) == "AVG(n) AS avg_n"

struct User
end

u = from(User)
n = as(u.name, :n)

@test to_sql([n]) == "name AS n"

end # module test_octo_as
