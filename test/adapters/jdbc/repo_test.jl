module adapters_jdbc_repo_test

using Test # @test
using Octo.Adapters.JDBC # Repo Schema

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.JDBC,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    # FIXME
)

# TODO

Repo.disconnect()

end # module adapters_jdbc_repo_test
