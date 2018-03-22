module PostgreSQLLoader

# https://github.com/invenia/LibPQ.jl
using LibPQ
using LibPQ: clear!
import DataFrames: DataFrame

const current = Dict{Symbol, Any}(
    :conn => nothing,
    :sink => NamedTuple,
)

current_conn() = current[:conn]
current_sink() = current[:sink]

# load
function load(; kwargs...)
    str = join(map(kv->join(kv, '='), collect(kwargs)), ' ')
    conn = LibPQ.Connection(str)
    current[:conn] = conn
end

# disconnect
function disconnect()
    conn = current_conn()
    close(conn)
    current[:conn] = nothing
end

# query
function query(sql::String)
    conn = current_conn()
    sink = current_sink()
    stmt = prepare(conn, sql)
    result = LibPQ.execute(stmt)
    df = fetch!(sink, result)
    clear!(result)
    df
end

# execute
function execute(sql::String)::Nothing
    conn = current_conn()
    LibPQ.execute(conn, sql)
    nothing
end

function execute(prepared::String, vals::Vector)::Nothing
    conn = current_conn()
    stmt = prepare(conn, prepared)
    LibPQ.execute(stmt, vals)
    nothing
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::Nothing
    conn = current_conn()
    stmt = prepare(conn, prepared)
    for tup in nts
        LibPQ.execute(stmt, collect(tup))
    end
    nothing
end

end # module Octo.Backends.PostgreSQLLoader
