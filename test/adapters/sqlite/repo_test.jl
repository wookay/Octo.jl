module adapters_sqlite_array_test

# https://discourse.julialang.org/t/use-julia-array-in-sqlite-query/32049

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE

import SQLite # pathof(SQLite)
dbfile = joinpath(dirname(pathof(SQLite)), "..", "test", "Chinook_Sqlite.sqlite")
dbfile2 = joinpath(@__DIR__, "test.sqlite")
cp(dbfile, dbfile2; force=true)
chmod(dbfile2, 0o666)

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.SQLite,
    dbfile = dbfile2
)

struct Temp
end
Schema.model(Temp, table_name="temp")

Repo.execute([DROP TABLE IF EXISTS Temp])
Repo.execute(Raw("""
    CREATE TABLE Temp (
        id INTEGER PRIMARY KEY,
        label TEXT NOT NULL
    )"""))

Repo.insert!(Temp, [
                    (label="d",),
                    (label="c",),
                    (label="c",),
                    (label="b",),
                    (label="a",)])

df = Repo.query([SELECT * FROM Temp WHERE :label IN ("a","b","c")])
@test size(df) == (4,)

df = Repo.query([SELECT * FROM Temp WHERE :label IN ("a",)])
@test size(df) == (1,)

df = Repo.query([SELECT * FROM Temp WHERE :label IN ()])
@test size(df) == (0,)

Repo.disconnect()

end # module adapters_sqlite_array_test


module adapters_sqlite_repo_test

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE

import SQLite # pathof(SQLite)
dbfile = joinpath(dirname(pathof(SQLite)), "..", "test", "Chinook_Sqlite.sqlite")
dbfile2 = joinpath(@__DIR__, "test.sqlite")
cp(dbfile, dbfile2; force=true)
chmod(dbfile2, 0o666)

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.SQLite,
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

struct Album
end
Schema.model(Album, table_name="temp", primary_key="AlbumId")

df = Repo.query(Album)
@test size(df) == (347,)

changes = (AlbumId=0, Title="Test Album", ArtistId=0)
result = Repo.insert!(Album, changes)
@test result.num_affected_rows == 1

df = Repo.query(Album)
@test size(df) == (348,)

df = Repo.get(Album, 6)
@test df[1].Title == "Jagged Little Pill"

df = Repo.get(Album, (Title="Jagged Little Pill",))
@test df[1].Title == "Jagged Little Pill"

changes = (AlbumId=6, Title="Texas")
result = Repo.update!(Album, changes)
@test result.num_affected_rows == 1

df = Repo.get(Album, 6)
@test df[1].Title == "Texas"

result = Repo.delete!(Album, changes)
@test result.num_affected_rows == 1

result = Repo.delete!(Album, [1, 2, 3])
@test result.num_affected_rows == 3

result = Repo.delete!(Album, (4, 5))
@test result.num_affected_rows == 2

result = Repo.delete!(Album, 11:15)
@test result.num_affected_rows == 5

df = Repo.query(Album)
@test size(df) == (337,)

df = Repo.get(Album, 6)
@test size(df) == (0,)

❔  = Octo.PlaceHolder

a = from(Album)
df = Repo.query([SELECT * FROM a WHERE a.Title == ❔  AND a.ArtistId == ❔ ], ["The Doors", 140])
@test size(df) == (1,)

Repo.disconnect()

end # module adapters_sqlite_repo_test
