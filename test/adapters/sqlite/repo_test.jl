module adapters_sqlite_repo_test

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE
using Pkg # Pkg.dir

dbfile = joinpath(Pkg.dir("SQLite"), "test", "Chinook_Sqlite.sqlite")
dbfile2 = joinpath(dirname(@__FILE__), "test.sqlite")
cp(dbfile, dbfile2; force=true)

Repo.set_log_level(Repo.LogLevelDebugSQL)

repo = Repo.connect(
    adapter = Octo.Adapters.SQLite,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    database = joinpath(dirname(@__FILE__), "test.sqlite")
)

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "EmployeeId"
)

df = Repo.all(Employee)
@test df isa Vector{<:NamedTuple}
@test size(df) == (8,)

df = Repo.get(Employee, 2)
@test size(df) == (1,)

em = from(Employee)
df = Repo.query([SELECT * FROM em WHERE em.EmployeeId == 2])
@test size(df) == (1,)


# using Octo.Adapters.SQLite # DROP TABLE IF EXISTS CREATE AS

Repo.query([DROP TABLE IF EXISTS :temp])
Repo.query([CREATE TABLE :temp AS SELECT * FROM :Album])

struct Temp
end
Schema.model(Temp, table_name="temp", primary_key="AlbumId")

df = Repo.all(Temp)
@test size(df) == (347,)

changes = (AlbumId=0, Title="Test Album", ArtistId=0)
Repo.insert!(Temp, changes)
df = Repo.all(Temp)
@test size(df) == (348,)

df = Repo.get(Temp, 6)
@test df[1].Title == "Jagged Little Pill"

df = Repo.get(Temp, (Title="Jagged Little Pill",))
@test df[1].Title == "Jagged Little Pill"

changes = (AlbumId=6, Title="Texas")
Repo.update!(Temp, changes)
df = Repo.get(Temp, 6)
@test df[1].Title == "Texas"

Repo.delete!(Temp, changes)
df = Repo.get(Temp, 6)
@test size(df) == (0,)

end # module adapters_sqlite_repo_test
