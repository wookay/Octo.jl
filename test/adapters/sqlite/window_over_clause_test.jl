module adapters_sqlite_window_over_clause_test

using Test # @test_logs
using Octo.Adapters.SQLite # Repo to_sql window SELECT FROM RANK OVER PARTITION BY ORDER DESC

@test_logs (:warn, "SQLite does not support") [SELECT (:depname, :empno, :salary, window([RANK() OVER PARTITION BY :depname ORDER BY :salary DESC])) FROM :empsalary]

end # module adapters_sqlite_window_over_clause_test
