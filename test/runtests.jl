using Jive

ignores = Set()

for db in ["hive", "jdbc", "odbc", "duckdb"]
    push!(ignores, joinpath("adapters", db))
end

# LibPQ v0.11.1
#     ERROR: LoadError: ArgumentError: cannot convert NULL to string
push!(ignores, "adapters/postgresql/copy_test")

# skip options
push!(ignores, "adapters/postgresql/options.jl")
push!(ignores, "adapters/mysql/options.jl")

runtests(@__DIR__, skip=collect(ignores))
