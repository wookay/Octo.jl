module MySQLLoader

# https://github.com/JuliaDatabases/MySQL.jl
using MySQL # MySQL.jl 1.4
using .MySQL.DBInterface
using .MySQL.Tables

using Octo: Repo, AdapterBase, DBMS, SQLElement, Structured
using .Repo: SQLKeyword, ExecuteResult, sql_startswith_insert_update_delete
using .AdapterBase: INSERT

# db_dbname
function db_dbname(nt::NamedTuple)::String
    get(nt, :db, "")
end

# db_connect
function db_connect(; kwargs...)
    args = (:hostname, :username, :password)
    (hostname, username, password) = getindex.(Ref(kwargs), args)
    options = filter(kv -> !(kv.first in args), kwargs)
    DBInterface.connect(MySQL.Connection, hostname, username, password; options...)
end

# db_disconnect
function db_disconnect(conn)
    DBInterface.close!(conn)
end

# query
function query(conn, sql::String)
    (Tables.rowtable ∘ DBInterface.execute)(conn, sql)
end

function query(conn, prepared::String, vals::Vector)
    stmt = DBInterface.prepare(conn, prepared)
    (Tables.rowtable ∘ DBInterface.execute)(stmt, vals)
end

# execute

function execute(conn, sql::String)::ExecuteResult
    q = DBInterface.execute(conn, sql)
    sql_startswith_insert_update_delete_then_get_num_affected_rows(q.sql, conn)
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    stmt = DBInterface.prepare(conn, prepared)
    DBInterface.execute(stmt, vals)
    sql_startswith_insert_update_delete_then_get_num_affected_rows(prepared, conn)
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = DBInterface.prepare(conn, prepared)
    num_affected_rows = 0
    for nt in nts
        DBInterface.execute(stmt, values(nt))
        num_affected_rows += get_num_affected_rows(conn)
    end
    (num_affected_rows=num_affected_rows,)
end

function sql_startswith_insert_update_delete_then_get_num_affected_rows(sql::String, conn)
    if sql_startswith_insert_update_delete(sql)
        num_affected_rows = get_num_affected_rows(conn)
        (num_affected_rows=num_affected_rows,)
    else
        nothing
    end
end

function get_num_affected_rows(conn)::Int
    MySQL.API.affectedrows(conn.mysql)
end

# execute_result
function execute_result(conn, command::SQLKeyword)::NamedTuple
    if INSERT === command
        last_insert_id = MySQL.API.insertid(conn.mysql)
        (id=last_insert_id,)
    else
        NamedTuple()
    end
end

function Base.show(io::IO, mime::MIME"text/plain", element::Union{E,Structured} where E<:SQLElement)
    dbms = DBMS.MySQL()
    AdapterBase._show(io, mime, dbms, element)
end

end # module Octo.Backends.MySQLLoader
