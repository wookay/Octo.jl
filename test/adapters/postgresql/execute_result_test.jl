module adapters_postgresql_execute_result_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

result = Repo.execute([DROP TABLE IF EXISTS Employee])
@test result === nothing

result = Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))
@test result === nothing

changes = (Name="John", Salary=10000.50)
@test Repo.insert!(Employee, changes).id == 1

changes = (Salary=3000, Name="Mike")
@test Repo.insert!(Employee, changes).id == 2

struct Test1
end
Schema.model(Test1, table_name="test1", primary_key=nothing)
result = Repo.execute([DROP TABLE IF EXISTS Test1])
@test result === nothing

result = Repo.execute(Raw("""
CREATE TABLE IF NOT EXISTS test1 (a boolean, b text)
"""))
@test result === nothing

result = Repo.insert!(Test1, (a=true, b="sic est"))
@test result == (num_affected_rows = 1,)
result = Repo.insert!(Test1, (a=true, b="sic est"); returning=nothing)
@test result == (num_affected_rows = 1,)

struct Test2
end
Schema.model(Test2, table_name="test2", primary_key=("a", "b"))
Repo.execute([DROP TABLE IF EXISTS Test2])
Repo.execute(Raw("""
CREATE TABLE IF NOT EXISTS test2 (a boolean, b text, PRIMARY KEY (a, b))
"""))

result = Repo.insert!(Test2, (a=true, b="sic est1"))
@test result == (a=true, b="sic est1", num_affected_rows=1)
result = Repo.insert!(Test2, (a=true, b="sic est2"); returning=nothing)
@test result == (num_affected_rows = 1,)
result = Repo.insert!(Test2, (a=true, b="sic est3"); returning=[:a])
@test result == (a=true, num_affected_rows=1)
result = Repo.insert!(Test2, (a=true, b="sic est4"); returning=[:a, :b])
@test result == (a=true, b="sic est4", num_affected_rows=1)
result = Repo.insert!(Test2, (a=true, b="sic est5"); returning=[:b, :a])
@test result == (b="sic est5", a=true, num_affected_rows=1)

Repo.disconnect()

end # module adapters_postgresql_execute_result_test
