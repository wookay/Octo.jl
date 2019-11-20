module adapters_postgresql_execute_result_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    dbname = "postgresqltest",
    user = "postgres",
)

Repo.execute([DROP TABLE IF EXISTS Employee])
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))

changes = (Name="John", Salary=10000.50)
@test Repo.insert!(Employee, changes).id == 1

changes = (Salary=3000, Name="Mike")
@test Repo.insert!(Employee, changes).id == 2

Repo.disconnect()

end # execute_result_test
