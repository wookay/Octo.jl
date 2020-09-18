module PostgreSQLLoader

using Octo.Repo: SQLKeyword, ExecuteResult

# https://github.com/invenia/LibPQ.jl
using LibPQ # 1.2
using .LibPQ.Tables

# db_dbname
function db_dbname(nt::NamedTuple)::String
    get(nt, :dbname, "")
end

# db_connect
function db_connect(; kwargs...)
    if !isempty(kwargs)
        str = join(map(kv->join(kv, '='), collect(kwargs)), ' ')
        LibPQ.Connection(str)
    end
end

# db_disconnect
function db_disconnect(conn)
    close(conn)
end

# query
function query(conn, sql::String)
    stmt = LibPQ.prepare(conn, sql)
    result = LibPQ.execute(stmt)
    df = Tables.rowtable(result)
    LibPQ.close(result)
    df
end

function query(conn, prepared::String, vals::Vector)
    stmt = LibPQ.prepare(conn, prepared)
    result = LibPQ.execute(stmt, vals)
    df = Tables.rowtable(result)
    LibPQ.close(result)
    df
end

# execute
function execute(conn, sql::String)::ExecuteResult
    result = LibPQ.execute(conn, sql)
    execute_result(conn, result)
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    stmt = LibPQ.prepare(conn, prepared)
    result = LibPQ.execute(stmt, vals)
    execute_result(conn, result)
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = LibPQ.prepare(conn, prepared)
    result = []
    for tup in nts
        result = LibPQ.execute(stmt, collect(tup))
    end
    execute_result(conn, result)
end

# execute_result
function execute_result(conn, command::SQLKeyword)::ExecuteResult
    ExecuteResult()
end

function execute_result(conn, result)
    if !isempty(result)
        df = Tables.rowtable(result)
        LibPQ.close(result)
        first(df)
    else
        ExecuteResult()
    end
end

end # module Octo.Backends.PostgreSQLLoader
