module test_octo_functions

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

@test to_sql([NOT(t.salary > 100)]) == "NOT(salary > 100)"
@test to_sql([SOME(t.salary > 100)]) == "SOME(salary > 100)"
@test to_sql([EVERY(t.salary > 100)]) == "EVERY(salary > 100)"

end # module test_octo_functions
