module test_octo_predicates

using Test
using Octo.Adapters.SQL # from to_sql
using Octo: Enclosed

struct User
end

u = from(User)
enc = Enclosed([])
@test to_sql([u.name == enc]) == "name = ()"

@test to_sql([u.name IS NOT NULL]) == "name IS NOT NULL"
@test to_sql([30 >= u.age AND u.age >= 20]) == "30 >= age AND age >= 20"


struct PGStatioUserTable
end
Schema.model(PGStatioUserTable, table_name="pg_statio_user_tables")
p = from(PGStatioUserTable)
q = [SELECT
     (as(SUM(p.heap_blks_read), :heap_read), as(SUM(p.heap_blks_hit), :heap_hit), as(SUM(p.heap_blks_hit) / (SUM(p.heap_blks_hit) + SUM(p.heap_blks_read)), :ratio))
     FROM
     p]
@test to_sql(q) == """SELECT SUM(heap_blks_read) AS heap_read, SUM(heap_blks_hit) AS heap_hit, SUM(heap_blks_hit) / (SUM(heap_blks_hit) + SUM(heap_blks_read)) AS ratio FROM pg_statio_user_tables"""

q = [SELECT
     (p.relname, as(100 * p.idx_scan / (p.seq_scan + p.idx_scan), :percent_of_times_index_used), as(p.n_live_tup, :rows_in_table))
     FROM
     p
     WHERE
     p.seq_scan + p.idx_scan > 0
     ORDER
     BY
     p.n_live_tup
     DESC]
@test to_sql(q) == "SELECT relname, 100 * idx_scan / (seq_scan + idx_scan) AS percent_of_times_index_used, n_live_tup AS rows_in_table FROM pg_statio_user_tables WHERE (seq_scan + idx_scan) > 0 ORDER BY n_live_tup DESC"

end # module test_octo_predicates
