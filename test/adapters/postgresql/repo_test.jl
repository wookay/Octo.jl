module adapters_postgresql_repo_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.debug_sql()

@test_throws Repo.NeedsConnectError Repo.get(Employee, 2)

#Repo.connect(
#    adapter = Octo.Adapters.PostgreSQL,
#    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
#    user = "postgres",
#)
#
# using Octo.Adapters.PostgreSQL # DROP DATABASE IF EXISTS CREATE TABLE
#Repo.execute([DROP DATABASE IF EXISTS :postgresqltest])
#Repo.execute([CREATE DATABASE :postgresqltest])
#Repo.disconnect()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    # sink = DataFrames.DataFrame,
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
Repo.insert!(Employee, changes)

Repo.execute(Raw("""INSERT INTO Employee (Name, Salary) VALUES (\$1, \$2)"""), changes)

multiple_changes = [
    (Name="Tom", Salary=20000.25),
    (Name="Jim", Salary=30000.00),
]
result = Repo.insert!(Employee, multiple_changes)
@test result isa Repo.ExecuteResult

Repo.execute(Raw("""INSERT INTO Employee (Name, Salary) VALUES (\$1, \$2)"""), multiple_changes)

df = Repo.query(Employee)
@test size(df,) == (6,)

df = Repo.get(Employee, 2)
@test size(df) == (1,)
@test df[1].name == "John"

df = Repo.get(Employee, (Name="Tom",))
@test size(df) == (2,)
@test df[1].name == "Tom"

changes = (Name="Tim", Salary=15000.50)
Repo.insert!(Employee, changes)
df = Repo.query(Employee)
@test size(df) == (7,)
df = Repo.get(Employee, (Name="Tim",))
@test size(df) == (1,)
@test df[1].salary == 15000.50

changes = (ID=2, Name="Chloe", Salary=15000.50)
Repo.update!(Employee, changes)
df = Repo.get(Employee, 2)
@test df[1].name == "Chloe"

changes = (ID=2, Name="Chloe")
Repo.delete!(Employee, changes)
df = Repo.get(Employee, 2)
@test size(df) == (0,)

em = from(Employee)
df = Repo.query([SELECT * FROM em WHERE em.Name == "Tim"])
@test size(df) == (1,)
@test df[1].name == "Tim"

# coverage up
Schema.tables[Base.typename(Employee)] = Dict(:table_name => "Employee")
@test_throws Schema.PrimaryKeyError Repo.get(Employee, 2)
@test_throws Schema.PrimaryKeyError Repo.update!(Employee, (ID=2,))
Repo.insert!(Employee, Vector{NamedTuple}())

Repo.disconnect()

end # module adapters_postgresql_repo_test
