module HiveLoader

# https://github.com/JuliaDatabases/Hive.jl v0.3.0
using Hive # HiveSession HiveAuth

using Octo: Repo, AdapterBase, DBMS, SQLElement, Structured
using .Repo: SQLKeyword, ExecuteResult

# db_dbname
function db_dbname(nt::NamedTuple)::String
    ""
end

# db_connect
function db_connect(; host::String="localhost", port::Integer=10000, auth::HiveAuth=HiveAuth(), tprotocol::Symbol=:binary)
    HiveSession(host, port, auth; tprotocol=tprotocol)
end

# db_disconnect
function db_disconnect(sess)
    if sess isa HiveSession
        Hive.close(sess)
    end
end

# query
function query(sess, sql::String)
    pending = Hive.execute(sess, sql)
    rs = Hive.result(pending)
    sch = Hive.schema(rs)
    column_names = tuple(Symbol.(getproperty.(sch.columns, :columnName))...)
    df = reduce(vcat, Hive.records(rs))
    nts = NamedTuple{column_names}.(df)
    Hive.close(rs)
    nts
end

function query(sess, prepared::String, vals::Vector) # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

# execute
function execute(sess, sql::String)::ExecuteResult
    result = Hive.execute(sess, sql)
    nothing
end

function execute(sess, prepared::String, vals::Vector)::ExecuteResult # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

function execute(sess, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

# execute_result
function execute_result(sess, command::SQLKeyword)::NamedTuple
    NamedTuple()
end

function Base.show(io::IO, mime::MIME"text/plain", element::Union{E,Structured} where E<:SQLElement)
    dbms = DBMS.Hive()
    AdapterBase._show(io, mime, dbms, element)
end

end # module Octo.Backends.HiveLoader
