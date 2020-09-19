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

pg_connector = Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    dbname = "postgresqltest2",
    user = "postgres",
    multiple = true,
)

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.execute([DROP TABLE IF EXISTS Employee], db=pg_connector)
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""), db=pg_connector)

Repo.query(Employee, db=sqlite_connector)
Repo.query(Employee, db=pg_connector)

Repo.disconnect(db=sqlite_connector)
Repo.disconnect(db=pg_connector)

end # module adapters_postgresql_multiple_databases_test
