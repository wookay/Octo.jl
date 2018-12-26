module adapters_hive_repo_test

using Test # @test
using Octo.Adapters.Hive # Repo Schema Raw USE

Repo.debug_sql()

Repo.connect(adapter=Octo.Adapters.Hive, host="localhost", port=10000)

struct Employee
end
Schema.model(Employee, table_name="employee", primary_key="eid")

Repo.execute([DROP TABLE IF EXISTS :employee])
Repo.execute(Raw("""
CREATE TABLE IF NOT EXISTS employee (eid Int, name String, salary Double)
"""))

Repo.insert!(Employee, [(1, "Jeremy", 10000.50), (2, "Cloris", 20000.50)])

df = Repo.query(Employee)

@test df[1][Symbol("employee.name")] == "Jeremy"
@test df[2][Symbol("employee.name")] == "Cloris"

@test df[1][Symbol("employee.salary")] == 10000.50
@test df[2][Symbol("employee.salary")] == 20000.50

@test size(df) == (2,)

Repo.disconnect()

end # module adapters_hive_repo_test
