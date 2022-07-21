module adapters_postgresql_discourse_84510

# https://discourse.julialang.org/t/seeking-assistance-to-insert-data-into-postgres-db-using-libpq-jl/84510

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Raw Schema.model DROP TABLE IF EXISTS

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

struct DailyMetric
end
Schema.model(DailyMetric, table_name="test_dailymetrics")

Repo.execute([DROP TABLE IF EXISTS DailyMetric])

Repo.execute(Raw("""
    CREATE TABLE test_dailymetrics (
        id       SERIAL,
        dmdate   DATE,
        dmmetric TEXT,
        dmnum    integer
    );
"""))

using Dates
Repo.insert!(DailyMetric, (dmdate=Date(2022, 7, 17), dmmetric="overall", dmnum=8))

result = Repo.query(DailyMetric)
@test result[1].dmdate == Date(2022, 7, 17)
@test result[1].dmmetric == "overall"
@test result[1].dmnum == 8

using DataFrames
df = DataFrame(result)
@test df[1,:].dmnum == 8

end # module adapters_postgresql_discourse_84510
