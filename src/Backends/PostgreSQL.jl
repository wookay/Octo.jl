module PostgreSQLLoader

using Octo.Repo: ExecuteResult

# https://github.com/invenia/LibPQ.jl
using LibPQ # v0.9.1
using .LibPQ.Tables

const current = Dict{Symbol, Any}(
    :conn => nothing,
)

current_conn() = current[:conn]

# db_connect
function db_connect(; kwargs...)
    if !isempty(kwargs)
        str = join(map(kv->join(kv, '='), collect(kwargs)), ' ')
        conn = LibPQ.Connection(str)
        current[:conn] = conn
    end
end

# db_disconnect
function db_disconnect()
    conn = current_conn()
    close(conn)
    current[:conn] = nothing
end

# query
function query(sql::String)
    conn = current_conn()
    stmt = LibPQ.prepare(conn, sql)
    result = LibPQ.execute(stmt)
    df = Tables.rowtable(result)
    LibPQ.close(result)
    df
end

function query(prepared::String, vals::Vector)
    conn = current_conn()
    stmt = LibPQ.prepare(conn, prepared)
    result = LibPQ.execute(stmt, vals)
    df = Tables.rowtable(result)
    LibPQ.close(result)
    df
end

# execute
function execute(sql::String)::ExecuteResult
    conn = current_conn()
    LibPQ.execute(conn, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    conn = current_conn()
    stmt = LibPQ.prepare(conn, prepared)
    LibPQ.execute(stmt, vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    conn = current_conn()
    stmt = LibPQ.prepare(conn, prepared)
    for tup in nts
        LibPQ.execute(stmt, collect(tup))
    end
    ExecuteResult()
end

end # module Octo.Backends.PostgreSQLLoader
