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


# using Octo.Adapters.SQLite # DROP TABLE IF EXISTS CREATE AS

Repo.query([DROP TABLE IF EXISTS :temp])
Repo.query([CREATE TABLE :temp AS SELECT * FROM :Album])

struct Temp
end
Schema.model(Temp, table_name="temp", primary_key="AlbumId")

df = Repo.all(Temp)
@test size(df) == (347, 3)

changes = (AlbumId=0, Title="Test Album", ArtistId=0)
Repo.insert!(Temp, changes)
df = Repo.all(Temp)
@test size(df) == (348, 3)

df = Repo.get(Temp, 6)
@test df[1, :Title] == "Jagged Little Pill"

changes = (AlbumId=6, Title="Texas")
Repo.update!(Temp, changes)
df = Repo.get(Temp, 6)
@test df[1, :Title] == "Texas"

Repo.delete!(Temp, changes)
df = Repo.get(Temp, 6)
@test size(df) == (0, 3)

end # module adapters_sqlite_repo_test
