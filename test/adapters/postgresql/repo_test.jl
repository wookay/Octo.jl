module adapters_postgresql_repo_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

Repo.config(
    adapter = Octo.Adapters.PostgreSQL,
    username = "postgres",
    password = "",
    hostname = "localhost"
)

# using Octo.Adapters.PostgreSQL # DROP DATABASE IF EXISTS CREATE TABLE
Repo.execute([DROP DATABASE IF EXISTS :postgresqltest])
Repo.execute([CREATE DATABASE :postgresqltest])
Repo.disconnect()

Repo.config(
    adapter = Octo.Adapters.PostgreSQL,
    username = "postgres",
    password = "",
    hostname = "localhost",
    database = "postgresqltest"
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
@test size(df) == (6, ncolumns)

df = Repo.get(Employee, 2)
@test size(df) == (1, ncolumns)
@test df[1, :name] == "John"

df = Repo.get(Employee, (Name="Tom",))
@test size(df) == (2, ncolumns)
@test df[1, :name] == "Tom"

changes = (Name="Tim", Salary=15000.50)
Repo.insert!(Employee, changes)
df = Repo.all(Employee)
@test size(df) == (7, ncolumns)
df = Repo.get(Employee, (Name="Tim",))
@test size(df) == (1, ncolumns)
@test df[1, :salary] == 15000.50

changes = (ID=2, Name="Chloe")
Repo.update!(Employee, changes)
df = Repo.get(Employee, 2)
@test df[1, :name] == "Chloe"

changes = (ID=2, Name="Chloe")
Repo.delete!(Employee, changes)
df = Repo.get(Employee, 2)
@test size(df) == (0, ncolumns)

e = from(Employee)
df = Repo.query([SELECT * FROM e WHERE e.Name == "Tim"])
@test size(df) == (1, ncolumns)
@test df[1, :name] == "Tim"

Repo.disconnect()

end # module adapters_postgresql_repo_test
