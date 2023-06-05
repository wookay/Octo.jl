module adapters_postgresql_insert_on_conflict_do_update_test

using Test
using Octo.Adapters.PostgreSQL

@sql_keywords CONFLICT DO NOTHING

struct Distributor
end
Schema.model(Distributor, table_name="distributors")

d = from(Distributor)

# Issue 55
# https://www.postgresql.org/docs/current/sql-insert.html

#=
INSERT INTO distributors (did, dname)
    VALUES (5, 'Gizmo Transglobal'), (6, 'Associated Computing, Inc')
    ON CONFLICT (did) DO UPDATE SET dname = EXCLUDED.dname;
=#
vals = [(5, "Gizmo Transglobal"), (6, "Associated Computing, Inc")]
sql = to_sql([INSERT INTO d (d.did, d.dname) VALUES Octo.VectorOfTuples(vals) ON CONFLICT (d.did,) DO UPDATE SET d.dname == "Company"])
@test sql == """INSERT INTO distributors (did, dname) VALUES (5, 'Gizmo Transglobal'), (6, 'Associated Computing, Inc') ON CONFLICT did DO UPDATE SET dname = 'Company'"""

#=
INSERT INTO distributors (did, dname) VALUES (10, 'Conrad International')
    ON CONFLICT (did) WHERE is_active DO NOTHING;
=#
vals = [(10, "Conrad International")]
sql = to_sql([INSERT INTO d (d.did, d.dname) VALUES Octo.VectorOfTuples(vals) ON CONFLICT (d.did,) WHERE d.is_active DO NOTHING])
@test sql == """INSERT INTO distributors (did, dname) VALUES (10, 'Conrad International') ON CONFLICT did WHERE is_active DO NOTHING"""

end # module adapters_postgresql_insert_on_conflict_do_update_test
