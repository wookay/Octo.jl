module adapters_postgresql_repo_uuid_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Schema Raw

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

struct PinkFloyd
end
Schema.model(PinkFloyd, table_name="PINK_FLOYD")

Repo.execute([DROP TABLE IF EXISTS PinkFloyd])

# https://arctype.com/blog/postgres-uuid/
Repo.execute(Raw("""
CREATE TABLE PINK_FLOYD (
    id uuid DEFAULT uuid_generate_v4(),
    album_name VARCHAR NOT NULL,
    PRIMARY KEY (id)
)
    """))

Repo.insert!(PinkFloyd, [
    (album_name="The Wall",),
    (album_name="The Dark Side of the Moon",),
    (album_name="Wish You Were Here",),
    (album_name="The Division Bell",),
    (album_name="Pulse",),
    (album_name="Meddle",),
    (album_name="Atom Heart Mother",),
    (album_name="The Final Cut",),
    ])

df = Repo.query(PinkFloyd)
@test size(df) == (8,)

pk_ids = map(x -> x.id, df[1:2])

df = Repo.get(PinkFloyd, first(pk_ids))
@test df[1].album_name == "The Wall"

df = Repo.get(PinkFloyd, pk_ids)
@test df[2].album_name == "The Dark Side of the Moon"

Repo.delete!(PinkFloyd, pk_ids)

df = Repo.query(PinkFloyd)
@test size(df) == (6,)

Repo.disconnect()

end # module adapters_postgresql_repo_uuid_test
