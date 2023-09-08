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
inserted = Repo.insert!(Item, changes)
@test inserted == (Count = 2,)

df = Repo.query(Item)
@test size(df) == (2, 3)

df = Repo.get(Item, (item="Jeans",))
@test size(df) == (1, 3)
@test df[!, :item] == ["Jeans"]
@test df[1, :].item == "Jeans"

changes = (item="Jeans",)
result = Repo.delete!(Item, changes)
@test result == (Count = 1,)
result = Repo.delete!(Item, changes)
@test result == (Count = 0,)

df = Repo.query(Item)
@test size(df) == (1, 3)

Repo.disconnect()

end # module adapters_duckdb_repo_test
