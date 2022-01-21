module adapters_duckdb_repo_test

using Test # @test
using Octo.Adapters.DuckDB # Repo Schema Raw

struct Item
end
Schema.model(Item, table_name="items")

Repo.debug_sql()

Repo.connect(; adapter = Octo.Adapters.DuckDB)

Repo.execute([DROP TABLE IF EXISTS Item])
Repo.execute(Raw("""
    CREATE TABLE items(item VARCHAR, value DECIMAL(10,2), count INTEGER)
    """))

changes = [(item="Jeans", value=20.0, count=1),
           (item="hammer", value=42.2, count=2)]
# Repo.insert!(Item, changes)

res = Repo.execute("INSERT INTO items VALUES ('jeans', 20.0, 1), ('hammer', 42.2, 2)")

df = Repo.query(Item)
@test size(df) == (2, 2)

Repo.disconnect()

end # module adapters_duckdb_repo_test
