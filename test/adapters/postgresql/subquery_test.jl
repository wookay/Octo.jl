module adapters_postgresql_subquery_test

using Test # @test
using Octo.Adapters.PostgreSQL # Octo.PlaceHolder Repo from to_sql Schema.model SELECT FROM WHERE ORDER BY LIMIT INNER JOIN LATERAL ON TRUE

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    dbname = "postgresqltest",
    user = "postgres",
)

struct Game
end
Schema.model(Game, table_name="games")

struct GameSold
end
Schema.model(GameSold, table_name="games_sold")

g0 = from(Game, :g0)
gs = from(GameSold, :gs)
f1 = from([SELECT * FROM gs WHERE gs.game_id == g0.id ORDER BY gs.sold_on LIMIT 2], :f1)
@test to_sql([SELECT (g0.name, f1.sold_on) FROM g0 INNER JOIN LATERAL f1 ON TRUE]) ==
             "SELECT g0.name, f1.sold_on FROM games g0 INNER JOIN LATERAL (SELECT * FROM games_sold gs WHERE gs.game_id = g0.id ORDER BY gs.sold_on LIMIT 2) AS f1 ON TRUE"

@test to_sql([SELECT (:depname, :empno, :salary, window([RANK() OVER PARTITION BY :depname ORDER BY :salary DESC])) FROM :empsalary]) == 
             "SELECT depname, empno, salary, RANK() OVER (PARTITION BY depname ORDER BY salary DESC) FROM empsalary"

@test to_sql([SELECT (:depname, :empno, :salary, window([RANK() OVER PARTITION BY :depname ORDER BY :salary DESC], :w)) FROM :empsalary]) == 
             "SELECT depname, empno, salary, RANK() OVER (PARTITION BY depname ORDER BY salary DESC) AS w FROM empsalary"

Repo.disconnect()

end # module adapters_postgresql_subquery_test
