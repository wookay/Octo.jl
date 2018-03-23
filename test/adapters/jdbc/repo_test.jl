module adapters_jdbc_repo_test

using Test # @test
using Octo.Adapters.JDBC # Repo Schema

Repo.set_log_level(Repo.LogLevelDebugSQL)

Repo.connect(
    adapter = Octo.Adapters.JDBC,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    # FIXME
)

# TODO

Repo.disconnect()

end # module adapters_jdbc_repo_test
