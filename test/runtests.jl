using Jive

ignores = Set()

push!(ignores, joinpath("adapters", "hive"))

if Sys.iswindows()
    push!(ignores, joinpath("adapters", "mysql"))
    push!(ignores, joinpath("adapters", "odbc"))
    push!(ignores, joinpath("adapters", "jdbc"))
elseif VERSION < v"1.3.0"
    push!(ignores, joinpath("adapters", "jdbc"))
end

if haskey(ENV, "TRAVIS") && ENV["TRAVIS_OS_NAME"] == "osx"
    push!(ignores, joinpath("adapters", "mysql"))
    push!(ignores, joinpath("adapters", "odbc"))
end

using Jive.Distributed: nprocs
if nprocs() > 1 || !(get(ENV, "JIVE_PROCS", "") in ["", "0"]) || VERSION >= v"1.3.0-alpha"
    push!(ignores, joinpath("adapters", "jdbc"))
end


# LibPQ v0.11.1
#     ERROR: LoadError: ArgumentError: cannot convert NULL to string
push!(ignores, "adapters/postgresql/copy_test")

runtests(@__DIR__, skip=["adapters/mysql/options.jl", ignores...])
