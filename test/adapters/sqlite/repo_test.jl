module adapters_sqlite_repo_test

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE

import SQLite # pathof(SQLite)
dbfile = joinpath(dirname(pathof(SQLite)), "..", "test", "Chinook_Sqlite.sqlite")
dbfile2 = joinpath(@__DIR__, "test.sqlite")
cp(dbfile, dbfile2; force=true)
chmod(dbfile2, 0o666)

Repo.debug_sql()

repo = Repo.connect(
    adapter = Octo.Adapters.SQLite,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    dbfile = dbfile2
)

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "EmployeeId"
)

df = Repo.query(Employee)
@test df isa Vector{<:NamedTuple}
@test size(df) == (8,)

df = Repo.get(Employee, 2)
@test size(df) == (1,)

em = from(Employee)
df = Repo.query([SELECT * FROM em WHERE em.EmployeeId == 2])
@test size(df) == (1,)

# using Octo.Adapters.SQLite # CREATE TABLE IF NOT EXISTS
Repo.query([CREATE TABLE IF NOT EXISTS :temp AS SELECT * FROM :Album])

struct Temp
end
Schema.model(Temp, table_name="temp", primary_key="AlbumId")

df = Repo.query(Temp)
@test size(df) == (347,)

changes = (AlbumId=0, Title="Test Album", ArtistId=0)
Repo.insert!(Temp, changes)
df = Repo.query(Temp)
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


❔  = Octo.PlaceHolder

a = from(Temp)
df = Repo.query([SELECT * FROM a WHERE a.Title == ❔  AND a.ArtistId == ❔ ], ["The Doors", 140])
@test size(df) == (1,)

Repo.disconnect()

end # module adapters_sqlite_repo_test
