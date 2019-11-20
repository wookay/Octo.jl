module adapters_postgresql_boolean_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Raw Schema.model DROP TABLE IF EXISTS SELECT TRUE FALSE

@test to_sql([SELECT (TRUE, FALSE)]) == "SELECT TRUE, FALSE"

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    dbname = "postgresqltest",
    user = "postgres",
)

struct Test1
end
Schema.model(Test1, table_name="test1")

Repo.execute([DROP TABLE IF EXISTS Test1])
Repo.execute(Raw("""
CREATE TABLE IF NOT EXISTS test1 (a boolean, b text)
"""))

Repo.insert!(Test1, (a=true, b="sic est"); returning=nothing)
Repo.insert!(Test1, (a=false, b="non est"); returning=nothing)

df = Repo.query(Test1)
@test Pretty.table(df) == """
|       a | b         |
| ------- | --------- |
|    true | sic est   |
|   false | non est   |
2 rows."""

end # module adapters_postgresql_boolean_test
