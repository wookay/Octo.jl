module adapters_postgresql_copy_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

# https://discourse.julialang.org/t/postgresql-in-julia-libpq-jl/9379/4
Repo.execute(Raw("CREATE TABLE IF NOT EXISTS a_uts (ut text, id serial)"))

buffer = IOBuffer()
d = [["W:000060362500001",1], ["W:000060362500002",2], ["W:000070603200027",3]]
for (ut, id) in d
    data = string(join((ut, id), '\t'), '\n')
    write(buffer, data)
end
seekstart(buffer)

# from Postgres/test/runtests.jl
using Postgres: Postgres

repo_conn = Repo.current_connection()
conn = repo_conn.conn

debug = false
Postgres.copy_from(conn, "COPY a_uts (ut, id) FROM STDIN", buffer; debug)

struct UTS
end
Schema.model(UTS, table_name="a_uts")

df = Repo.query(UTS)
@test size(df) == (3,)

Repo.execute([DROP TABLE :a_uts])

Repo.disconnect()

end # module adapters_postgresql_copy_test
