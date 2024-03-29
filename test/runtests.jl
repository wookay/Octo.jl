using Jive

ignores = Set()

for db in ["hive", "jdbc", "odbc"]
    push!(ignores, joinpath("adapters", db))
end

if haskey(ENV, "CI")
    if Sys.isapple() || Sys.iswindows()
        for db in ["mysql", "postgresql"]
            push!(ignores, joinpath("adapters", db))
        end
    end
end

# LibPQ v0.11.1
#     ERROR: LoadError: ArgumentError: cannot convert NULL to string
push!(ignores, "adapters/postgresql/copy_test")

# skip options
push!(ignores, "adapters/postgresql/options.jl")
push!(ignores, "adapters/mysql/options.jl")

runtests(@__DIR__, skip=collect(ignores))
