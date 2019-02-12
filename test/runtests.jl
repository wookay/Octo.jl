using Jive

ignores = Set()

push!(ignores, joinpath("adapters", "hive"))

if Sys.iswindows()
    push!(ignores, joinpath("adapters", "mysql"))
    push!(ignores, joinpath("adapters", "odbc"))
    push!(ignores, joinpath("adapters", "jdbc"))
end

# juliarun-ci
if startswith(@__FILE__, "/home/jrun/Octo")
    @info "FIXME: How to test it on JuliaCIBot?"
    push!(ignores, joinpath("adapters", "postgresql"))
    push!(ignores, joinpath("adapters", "mysql"))
    push!(ignores, joinpath("adapters", "odbc"))
    push!(ignores, joinpath("adapters", "jdbc"))
end

using Jive.Distributed: nprocs
if nprocs() > 1 || !(get(ENV, "JIVE_PROCS", "") in ["", "0"])
    push!(ignores, joinpath("adapters", "jdbc"))
end

if VERSION >= v"1.2.0-DEV.219"
    push!(ignores, joinpath("adapters", "odbc"))
end

runtests(@__DIR__, skip=["adapters/mysql/options.jl", ignores...])
