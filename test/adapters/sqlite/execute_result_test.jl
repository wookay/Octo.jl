module adapters_sqlite_execute_result_test

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
    dbfile = dbfile2
)

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "EmployeeId"
)

Repo.query([CREATE TABLE IF NOT EXISTS :temp AS SELECT * FROM :Album])

struct Temp
end
Schema.model(Temp, table_name="temp", primary_key="AlbumId")

result = Repo.query([DELETE FROM Temp])

result = Repo.execute([DELETE FROM Temp])
@test result === nothing

changes = (AlbumId=0, Title="Test Album", ArtistId=0)
inserted = Repo.insert!(Temp, changes)
@test inserted.id == 1

result = Repo.execute("delete from Temp")
@test result.num_affected_rows == 1

Repo.disconnect()

end # module adapters_sqlite_execute_result_test
