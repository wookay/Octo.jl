module adapters_postgresql_window_over_clause_test

using Test # @test
using Octo.Adapters.PostgreSQL # to_sql window SELECT FROM RANK OVER PARTITION BY ORDER DESC

@test to_sql([SELECT (:depname, :empno, :salary, window([RANK() OVER PARTITION BY :depname ORDER BY :salary DESC])) FROM :empsalary]) ==
             "SELECT depname, empno, salary, RANK() OVER (PARTITION BY depname ORDER BY salary DESC) FROM empsalary"

@test to_sql([SELECT (:depname, :empno, :salary, window([RANK() OVER PARTITION BY :depname ORDER BY :salary DESC], :w)) FROM :empsalary]) ==
             "SELECT depname, empno, salary, RANK() OVER (PARTITION BY depname ORDER BY salary DESC) AS w FROM empsalary"

end # module adapters_postgresql_window_over_clause_test
