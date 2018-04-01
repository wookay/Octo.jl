module test_octo_aggregates

using Test
using Octo.Adapters.SQL

struct T
end

t = from(T)
@test to_sql([AVG(t.salary)]) == "AVG(salary)"

s = as(AVG(t.salary), :s)
@test to_sql([s]) == "AVG(salary) AS s"


import Octo: @sql_functions

@sql_functions A

@test to_sql([A(2,3)]) == "A(2, 3)"

end # module test_octo_aggregates
