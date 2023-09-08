module adapters_duckdb_repo_uuid_test

using Test # @test
using Octo.Adapters.DuckDB # Repo Schema Raw
using UUIDs # uuid4

struct UUIDTest
end
Schema.model(UUIDTest, table_name="uuid_test")

Repo.debug_sql()

Repo.connect(; adapter = Octo.Adapters.DuckDB)

# https://github.com/marcboeker/go-duckdb/blob/master/duckdb_test.go
Repo.execute([DROP TABLE IF EXISTS UUIDTest])
Repo.execute(Raw("""
    CREATE TABLE uuid_test(uuid UUID)
    """))

uuid = uuid4()
result = Repo.insert!(UUIDTest, (uuid=string(uuid),))
@test result == (Count=1,)

df = Repo.query(UUIDTest)
@test size(df) == (1, 1)

result = Repo.delete!(UUIDTest, (uuid=string(uuid),))
@test result == (Count=1,)

df = Repo.query(UUIDTest)
@test size(df) == (0, 1)

Repo.disconnect()

end # module adapters_duckdb_repo_uuid_test
