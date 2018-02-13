module adapters_sqlite_repo_test

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE

repo = Repo.config(
    adapter = Octo.Adapters.SQLite,
    database = joinpath(dirname(@__FILE__), "test.sqlite")
)

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "EmployeeId"
)

import DataFrames

df = Repo.all(Employee)
@test df isa DataFrames.DataFrame
@test size(df) == (8, 15)

df = Repo.get(Employee, 2)
@test size(df) == (1, 15)

e = from(Employee)
df = Repo.query([SELECT * FROM e WHERE e.EmployeeId == 2])
@test size(df) == (1, 15)

end # module adapters_sqlite_repo_test
