module ODBCLoader

# https://github.com/JuliaDatabases/ODBC.jl
import ODBC
import Octo.Repo: ExecuteResult
import Octo.Backends: UnsupportedError

const current = Dict{Symbol, Any}(
    :dsn => nothing,
    :sink => Vector{<:NamedTuple},
)

current_dsn() = current[:dsn]
current_sink() = current[:sink]

# sink
function sink(::Type)
    current[:sink] = T
end

# connect
function connect(; kwargs...)
    if !isempty(kwargs)
        args = (:username, :password)
        username = get(kwargs, :username, "")
        password = get(kwargs, :password, "")
        conn_args = filter(kv -> !(kv.first in args), kwargs)
        conn_str = join(map(kv->join(kv, '='), collect(conn_args)), ';')
        dsn = ODBC.DSN(conn_str, username, password)
        current[:dsn] = dsn
    end 
end

# disconnect
function disconnect()
    dsn = current_dsn()
    ODBC.disconnect!(dsn)
    current[:dsn] = nothing
end

# query
function query(sql::String)
    dsn = current_dsn()
    sink = current_sink()
    source = ODBC.Source(dsn, sql)
    df = ODBC.Data.stream!(source, sink)
    df
end

function query(prepared::String, vals::Vector)
    throw(UnsupportedError("needs to be implemented"))
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
