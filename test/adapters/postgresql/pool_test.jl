module adapters_postgresql_pool_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.debug_sql()

include("options.jl")

pool1 = Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

pool2 = Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    multiple = true,
    merge(Options.for_postgresql, (dbname = "postgresqltest2",))...
)

for pool in (pool1, pool2)
    Repo.execute([DROP TABLE IF EXISTS Employee], db=pool)
    Repo.execute(Raw("""
        CREATE TABLE Employee (
            ID SERIAL,
            Name VARCHAR(255),
            Salary FLOAT(8),
            PRIMARY KEY (ID)
        )"""), db=pool)
end

changes = (Name="John", Salary=10000.50)
Repo.insert!(Employee, changes)

df = Repo.query(Employee)
@test size(df,) == (1,)

df = Repo.query(Employee, db=pool1)
@test size(df,) == (1,)

df = Repo.query(Employee, db=pool2)
@test size(df,) == (0,)

changes = (Name="John", Salary=10000.50)
Repo.insert!(Employee, changes, db=pool2)

df = Repo.query(Employee, db=pool2)
@test size(df,) == (1,)

Repo.disconnect(db=pool2)
Repo.disconnect()

end # module adapters_postgresql_pool_test
