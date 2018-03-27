module PostgreSQLLoader

# https://github.com/invenia/LibPQ.jl
import LibPQ

const current = Dict{Symbol, Any}(
    :conn => nothing,
    :sink => Vector{<:NamedTuple}, # DataFrames.DataFrame
)

current_conn() = current[:conn]
current_sink() = current[:sink]

# sink
function sink(T::Type)
   current[:sink] = T
end

# connect
function connect(; kwargs...)
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
    stmt = LibPQ.prepare(conn, sql)
    result = LibPQ.execute(stmt)
    df = LibPQ.fetch!(sink, result)
    LibPQ.clear!(result)
    df
end

function query(prepared::String, vals::Vector)
    conn = current_conn()
    sink = current_sink()
    stmt = LibPQ.prepare(conn, prepared)
    result = LibPQ.execute(stmt, vals)
    df = LibPQ.fetch!(sink, result)
    LibPQ.clear!(result)
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
    stmt = LibPQ.prepare(conn, prepared)
    LibPQ.execute(stmt, vals)
    nothing
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::Nothing
    conn = current_conn()
    stmt = LibPQ.prepare(conn, prepared)
    for tup in nts
        LibPQ.execute(stmt, collect(tup))
    end
    nothing
end

end # module Octo.Backends.PostgreSQLLoader