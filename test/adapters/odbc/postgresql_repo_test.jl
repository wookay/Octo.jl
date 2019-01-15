module adapters_odbc_postgresql_repo_test

using Test # @test
using Octo.Adapters.ODBC # Repo Schema

Repo.debug_sql()

Repo.connect(
    adapter  = Octo.Adapters.ODBC,
    database = Octo.DBMS.SQL,
    dsn      = "PgSQL-test",
    username = "postgres",
    password = "",
)

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.execute([DROP TABLE IF EXISTS Employee])
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))

changes = (Name="John", Salary=10000.50)
Repo.insert!(Employee, changes)
changes = (Name="Cloris", Salary=20000.50)
Repo.insert!(Employee, changes)
df = Repo.query(Employee)
@test size(df) == (2,)
@test df == [(id=1, name="John", salary=10000.50),
             (id=2, name="Cloris", salary=20000.50)]

Repo.disconnect()

end # module adapters_odbc_postgresql_repo_test
