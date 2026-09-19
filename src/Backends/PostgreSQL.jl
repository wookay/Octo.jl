module PostgreSQLLoader

# https://github.com/JuliaDatabases/Postgres.jl
using Postgres: Postgres # 2.1
using .Postgres: Tables, DBInterface

using Octo: Repo, AdapterBase, DBMS, SQLElement, Structured
using .Repo: SQLKeyword, ExecuteResult

# db_dbname
function db_dbname(nt::NamedTuple)::String
    get(nt, :dbname, "")
end

# db_connect
function db_connect(; kwargs...)
    if !isempty(kwargs)
        host     = get(kwargs, :host, "")
        user     = get(kwargs, :user, "")
        password = get(kwargs, :password, "")
        dbname   = get(kwargs, :dbname, "")
        DBInterface.connect(Postgres.Connection, host, user, password; dbname)
    end
end

# db_disconnect
function db_disconnect(conn)
    DBInterface.close!(conn)
end

# query
function query(conn, sql::String)
    stmt = DBInterface.prepare(conn, sql)
    result = DBInterface.execute(stmt)
    DBInterface.close!(stmt)
    df = Tables.rowtable(result)
    df
end

function query(conn, prepared::String, vals::Vector)
    stmt = DBInterface.prepare(conn, prepared)
    result = DBInterface.execute(stmt, vals)
    DBInterface.close!(stmt)
    df = Tables.rowtable(result)
    df
end

# execute
function execute(conn, sql::String)::ExecuteResult
    result = DBInterface.execute(conn, sql)
    rowtable_and_close_result(result, get_num_affected_rows(result))
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    stmt = DBInterface.prepare(conn, prepared)
    result = DBInterface.execute(stmt, vals)
    DBInterface.close!(stmt)
    rowtable_and_close_result(result, get_num_affected_rows(result))
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = DBInterface.prepare(conn, prepared)
    num_affected_rows::Union{Nothing, Int} = nothing
    result = nothing
    for tup in nts
        result = DBInterface.execute(stmt, collect(tup))
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
    DBInterface.close!(stmt)
    rowtable_and_close_result(result, num_affected_rows)
end

function rowtable_and_close_result(result, num_affected_rows::Union{Nothing, Int})
    if num_affected_rows === nothing
        nothing
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
    Postgres.rows_affected(result)
end

# execute_result
function execute_result(conn, command::SQLKeyword)::NamedTuple
    NamedTuple()
end

end # module Octo.Backends.PostgreSQLLoader
