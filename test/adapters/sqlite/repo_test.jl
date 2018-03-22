module adapters_sqlite_repo_test

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE
using Pkg # Pkg.dir

dbfile = joinpath(Pkg.dir("SQLite"), "test", "Chinook_Sqlite.sqlite")
dbfile2 = joinpath(dirname(@__FILE__), "test.sqlite")
cp(dbfile, dbfile2; force=true)

Repo.set_log_level(Repo.LogLevelDebugSQL)

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
@test df isa NamedTuple
@test length(df.EmployeeId) == 8

df = Repo.get(Employee, 2)
@test length(df.EmployeeId) == 1

em = from(Employee)
df = Repo.query([SELECT * FROM em WHERE em.EmployeeId == 2])
@test length(df.EmployeeId) == 1


# using Octo.Adapters.SQLite # DROP TABLE IF EXISTS CREATE AS

Repo.query([DROP TABLE IF EXISTS :temp])
Repo.query([CREATE TABLE :temp AS SELECT * FROM :Album])

struct Temp
end
Schema.model(Temp, table_name="temp", primary_key="AlbumId")

df = Repo.all(Temp)
@test length(df.AlbumId) == 347

changes = (AlbumId=0, Title="Test Album", ArtistId=0)
Repo.insert!(Temp, changes)
df = Repo.all(Temp)
@test length(df.AlbumId) == 348

df = Repo.get(Temp, 6)
@test df.Title[1] == "Jagged Little Pill"

df = Repo.get(Temp, (Title="Jagged Little Pill",))
@test df.Title[1] == "Jagged Little Pill"

changes = (AlbumId=6, Title="Texas")
Repo.update!(Temp, changes)
df = Repo.get(Temp, 6)
@test df.Title[1] == "Texas"

Repo.delete!(Temp, changes)
df = Repo.get(Temp, 6)
@test length(df.AlbumId) == 0

end # module adapters_sqlite_repo_test
