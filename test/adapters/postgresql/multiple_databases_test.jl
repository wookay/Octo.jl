module adapters_postgresql_multiple_databases_test

using Test # @test
using Octo.Adapters.SQLite # Repo Schema from SELECT FROM WHERE

import SQLite # pathof(SQLite)
dbfile = joinpath(dirname(pathof(SQLite)), "..", "test", "Chinook_Sqlite.sqlite")
dbfile2 = joinpath(@__DIR__, "test.sqlite")
cp(dbfile, dbfile2; force=true)
chmod(dbfile2, 0o666)

Repo.debug_sql()

sqlite_connector = Repo.connect(
    adapter = Octo.Adapters.SQLite,
    dbfile = dbfile2,
    multiple = true,
)

using Octo.Adapters.PostgreSQL # Repo Schema Raw

include("options.jl")

pg_connector = Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    multiple = true,
    Options.for_postgresql... 
)

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

for c in (sqlite_connector, pg_connector)
    Repo.execute([DROP TABLE IF EXISTS Employee], db=c)
end
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID INTEGER PRIMARY KEY,
        Name TEXT NOT NULL,
        Salary NUMERIC NOT NULL
    )"""), db=sqlite_connector)
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""), db=pg_connector)

result = Repo.insert!(Employee, (Name = "Jessica", Salary= 70000.50); db=sqlite_connector)
@test keys(result) == (:id, :num_affected_rows)
@test result.num_affected_rows == 1
result = Repo.insert!(Employee, (Name = "Jessica", Salary= 70000.50); db=pg_connector)
@test keys(result) == (:id, :num_affected_rows)
@test result.num_affected_rows == 1

Repo.query(Employee, db=sqlite_connector)
Repo.query(Employee, db=pg_connector)

Repo.disconnect(db=sqlite_connector)
Repo.disconnect(db=pg_connector)

end # module adapters_postgresql_multiple_databases_test
