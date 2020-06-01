module ODBCLoader

using Octo.Repo: SQLKeyword, ExecuteResult

# https://github.com/JuliaDatabases/ODBC.jl
using ODBC # 1.0
using .ODBC.DBInterface
using .ODBC.Tables

const current = Dict{Symbol, Any}(
    :conn => nothing,
)

current_conn() = current[:conn]

# db_connect
function db_connect(; kwargs...)
    if !isempty(kwargs)
        dsn = get(kwargs, :dsn, "")
        conn = DBInterface.connect(ODBC.Connection, dsn)
        current[:conn] = conn
    end 
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
    ExecuteResult()
end

end # module Octo.Backends.ODBCLoader
