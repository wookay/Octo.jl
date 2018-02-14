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

Repo.execute(Raw("""CREATE TABLE Employee (
                     ID SERIAL,
                     Name VARCHAR(255),
                     Salary FLOAT(8),
                     PRIMARY KEY (ID) )
                 """))
Repo.execute(Raw("""INSERT INTO Employee (Name, Salary)
                     VALUES
                     ('John', 10000.50),
                     ('Tom', 20000.25),
                     ('Jim', 30000.00);
                 """))

const ncolumns = 3

struct Employee
end
Schema.model(Employee,
    table_name = "Employee",
    primary_key = "ID"
)
df = Repo.all(Employee)
@test size(df) == (3, ncolumns)

df = Repo.get(Employee, 2)
@test size(df) == (1, ncolumns)
@test df[1, :name] == "Tom"

df = Repo.get(Employee, (Name="Tom",))
@test size(df) == (1, ncolumns)

changes = (Name="Tim", Salary=15000.50)
Repo.insert!(Employee, changes)

df = Repo.all(Employee)
@test size(df) == (4, ncolumns)

df = Repo.get(Employee, (Name="Tim",))
@test size(df) == (1, ncolumns)
@test df[1, :salary] == 15000.50

changes = (ID=2, Name="Chloe")
Repo.update!(Employee, changes)
df = Repo.get(Employee, 2)
@test df[1, :name] == "Chloe"

Repo.delete!(Employee, changes)
df = Repo.get(Employee, 2)
@test size(df) == (0, ncolumns)

Repo.disconnect()

end # module adapters_postgresql_repo_test
