module MySQLLoader

import MySQL
import DataFrames

const current = Dict{Symbol, Union{Nothing, MySQL.Connection}}(
    :conn => nothing
)

current_conn() = current[:conn]

# load
function load(; kwargs...)
    args = (:hostname, :username, :password)
    (hostname, username, password) = getindex.(kwargs, args)
    options = filter(kv -> !(kv.first in args), kwargs)
    conn = MySQL.connect(hostname, username, password; options...)
    current[:conn] = conn
end

# disconnect
function disconnect()
    conn = current_conn()
    MySQL.disconnect(conn)
    current[:conn] = nothing
end

# query
function query(sql::String)
    conn = current_conn()
    MySQL.query(conn, sql, DataFrames.DataFrame)
end

# execute
function execute(sql::String)
    conn = current_conn()
    MySQL.execute!(conn, sql)
end

function execute(sql::String, tups::Vector{Tuple})
    conn = current_conn()
    stmt = MySQL.Stmt(conn, sql)
    for tup in tups
        MySQL.execute!(stmt, tup)
    end
end

end # module Octo.Backends.MySQLLoader
