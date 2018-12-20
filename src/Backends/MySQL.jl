module MySQLLoader

# https://github.com/JuliaDatabases/MySQL.jl
using MySQL # MySQL.jl v0.7.0
using Octo.Repo: ExecuteResult
using Octo.Backends: UnsupportedError

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
    sink = current_sink()
    table = MySQL.Query(conn, sql, sink=sink)
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

end # module Octo.Backends.MySQLLoader
