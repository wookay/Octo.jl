module adapters_sqlite_placeholder_test

using Test # @test
using Octo.Adapters.SQLite # from to_sql Schema.model PlaceHolder SELECT FROM WHERE

Repo.set_log_level(Repo.LogLevelDebugSQL)

Repo.connect(
    adapter = Octo.Adapters.SQLite,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    database = joinpath(dirname(@__FILE__), "test.sqlite")
)

struct Temp
end
Schema.model(Temp, table_name="temp", primary_key="AlbumId")

❔ = Octo.PlaceHolder

a = from(Temp)
df = Repo.query([SELECT * FROM a WHERE a.Title == ❔ AND a.ArtistId == ❔], ["The Doors", 140])
@test size(df) == (1,)

Repo.disconnect()

end # module adapters_sqlite_placeholder_test
