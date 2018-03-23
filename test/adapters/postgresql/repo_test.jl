module adapters_postgresql_repo_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

Repo.set_log_level(Repo.LogLevelDebugSQL)

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    user = "postgres",
)

# using Octo.Adapters.PostgreSQL # DROP DATABASE IF EXISTS CREATE TABLE
Repo.execute([DROP DATABASE IF EXISTS :postgresqltest])
Repo.execute([CREATE DATABASE :postgresqltest])
Repo.disconnect()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    # sink = DataFrames.DataFrame,
    dbname = "postgresqltest",
    user = "postgres",
)

const ncolumns = 3
Repo.execute(Raw("""CREATE TABLE Employee (
                     ID SERIAL,
                     Name VARCHAR(255),
                     Salary FLOAT(8),
                     PRIMARY KEY (ID) )
                 """))

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "ID"
)

changes = (Name="John", Salary=10000.50)
Repo.insert!(Employee, changes)

Repo.execute(Raw("""INSERT INTO Employee (Name, Salary) VALUES (\$1, \$2)"""), changes)

multiple_changes = [
    (Name="Tom", Salary=20000.25),
    (Name="Jim", Salary=30000.00),
]
Repo.insert!(Employee, multiple_changes)

Repo.execute(Raw("""INSERT INTO Employee (Name, Salary) VALUES (\$1, \$2)"""), multiple_changes)

df = Repo.all(Employee)
@test size(df,) == (6,)

df = Repo.get(Employee, 2)
@test size(df) == (1,)
@test df[1].name == "John"

df = Repo.get(Employee, (Name="Tom",))
@test size(df) == (2,)
@test df[1].name == "Tom"

changes = (Name="Tim", Salary=15000.50)
Repo.insert!(Employee, changes)
df = Repo.all(Employee)
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

Repo.disconnect()

end # module adapters_postgresql_repo_test