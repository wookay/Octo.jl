module adapters_postgresql_transactions_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.debug_sql()

include("options.jl")

# @test_throws Repo.NeedsConnectError Repo.get(Employee, 2)

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

Repo.execute([DROP TABLE IF EXISTS Employee])
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID BIGSERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))

multiple_changes = [
    (Name="Tom", Salary=20000.25),
    (Name="Jim", Salary=30000.00),
]
Repo.insert!(Employee, multiple_changes)

df = Repo.query(Employee)
@test size(df) == (2,)

Repo.delete!(Employee, (Name="Tom",))

df = Repo.query(Employee)
@test size(df) == (1,)

Repo.execute([BEGIN])
Repo.insert!(Employee, (Name="Tom", Salary=20000.25))
Repo.execute([SAVEPOINT :my_savepoint])
try
    Repo.insert!(Employee, (Name2="Tom", Salary=20000.25))
catch
    Repo.execute([ROLLBACK TO SAVEPOINT :my_savepoint])
end
Repo.execute([COMMIT])

df = Repo.query(Employee)
@test size(df) == (2,)

Repo.disconnect()

end # module adapters_postgresql_transactions_test
