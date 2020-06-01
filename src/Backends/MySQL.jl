module MySQLLoader

# https://github.com/JuliaDatabases/MySQL.jl
using MySQL # MySQL.jl 1.1
using .MySQL.DBInterface
using .MySQL.Tables
using Octo.Repo: SQLKeyword, ExecuteResult
using Octo.AdapterBase: INSERT
using Octo.Backends: UnsupportedError

const current = Dict{Symbol, Any}(
    :conn => nothing,
)

current_conn() = current[:conn]

# db_connect
function db_connect(; kwargs...)
    args = (:hostname, :username, :password)
    (hostname, username, password) = getindex.(Ref(kwargs), args)
    options = filter(kv -> !(kv.first in args), kwargs)
    conn = DBInterface.connect(MySQL.Connection, hostname, username, password; options...)
    current[:conn] = conn
end

# db_disconnect
function db_disconnect()
    conn = current_conn()
    DBInterface.close!(conn)
    current[:conn] = nothing
end

# query
function query(sql::String)
    conn = current_conn()
    (Tables.rowtable ∘ DBInterface.execute)(conn, sql)
end

function query(prepared::String, vals::Vector)
    conn = current_conn()
    stmt = DBInterface.prepare(conn, prepared)
    (Tables.rowtable ∘ DBInterface.execute)(stmt, vals)
end

# execute
function execute(sql::String)::ExecuteResult
    conn = current_conn()
    DBInterface.execute(conn, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    conn = current_conn()
    stmt = DBInterface.prepare(conn, prepared)
    DBInterface.execute(stmt, vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    conn = current_conn()
    stmt = DBInterface.prepare(conn, prepared)
    for nt in nts
        DBInterface.execute(stmt, values(nt))
    end
    ExecuteResult()
end

# execute_result
function execute_result(command::SQLKeyword)::ExecuteResult
    if INSERT === command
        conn = current_conn()
        last_insert_id = MySQL.API.insertid(conn.mysql)
        (id=last_insert_id,)
    end
end

end # module Octo.Backends.MySQLLoader
