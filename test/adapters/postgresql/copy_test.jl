module adapters_postgresql_copy_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    user = "postgres",
)

# https://discourse.julialang.org/t/postgresql-in-julia-libpq-jl/9379/4
Repo.execute(Raw("CREATE TABLE IF NOT EXISTS a_uts (ut text, id serial)"))

using LibPQ.libpq_c: PQputCopyData, PQputCopyEnd
loader = Repo.current_loader()
jl_conn = loader.current_conn()

Repo.execute(Raw("COPY a_uts (ut, id) FROM STDIN"))
d = [["W:000060362500001",1], ["W:000060362500002",2], ["W:000070603200027",3]]
for (ut, id) in d
    buf = string(join((ut, id), '\t'), '\n')
    PQputCopyData(jl_conn.conn, pointer(buf), Cint(length(buf)))
end
PQputCopyEnd(jl_conn.conn, C_NULL)

struct UTS
end
Schema.model(UTS, table_name="a_uts")

df = Repo.query(UTS)
@test size(df) == (3,)

Repo.execute([DROP TABLE :a_uts])

Repo.disconnect()

end # module adapters_postgresql_copy_test
