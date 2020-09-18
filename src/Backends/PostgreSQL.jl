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
    rowtable_and_close_result(result, get_num_affected_rows(result))
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    stmt = LibPQ.prepare(conn, prepared)
    result = LibPQ.execute(stmt, vals)
    rowtable_and_close_result(result, get_num_affected_rows(result))
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = LibPQ.prepare(conn, prepared)
    num_affected_rows::Union{Nothing, Int} = nothing
    result = nothing
    for tup in nts
        result = LibPQ.execute(stmt, collect(tup))
        num = get_num_affected_rows(result)
        if num === nothing
        else
            if num_affected_rows === nothing
                num_affected_rows = num
            else
                num_affected_rows += num
            end
        end
    end
    rowtable_and_close_result(result, num_affected_rows)
end

function rowtable_and_close_result(result, num_affected_rows::Union{Nothing, Int})
    if num_affected_rows === nothing
        NamedTuple()
    else
        df = Tables.rowtable(result)
        if isempty(df)
            (num_affected_rows=num_affected_rows,)
        else
            merge(first(df), (num_affected_rows=num_affected_rows,))
        end
    end
end

function get_num_affected_rows(result)::Union{Nothing, Int}
    str = unsafe_string(LibPQ.libpq_c.PQcmdTuples(result.result))
    if isempty(str)
        nothing
    else
        parse(Int, str)
    end
end

# execute_result
function execute_result(conn, command::SQLKeyword)::ExecuteResult
    ExecuteResult()
end

end # module Octo.Backends.PostgreSQLLoader
