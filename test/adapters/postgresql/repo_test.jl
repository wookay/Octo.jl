module adapters_postgresql_repo_test

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
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))

changes = (Name="John", Salary=10000.50)
result = Repo.insert!(Employee, changes)
@test result.num_affected_rows == 1

Repo.execute(Raw("""INSERT INTO Employee (Name, Salary) VALUES (\$1, \$2)"""), changes)

multiple_changes = [
    (Name="Tom", Salary=20000.25),
    (Name="Jim", Salary=30000.00),
]
result = Repo.insert!(Employee, multiple_changes)
@test result.num_affected_rows == 2

result = Repo.execute(Raw("""INSERT INTO Employee (Name, Salary) VALUES (\$1, \$2)"""), multiple_changes)
@test result.num_affected_rows == 2

df = Repo.query(Employee)
@test size(df,) == (6,)

df = Repo.get(Employee, 2)
@test size(df) == (1,)
@test df[1].name == "John"

df = Repo.get(Employee, [2, 3])
@test df[1].name == "John"

df = Repo.get(Employee, (2, 3))
@test df[2].name == "Tom"

df = Repo.get(Employee, (Name="Tom",))
@test size(df) == (2,)
@test df[1].name == "Tom"

changes = (Name="Tim", Salary=15000.50)
result = Repo.insert!(Employee, changes)
@test result.num_affected_rows == 1

df = Repo.query(Employee)
@test size(df) == (7,)
df = Repo.get(Employee, (Name="Tim",))
@test size(df) == (1,)
@test df[1].salary == 15000.50

changes = (ID=2, Name="Chloe", Salary=15000.50)
result = Repo.update!(Employee, changes)
@test result.num_affected_rows == 1

df = Repo.get(Employee, 2)
@test df[1].name == "Chloe"

changes = (ID=2, Name="Chloe")
result = Repo.delete!(Employee, changes)
@test result.num_affected_rows == 1

df = Repo.get(Employee, 2)
@test size(df) == (0,)

em = from(Employee)
df = Repo.query([SELECT * FROM em WHERE em.Name == "Tim"])
@test size(df) == (1,)
@test df[1].name == "Tim"

result = Repo.delete!(Employee, [1, 3])
@test result.num_affected_rows == 2

result = Repo.delete!(Employee, (4, 5))
@test result.num_affected_rows == 2

result = Repo.delete!(Employee, 6:7)
@test result.num_affected_rows == 2

df = Repo.query(Employee)
@test size(df) == (0,)

# coverage up
Schema.tables[Base.typename(Employee)] = Dict(:table_name => "Employee")
@test_throws Schema.PrimaryKeyError Repo.get(Employee, 2)
@test_throws Schema.PrimaryKeyError Repo.update!(Employee, (ID=2,))
Repo.insert!(Employee, Vector{NamedTuple}(); returning=nothing)

Repo.disconnect()

end # module adapters_postgresql_repo_test


# https://github.com/wookay/Octo.jl/issues/7
module adapters_postgresql_repo_insert_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

struct Role
end
Schema.model(Role, table_name="roles")

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

Repo.execute([DROP TABLE IF EXISTS Role])
Repo.execute(Raw("""
    CREATE TABLE roles(
      id SERIAL PRIMARY KEY,
      name VARCHAR(255)
    );
    """))
Repo.insert!(Role, (name="tom",))

df = Repo.query(Role)
@test size(df,) == (1,)

Repo.disconnect()

end # module adapters_postgresql_repo_insert_test
