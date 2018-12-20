module ODBCLoader

using Octo.Repo: ExecuteResult

# https://github.com/JuliaDatabases/ODBC.jl
using ODBC # v0.8.1

const current = Dict{Symbol, Any}(
    :dsn => nothing,
    :sink => Vector{<:NamedTuple},
)

current_dsn() = current[:dsn]
current_sink() = current[:sink]

# sink
function sink(T::Type)
    current[:sink] = T
end

# db_connect
function db_connect(; kwargs...)
    if !isempty(kwargs)
        connectionstring = get(kwargs, :dsn, "")
        username = get(kwargs, :username, "")
        password = get(kwargs, :password, "")
        dsn = ODBC.DSN(connectionstring, username, password)
        current[:dsn] = dsn
    end 
end

# db_disconnect
function db_disconnect()
    dsn = current_dsn()
    ODBC.disconnect!(dsn)
    current[:dsn] = nothing
end

# query
function query(sql::String)
    dsn = current_dsn()
    q = ODBC.Query(dsn, sql)
    collect(q)
end

function query(prepared::String, vals::Vector)
    dsn = current_dsn()
    stmt = ODBC.prepare(dsn, prepared)
    ODBC.execute!(stmt, vals)
    ExecuteResult()
end

# execute
function execute(sql::String)::ExecuteResult
    dsn = current_dsn()
    ODBC.execute!(dsn, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    dsn = current_dsn()
    stmt = ODBC.prepare(dsn, prepared)
    ODBC.execute!(stmt, vals) 
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    dsn = current_dsn()
    stmt = ODBC.prepare(dsn, prepared)
    for tup in nts
        ODBC.execute!(stmt, collect(tup))
    end
    ExecuteResult()
end

end # module Octo.Backends.ODBCLoader
