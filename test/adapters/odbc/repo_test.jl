module adapters_odbc_repo_test

using Test # @test
using Octo.Adapters.ODBC # Repo Schema

Repo.debug_sql()

Repo.connect(
    adapter  = Octo.Adapters.ODBC,
    Driver   = "/usr/local/lib/psqlodbca.so",
    Database = "postgresqltest",
    Server   = "localhost",
    Port     = 5432,
    username = "postgres",
    password = "",
)

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "ID"
)

Repo.execute([DROP TABLE IF EXISTS :Employee])
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))

changes = (Name="John", Salary=10000.50)
Repo.insert!(Employee, changes)

Repo.disconnect()

end # module adapters_odbc_repo_test
