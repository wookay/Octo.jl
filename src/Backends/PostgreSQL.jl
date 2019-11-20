module PostgreSQLLoader

using Octo.Repo: SQLKeyword, ExecuteResult

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
    result = LibPQ.execute(conn, sql)
    execute_result(result)
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    conn = current_conn()
    stmt = LibPQ.prepare(conn, prepared)
    result = LibPQ.execute(stmt, vals)
    execute_result(result)
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    conn = current_conn()
    stmt = LibPQ.prepare(conn, prepared)
    result = []
    for tup in nts
        result = LibPQ.execute(stmt, collect(tup))
    end
    execute_result(result)
end

# execute_result
function execute_result(command::SQLKeyword)::ExecuteResult
    ExecuteResult()
end

function execute_result(result)
    if !isempty(result)
        df = Tables.rowtable(result)
        LibPQ.close(result)
        first(df)
    else
        ExecuteResult()
    end
end

end # module Octo.Backends.PostgreSQLLoader
