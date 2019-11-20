module MySQLLoader

# https://github.com/JuliaDatabases/MySQL.jl
using MySQL # MySQL.jl v0.7.0
using Octo.Repo: SQLKeyword, ExecuteResult, INSERT
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
    conn = MySQL.connect(hostname, username, password; options...)
    current[:conn] = conn
end

# db_disconnect
function db_disconnect()
    conn = current_conn()
    MySQL.disconnect(conn)
    current[:conn] = nothing
end

# query
function query(sql::String)
    conn = current_conn()
    table = MySQL.Query(conn, sql)
    collect(table)
end

function query(prepared::String, vals::Vector) # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

# execute
function execute(sql::String)::ExecuteResult
    conn = current_conn()
    MySQL.execute!(conn, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    conn = current_conn()
    stmt = MySQL.Stmt(conn, prepared)
    MySQL.execute!(stmt, vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    conn = current_conn()
    stmt = MySQL.Stmt(conn, prepared)
    MySQL.execute!(stmt, nts...)
    ExecuteResult()
end

# execute_result
function execute_result(command::SQLKeyword)::ExecuteResult
    if INSERT === command
        conn = current_conn()
        last_insert_id = MySQL.insertid(conn)
        (id=last_insert_id,)
    end
end

end # module Octo.Backends.MySQLLoader
