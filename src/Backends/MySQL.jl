module MySQLLoader

# https://github.com/JuliaDatabases/MySQL.jl
using MySQL # MySQL.jl 1.1
using .MySQL.DBInterface
using .MySQL.Tables
using Octo.Repo: SQLKeyword, ExecuteResult
using Octo.AdapterBase: INSERT
using Octo.Backends: UnsupportedError

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
    DBInterface.execute(conn, sql)
    nothing
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    stmt = DBInterface.prepare(conn, prepared)
    DBInterface.execute(stmt, vals)
    nothing
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = DBInterface.prepare(conn, prepared)
    for nt in nts
        DBInterface.execute(stmt, values(nt))
    end
    nothing
end

# execute_result
function execute_result(conn, command::SQLKeyword)::ExecuteResult
    if INSERT === command
        last_insert_id = MySQL.API.insertid(conn.mysql)
        (id=last_insert_id,)
    end
end

end # module Octo.Backends.MySQLLoader
