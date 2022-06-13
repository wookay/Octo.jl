using Jive

ignores = Set()

for db in ["hive", "jdbc", "odbc"]
    push!(ignores, joinpath("adapters", db))
end

# waiting updates  https://github.com/JuliaBinaryWrappers/DuckDB_jll.jl
if haskey(ENV, "CI")
    push!(ignores, "adapters/duckdb")
end

# LibPQ v0.11.1
#     ERROR: LoadError: ArgumentError: cannot convert NULL to string
push!(ignores, "adapters/postgresql/copy_test")

# skip options
push!(ignores, "adapters/postgresql/options.jl")
push!(ignores, "adapters/mysql/options.jl")

runtests(@__DIR__, skip=collect(ignores))
