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

runtests(@__DIR__, skip=collect(ignores))
