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

# skip options
push!(ignores, "adapters/postgresql/options.jl")
push!(ignores, "adapters/mysql/options.jl")

runtests(@__DIR__, skip=collect(ignores), into=Main)
